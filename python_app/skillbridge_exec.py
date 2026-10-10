"""SkillBridge Python Lab - shared code executor.

This module contains the single source of truth for *how learner code is
executed* by SkillBridge Python Lab.  It is intentionally written against the
Python standard library only so that it can run in every environment we care
about:

  * The embedded CPython runtime shipped by Serious Python on Android/iOS
    (``python_app/main.py`` starts a tiny localhost HTTP server that calls
    :func:`execute`).
  * A host CPython interpreter during development and automated tests
    (``python_app/harness_cli.py`` is a thin CLI wrapper used by the Flutter
    ``ProcessPythonRuntime``).

Keeping the executor in one file means the on-device behaviour and the
dev/test behaviour are the *same* code path, so what we test on the desktop is
what ships on the phone.

Security note
-------------
``exec`` of untrusted code inside the *same* interpreter as the host is **not**
a security sandbox.  This executor implements practical guard rails (input
injection so ``input()`` never blocks, output caps, an optional CPU-time limit
on POSIX) but the real isolation guarantees come from the outer layer:

  * On mobile the code runs inside the app's private CPython process/thread.
  * In development it runs inside a short-lived child process that the Dart
    side kills on timeout.

See ``docs/SECURITY_AND_PRIVACY.md`` for the full discussion and the additional
protections required for production.
"""

from __future__ import annotations

import io
import json
import linecache
import sys
import time
import traceback
from typing import Any, Dict, List, Optional

# Sentinel markers let the Dart side reliably extract the JSON result from a
# stream that may also contain unrelated interpreter noise.
RESULT_START = "===SKILLBRIDGE_RESULT_START==="
RESULT_END = "===SKILLBRIDGE_RESULT_END==="

# Pseudo-filename used when compiling learner code. Registering the source in
# `linecache` under this name is what lets tracebacks show the offending line
# of the learner's own program instead of an anonymous `<skillbridge>` frame.
SOURCE_NAME = "<skillbridge>"

# Hard ceiling applied inside Python as a second line of defence. The Dart side
# applies its own, usually smaller, limit before this one is reached.
DEFAULT_MAX_OUTPUT_CHARS = 200_000

# Small, safe set of modules that beginner exercises are expected to use.
# ``math``, ``random`` etc. are part of the stdlib and available by default;
# we do not expose filesystem or network helpers here.
_SAFE_PREAMBLE = ""


class _InputExhausted(Exception):
    """Raised when learner code asks for more ``input()`` than was supplied."""


def _build_input_function(lines: List[str]) -> Any:
    """Return a ``input()`` replacement backed by ``lines``.

    Using a list means ``input()`` can never block waiting for a terminal, which
    would freeze the app on a phone.
    """
    iterator = iter(lines)

    def _input(prompt: str = "") -> str:
        # Echo the prompt into stdout so learners see what was asked, matching
        # the behaviour they get in a normal terminal.
        if prompt:
            sys.stdout.write(str(prompt))
        try:
            value = next(iterator)
        except StopIteration:
            # Mirror real Python: running out of input raises EOFError.
            raise EOFError("Ran out of input. Add more input lines and run again.")
        # ``input`` strips the trailing newline.
        return str(value).rstrip("\n").rstrip("\r")

    return _input


def _register_source(code: str) -> None:
    """Publish ``code`` to :mod:`linecache` under :data:`SOURCE_NAME`.

    ``traceback`` looks up frame filenames in ``linecache``; without this a
    learner's traceback would show only an anonymous ``<skillbridge>`` frame
    with no source line, which is unhelpful when they are just starting out.
    """
    linecache.cache[SOURCE_NAME] = (
        len(code),
        None,
        code.splitlines(True),
        SOURCE_NAME,
    )


def _truncate(text: str, limit: int) -> Dict[str, Any]:
    """Truncate ``text`` to ``limit`` characters.

    Returns a dict with the (possibly truncated) text and a flag so the UI can
    tell the learner that older output was dropped.
    """
    if not text:
        return {"text": "", "truncated": False}
    if len(text) <= limit:
        return {"text": text, "truncated": False}
    # Keep the *end* of the output; the most recent and most useful lines.
    head = 0
    kept = text[-limit:]
    dropped = len(text) - head
    return {
        "text": kept,
        "truncated": True,
        "droppedChars": dropped,
    }


def execute(
    code: str,
    *,
    stdin_lines: Optional[List[str]] = None,
    max_output_chars: int = DEFAULT_MAX_OUTPUT_CHARS,
    cpu_seconds: Optional[int] = None,
) -> Dict[str, Any]:
    """Execute ``code`` and return a structured result.

    The returned dictionary is JSON-serialisable and mirrors the fields the Dart
    ``ExecutionResult`` model expects::

        {
          "status": "success" | "error" | "timeout" | "cancelled",
          "stdout": str,
          "stderr": str,
          "exception": {"type": str, "message": str, "traceback": str} | None,
          "durationMs": int,
          "stdoutTruncated": bool,
          "stderrTruncated": bool,
          "pythonVersion": str,
        }
    """
    stdin_lines = list(stdin_lines or [])
    stdout_buf = io.StringIO()
    stderr_buf = io.StringIO()

    # Guard rail: optional CPU wall-clock limit enforced with SIGALRM where
    # available (POSIX). On Windows/most mobile builds this is a no-op and the
    # outer process/server is responsible for timing out.
    alarm_installed = False
    if cpu_seconds and cpu_seconds > 0:
        alarm_installed = _install_alarm(cpu_seconds)

    globals_dict: Dict[str, Any] = {
        "__name__": "__main__",
        "__doc__": None,
        "__builtins__": _make_safe_builtins(stdin_lines),
    }

    started = time.perf_counter()
    status = "success"
    exception: Optional[Dict[str, str]] = None

    old_stdout, old_stderr = sys.stdout, sys.stderr
    try:
        sys.stdout = stdout_buf
        sys.stderr = stderr_buf
        try:
            # ``code`` is compiled first so we can distinguish syntax errors
            # (which get a beginner-friendly message) from runtime errors.
            _register_source(code)
            compiled = compile(code, SOURCE_NAME, "exec")
        except SyntaxError as exc:
            status = "error"
            exception = _format_syntax_error(exc)
        else:
            try:
                exec(compiled, globals_dict)
            except _InputExhausted as exc:
                status = "error"
                exception = {
                    "type": "EOFError",
                    "message": str(exc),
                    "traceback": "",
                }
            except EOFError as exc:
                status = "error"
                exception = {
                    "type": "EOFError",
                    "message": str(exc),
                    "traceback": "",
                }
            except SystemExit as exc:
                # ``sys.exit()`` / ``exit()`` should end the program cleanly.
                if exc.code not in (0, None):
                    status = "error"
                    exception = {
                        "type": "SystemExit",
                        "message": str(exc.code),
                        "traceback": "",
                    }
            except BaseException as exc:  # noqa: BLE001 - we must catch everything
                status = "error"
                exception = _format_exception(exc)
    finally:
        sys.stdout = old_stdout
        sys.stderr = old_stderr
        if alarm_installed:
            _cancel_alarm()

    duration_ms = int((time.perf_counter() - started) * 1000)

    out = _truncate(stdout_buf.getvalue(), max_output_chars)
    err = _truncate(stderr_buf.getvalue(), max_output_chars)

    return {
        "status": status,
        "stdout": out["text"],
        "stderr": err["text"],
        "stdoutTruncated": out["truncated"],
        "stderrTruncated": err["truncated"],
        "exception": exception,
        "durationMs": duration_ms,
        "pythonVersion": _python_version(),
    }


def _python_version() -> str:
    v = sys.version_info
    return f"{v.major}.{v.minor}.{v.micro}"


def _make_safe_builtins(stdin_lines: List[str]) -> Dict[str, Any]:
    """Return a ``builtins`` dict with ``input`` wired to ``stdin_lines``."""
    import builtins as _builtins

    namespace = dict(vars(_builtins))
    namespace["input"] = _build_input_function(stdin_lines)
    return namespace


def _format_syntax_error(exc: SyntaxError) -> Dict[str, str]:
    lineno = exc.lineno or 0
    offset = exc.offset or 0
    msg = exc.msg or "Invalid syntax"
    friendly = f"Syntax error on line {lineno}: {msg}"
    return {
        "type": "SyntaxError",
        "message": friendly,
        "traceback": "".join(traceback.format_exception_only(type(exc), exc)).strip(),
        "line": str(lineno),
        "offset": str(offset),
    }


def _format_exception(exc: BaseException) -> Dict[str, str]:
    """Format a runtime exception, hiding SkillBridge internal frames."""
    tb_lines = traceback.format_exception(type(exc), exc, exc.__traceback__)
    # Drop frames that point at this executor so learners only see their own
    # code in the traceback.
    filtered = [line for line in tb_lines if "skillbridge_exec.py" not in line]
    if filtered and not filtered[0].startswith("Traceback"):
        filtered.insert(0, "Traceback (most recent call last):\n")
    return {
        "type": type(exc).__name__,
        "message": str(exc),
        "traceback": "".join(filtered).strip(),
    }


def _install_alarm(seconds: int) -> bool:
    """Best-effort SIGALRM based CPU/wall limit (POSIX only)."""
    try:
        import signal  # local import so non-POSIX just skips

        def _handler(signum, frame):  # noqa: ANN001
            raise TimeoutError(f"Execution exceeded {seconds} seconds")

        signal.signal(signal.SIGALRM, _handler)
        signal.alarm(int(seconds))
        return True
    except (ImportError, ValueError, AttributeError, OSError):
        return False


def _cancel_alarm() -> None:
    try:
        import signal

        signal.alarm(0)
    except Exception:  # noqa: BLE001
        pass


def run_job_from_json(job: Dict[str, Any]) -> Dict[str, Any]:
    """Convenience wrapper used by the CLI and the HTTP server."""
    return execute(
        job.get("code", ""),
        stdin_lines=job.get("stdin", []),
        max_output_chars=int(job.get("maxOutputChars", DEFAULT_MAX_OUTPUT_CHARS)),
        cpu_seconds=job.get("cpuSeconds"),
    )
