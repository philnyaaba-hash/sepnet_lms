# ADR-001: Python runtime

* **Status:** Accepted (2026)
* **Deciders:** SkillBridge Python Lab team
* **Consequences:** `PythonRuntime` abstraction with three implementations;
  `python_app/skillbridge_exec.py` is the single source of truth for execution.

## Context

The app must run **real Python** written by a learner on an Android phone, with
no network. The candidate approaches were:

| Option | What it is |
| --- | --- |
| **A. Serious Python** | A Flutter plugin shipping a full CPython build; you package a Python *program* and run it inside the app |
| **B. Chaquopy / python-for-android** | Embed CPython in the Android app via a build-system plugin |
| **C. MicroPython / Pyodide** | A smaller Python implementation, or a browser-oriented build |
| **D. Server-side execution** | Send code to the LMS, run it there |
| **E. A WebView + JS Python** | Run a JS-ported Python (e.g. Pyodide) inside a WebView |

## Decision

**Ship Serious Python on device (Option A)**, behind a `PythonRuntime`
interface, and keep **`ProcessPythonRuntime`** (a host CPython child process) as
the development and CI runtime. **Do not simulate execution anywhere.**

## Why

1. **It is genuinely CPython.** Serious Python packages a real CPython build, so
   semantics match what the learners will eventually use. This rules out C
   (MicroPython diverges in important ways for a *teaching* app: `input()`
   behaviour, Unicode handling, stdlib coverage) and E (a JS port has its own
   divergences and drags in a WebView).
2. **It works offline on a phone.** Option D contradicts the offline-first
   requirement outright — a learner on a bus with no data must still be able to
   run their code.
3. **It is not a build-system intrusion.** Option B (Chaquopy) couples the
   Android build to a Gradle plugin and a specific NDK/ABI matrix. That is
   fragile on the modest CI we expect to use, and it complicates the iOS story
   where Chaquopy does not apply. Serious Python is an ordinary Flutter plugin.
4. **It is maintained and licensed cleanly.** Apache-2.0, on pub.dev, actively
   maintained, supports Android/iOS/macOS/Windows/Linux.
5. **A shared executor is possible.** The decisive design property: Serious
   Python runs a *program*, not a function call, so we package
   `python_app/main.py`, a tiny loopback HTTP server that calls
   `skillbridge_exec.execute()`. `harness_cli.py` calls the *same function* for
   the desktop runtime. One executor, two transports.

## Consequences

### Positive

* `test/python_runtime_process_test.dart` runs the real executor against a real
  interpreter on a laptop, so execution behaviour is verified in CI without a
  device or emulator.
* The runtime is swappable. `FakePythonRuntime` makes widget tests hermetic.
* The `ExecutionResult` JSON contract is explicit and serialisable.

### Negative / accepted costs

* **`cancel()` is best-effort on device.** The embedded interpreter owns its
  thread and exposes no kill primitive, so a runaway loop can only be stopped by
  the in-interpreter `SIGALRM`, which is POSIX-only. On the desktop runtime
  `cancel()` is a real `SIGKILL` and is tested. See `KNOWN_LIMITATIONS.md`.
* **A packaging step is required before a device build**
  (`dart run serious_python:main package python_app -p Android`). This is easy
  to forget, so it is documented prominently in `BUILD_AND_RELEASE.md`.
* **On-device execution has not been verified yet** — no Android SDK or device
  is available in this environment. The embedded path is implemented and
  type-checks, but it has never run on hardware. Until it has, this ADR's
  decision is "accepted, pending device verification".
* The loopback HTTP server is an unusual pattern; a future Serious Python
  release exposing a direct call API would let us delete it.

## Alternatives considered in more detail

### B. Chaquopy

Fine for a general-purpose Python-in-Android story, but it is a Gradle plugin
with a matching CPython build per ABI, it does not help with iOS at all, and it
would make the Python version a function of the Android toolchain rather than a
deliberate choice. Rejected on cross-platform and build-coupling grounds.

### C. MicroPython

Dramatically smaller and faster to start, which is genuinely attractive on a
low-end phone. Rejected because a *teaching* app must not silently diverge from
CPython: learners would hit differences in `input()`, string/Unicode handling,
f-strings, and stdlib availability, and would learn a dialect nobody else uses.
If startup time on low-end devices turns out to be a real problem, the right
answer is a smaller **CPython** build or a pre-warmed interpreter, not a
different language.

### D. Server-side execution

Would give perfect isolation and perfect grading. Rejected because it makes
every exercise require a network, which is the opposite of the core requirement.
It also puts learner code on a server, which is a materially bigger security
conversation than running it on the learner's own device.

### E. WebView + Pyodide

Rejected for the same reasons as C (divergent semantics) plus: a WebView costs
hundreds of MB, behaves inconsistently on the Android versions in the field, and
adds a large attack surface to an app used by minors.

## Verification plan

1. ✅ Real-execution tests against host CPython — `test/python_runtime_process_test.dart`.
2. ⬜ Package for Android, run on a physical device, confirm `/health` and
   `/execute` behave as the desktop runtime does.
3. ⬜ Measure cold-start time and peak memory on the lowest-spec target device.
4. ⬜ Re-test `cancel()` and timeout behaviour on device; if `SIGALRM` is
   unavailable, implement an in-interpreter watchdog that marks the result
   `timeout` and abandons the request.
