"""Serious Python entry point for SkillBridge Python Lab.

Serious Python embeds CPython into the Flutter app but does *not* let Flutter
call a Python function directly: instead it runs a Python *program* and the two
sides communicate. Following the official guidance, this entry point starts a
tiny HTTP server bound to loopback, and the Flutter ``SeriousPythonRuntime``
POSTs learner code to it and reads back the structured JSON result.

Protocol (all loopback only, a random-ish fixed port):

    GET  /health          -> {"ok": true, "pythonVersion": "..."}
    POST /execute         -> body: {"code": ..., "stdin": [...], "maxOutputChars": N}
                             resp: the JSON from skillbridge_exec.execute()

The server is deliberately minimal and stdlib-only so that no third-party
wheel needs to be bundled.
"""

from __future__ import annotations

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Allow importing the sibling executor when run from the packaged app dir.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from skillbridge_exec import _python_version, run_job_from_json  # noqa: E402

PORT = int(os.environ.get("SKILLBRIDGE_PORT", "8791"))


class _Handler(BaseHTTPRequestHandler):
    server_version = "SkillBridgePython/1.0"

    # Silence the default logging which would spam device logs.
    def log_message(self, *args, **kwargs):  # noqa: ANN002, ANN003
        return

    def _send_json(self, code: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802 - required name
        if self.path.startswith("/health"):
            self._send_json(200, {"ok": True, "pythonVersion": _python_version()})
        else:
            self._send_json(404, {"ok": False, "error": "not found"})

    def do_POST(self):  # noqa: N802 - required name
        if not self.path.startswith("/execute"):
            self._send_json(404, {"ok": False, "error": "not found"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length) if length else b"{}"
            job = json.loads(raw.decode("utf-8"))
            result = run_job_from_json(job)
            self._send_json(200, result)
        except Exception as exc:  # noqa: BLE001
            self._send_json(500, {"status": "error", "stderr": str(exc)})


def main() -> None:
    server = ThreadingHTTPServer(("127.0.0.1", PORT), _Handler)
    print(f"SkillBridge Python runtime listening on 127.0.0.1:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
