"""CLI wrapper around the SkillBridge code executor.

Used by the Flutter ``ProcessPythonRuntime`` during development and automated
tests. It runs on any host with CPython 3.x available.

Usage::

    python harness_cli.py <job.json> [<result.json>]

``job.json`` contains::

    {"code": "...", "stdin": ["line1", "line2"], "maxOutputChars": 200000}

The structured result is written both to ``<result.json>`` (when given) and to
stdout between the RESULT_START / RESULT_END markers so the Dart side can parse
either source.
"""

from __future__ import annotations

import json
import sys

from skillbridge_exec import RESULT_END, RESULT_START, run_job_from_json


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.stderr.write("usage: harness_cli.py <job.json> [<result.json>]\n")
        return 2

    job_path = argv[1]
    result_path = argv[2] if len(argv) > 2 else None

    # ``utf-8-sig`` transparently strips a BOM some editors/scripts prepend.
    with open(job_path, "r", encoding="utf-8-sig") as handle:
        job = json.load(handle)

    result = run_job_from_json(job)

    payload = json.dumps(result)
    if result_path:
        with open(result_path, "w", encoding="utf-8") as handle:
            handle.write(payload)

    # Markers + payload on the *real* stdout (user output was captured).
    sys.stdout.write(f"{RESULT_START}\n{payload}\n{RESULT_END}\n")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
