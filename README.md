# SkillBridge Python Lab

An offline-first Flutter app that lets learners aged 10–18 in Ghana **write and
really run Python** on a phone, save their work locally, and submit solutions to
a Learning Management System (LMS) — even when the network drops out.

> **Status:** working reference implementation. Android-first, iOS scaffolded.
> See [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md) for what has *not*
> been verified yet and why.

---

## What works today

| Capability | Where it lives | Verified by |
| --- | --- | --- |
| Real Python execution (CPython), with stdout/stderr/exceptions/timeout/cancel | `python_app/skillbridge_exec.py` | `test/python_runtime_process_test.dart` (15 tests against host CPython) |
| Native code editor: syntax highlighting, line numbers, auto-indent, auto-close | `lib/features/editor/` | `test/python_highlighter_test.dart`, `test/python_input_formatter_test.dart` |
| Offline drafts (SQLite) | `lib/core/storage/draft_repository.dart` | `test/storage_test.dart` |
| Durable submission queue with idempotency keys and exponential backoff | `lib/features/offline_sync/submission_sync_service.dart` | `test/submission_sync_service_test.dart` |
| Mock LMS with server-authoritative grading and de-duplicated rewards | `lib/integrations/lms/mock_lms_client.dart` | `test/submission_sync_service_test.dart`, `test/widget_test.dart` |
| Full UI: home, editor, exercise details, progress, settings | `lib/features/` | `test/widget_test.dart` |
| The editor and a real interpreter wired together | `lib/features/editor/editor_controller.dart` | `test/editor_real_runtime_test.dart` (drives the real editor against host CPython) |

`flutter analyze` is clean and `flutter test` runs **122 tests** across those
eight suites. What is *not* verified — chiefly, that the app runs on a real
phone — is listed in [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md), and
that document is the one to read before believing any row above.

## Documentation

| Document | What it answers |
| --- | --- |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the layers fit together and why. |
| [docs/ADR_001_PYTHON_RUNTIME.md](docs/ADR_001_PYTHON_RUNTIME.md) | Why Serious Python, and what the alternatives were. |
| [docs/CODEMIRROR_EVALUATION.md](docs/CODEMIRROR_EVALUATION.md) | CodeMirror 6 (WebView) vs. the native editor we shipped. |
| [docs/LMS_INTEGRATION.md](docs/LMS_INTEGRATION.md) | The proposed LMS contract and the gaps that must be closed. |
| [docs/SECURITY_AND_PRIVACY.md](docs/SECURITY_AND_PRIVACY.md) | Execution limits, secrets, and child-safety defaults. |
| [docs/BUILD_AND_RELEASE.md](docs/BUILD_AND_RELEASE.md) | Getting an Android build running. |
| [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) | The honest list of what is untested or incomplete. |
| [docs/PRODUCT_REFERENCE.md](docs/PRODUCT_REFERENCE.md) | Peer-app notes: copy tone, gamification worth adopting, what we will not copy. |

---

## Quick start

### Prerequisites

* Flutter 3.47.x (Dart 3.13.x)
* A CPython 3.x interpreter on `PATH` (needed for the development runtime and
  the execution tests). Override with `SB_PYTHON_EXECUTABLE`.
* Android SDK + a device/emulator for an on-device build.

### Install and check

```powershell
flutter pub get
flutter analyze     # expected: "No issues found!"
flutter test        # expected: all suites green
```

### Run on desktop (real Python via a host interpreter)

```powershell
# One-off, only on a machine without Developer Mode:
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\link_windows_plugins.ps1

flutter run -d windows
```

On desktop the app selects `ProcessPythonRuntime`, which spawns a short-lived
CPython child process running `python_app/harness_cli.py`. This is the *same*
executor that ships on the phone, so what you test on the desktop is what the
learner gets. The interpreter is whatever `python` resolves to on `PATH`.

The first command is needed only because `flutter build windows` creates one
symlink per plugin, and a non-administrator needs Developer Mode enabled to
create symlinks on Windows. It pre-creates them as junctions instead, which need
no privilege. See
[docs/BUILD_AND_RELEASE.md](docs/BUILD_AND_RELEASE.md#desktop-smoke-run).

### Run on the web (UI and offline storage only)

```powershell
dart run sqflite_common_ffi_web:setup      # once: writes web/sqlite3.wasm
flutter run -d web-server --web-port 8787 --web-hostname 127.0.0.1
```

Web has no `dart:io` and no `dart:ffi`, so it always selects `FakePythonRuntime`
and **does not execute Python**. It is a UI and offline-storage demonstration.

### Run on Android

```powershell
# One-off: package the embedded Python runtime for the target platform.
# serious_python 5.0.0 stages the processed app here, and the Gradle build
# reads it back out — so both commands need the same two variables.
$root = "C:\Users\<you>\skillbridge_python_lab"
$env:SERIOUS_PYTHON_APP           = "$root\build\python-app"
$env:SERIOUS_PYTHON_SITE_PACKAGES = "$root\build\python-site-packages"

dart run serious_python:main package python_app -p Android
flutter build apk --debug
```

No admin rights are needed: the Android SDK installs entirely under
`%LOCALAPPDATA%\Android\Sdk`. See
[docs/BUILD_AND_RELEASE.md](docs/BUILD_AND_RELEASE.md) for the full recipe,
including a component-by-component SDK install and the `--dart-define` reference.

### Point it at a real LMS

The app ships with `MockLmsClient` because the real endpoints do not exist yet.
`HttpLmsClient` implements the *proposed* contract; supply the URL at build time
with `--dart-define` (never hard-code secrets in the repo):

```powershell
flutter build apk --release `
  --dart-define=SB_ENV=staging `
  --dart-define=SB_LMS_BASE_URL=https://lms.example.org/api/v1 `
  --dart-define=SB_LMS_CLIENT_ID=skillbridge-android
```

`SB_PYTHON_RUNTIME` (`serious` | `process` | `fake`) overrides the runtime
selection if you need to force one.

---

## Design rules this codebase follows

1. **Never claim a feature works unless it is implemented *and* tested.** Every
   row in the table above points at a test file.
2. **Execution is real.** Learner code runs on a real CPython. Nothing is
   simulated, and we never silently swap in MicroPython or a toy interpreter.
3. **Rewards are server-authoritative.** The app never computes SkillCoins or
   achievements locally; it displays whatever the LMS returns.
4. **Submissions are never discarded.** A submission is persisted *before* any
   network call, retries reuse the same idempotency key, and only a trusted
   server verdict can move it to a terminal state.
5. **No secrets in the client.** Tokens come from an `AuthTokenProvider`; the
   repo contains no HMAC keys and no signing logic.
6. **Offline is the normal case, not the error case.** Every network read has a
   local cache fallback, and every write has a durable queue.

## Repository layout

```
lib/
  app/              Theme, router, root widget, navigation shell
  core/
    config/         --dart-define driven configuration
    di/             Composition root (AppDependencies)
    errors/         One AppException hierarchy for the whole app
    security/       Id generation (idempotency keys)
    storage/        SQLite: drafts, submissions, exercise cache, settings
  features/
    editor/         Editor screen + controller, and the editor widgets
    exercises/      Exercise model + details screen
    home/           Home screen, connectivity controller
    achievements/   Progress / SkillCoins screen (read-only, server-driven)
    settings/       Settings screen + controller
    offline_sync/   Connectivity service + submission sync service
    python_runtime/ PythonRuntime abstraction and its three implementations
    submissions/    Submission model and sync-state machine
  integrations/lms/ LmsClient contract, mock client, HTTP client, models
python_app/
  skillbridge_exec.py   THE executor: single source of truth for running code
  main.py               Loopback HTTP server used on-device (Serious Python)
  harness_cli.py        CLI wrapper used by the desktop/dev runtime and tests
test/                    6 suites; see the table above
docs/                    Architecture, ADRs, security, build, limitations
```
