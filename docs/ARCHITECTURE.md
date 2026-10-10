# Architecture

## Goals

SkillBridge Python Lab has to work on low-end Android phones in classrooms with
intermittent connectivity, for learners who are just starting to program. Those
two facts drive every decision below:

* **Offline-first.** Nothing the learner does may require the network. Reading
  exercises, editing, running code, and submitting all work offline; the network
  is only a synchronisation channel.
* **Real execution.** A Python exercise that does not really run Python teaches
  the wrong thing. Execution is real, and its limits are explicit.
* **Server-authoritative rewards.** Anything that looks like a reward (points,
  achievements) must come from the LMS, never from the device.
* **Testable without a device.** Every layer has a seam so the whole app can be
  exercised by `flutter test` on a laptop.

## Layering

```
presentation  ──  features/*/ *_screen.dart, app/
      │            widgets only; no SQL, no HTTP, no dart:io
      ▼
state         ──  features/*/ *_controller.dart (ChangeNotifier)
      │            owns use-cases: run code, save draft, submit, sync
      ▼
domain        ──  models: Exercise, Submission, ExecutionResult,
      │            LearnerProgress, AppException
      ▼
ports         ──  PythonRuntime, LmsClient, ConnectivityService
      │            small interfaces, one job each
      ▼
adapters      ──  ProcessPythonRuntime / SeriousPythonRuntime / FakePythonRuntime
                  HttpLmsClient / MockLmsClient
                  ConnectivityPlusService / FakeConnectivityService
                  AppDatabase + repositories (SQLite)
```

The dependency arrows only point downwards. `lib/features/editor/*_screen.dart`
never touches `dart:io` or SQL; it goes through `EditorController`, which goes
through `AppDependencies`, which wires concrete adapters in.

### Why `provider` and not something heavier?

The app has roughly six screens and one composition root. `provider` with
`ChangeNotifier` controllers gives:

* a single obvious place to build the object graph (`AppDependencies`),
* `ChangeNotifier` objects that are trivially substitutable in tests,
* no code generation, which keeps cold builds fast on modest CI hardware.

If the app grows a lot of cross-feature state, migrating the controllers to
Riverpod is mechanical because the controllers are already UI-free.

## The composition root

`lib/core/di/app_dependencies.dart` is the only place that knows which concrete
adapter to build. It is called once from `main.dart` (inside a `FutureBuilder`
so the user sees a real loading state and a real error state rather than a
white screen), and once per test with fakes.

Configuration arrives through `AppConfig`, which reads `--dart-define` values at
compile time. There are no runtime environment files and no secrets.

Runtime selection:

| Platform / override | Runtime | Why |
| --- | --- | --- |
| `SB_PYTHON_RUNTIME=serious` | `SeriousPythonRuntime` | Embedded CPython via Serious Python |
| `SB_PYTHON_RUNTIME=process` | `ProcessPythonRuntime` | Host CPython child process |
| `SB_PYTHON_RUNTIME=fake` | `FakePythonRuntime` | Deterministic, for widget tests |
| Android / iOS (default) | `SeriousPythonRuntime` | The only real on-device option |
| Desktop / CI (default) | `ProcessPythonRuntime` | Makes real-execution tests possible |
| Web | `FakePythonRuntime` | There is no Python on the web build |

## Storage

One SQLite database (`AppDatabase`) with four tables:

| Table | Purpose | Key |
| --- | --- | --- |
| `drafts` | Current working copy per (learner, exercise) | `UNIQUE(learner_ref, exercise_id)` |
| `submissions` | Durable queue **and** history | `submission_id` (client-generated UUID) |
| `exercises` | Cached exercise metadata for offline reading | `exercise_id` |
| `sync_meta` | Small key/value bookkeeping | `key` |

`sqflite_common_ffi` provides the factory on desktop and in tests; the native
`sqflite` plugin is used on Android/iOS. `AppDatabase._platformFactory()` picks
one, which is why the storage tests run against a real SQLite file on a laptop
rather than a mock.

`shared_preferences` holds non-sensitive UI preferences only. Auth tokens never
touch either store — see `docs/SECURITY_AND_PRIVACY.md`.

## The execution pipeline

```
EditorScreen ──▶ EditorController.run()
                    │  builds ExecutionRequest(code, stdinLines, timeout, maxOutputChars)
                    ▼
               PythonRuntime.execute()
                    │
      ┌─────────────┼──────────────────┐
      ▼             ▼                  ▼
 SeriousPython   ProcessPython      FakePython
 (HTTP to an     (spawn CPython     (canned result,
  embedded        child running      for widget
  loopback        harness_cli.py)    tests)
  server)
      └─────────────┴──────────────────┘
                    ▼
            ExecutionResult.fromJson()      ◀── all three speak this
                    ▼
               OutputConsole
```

The crucial property: **all three runtimes speak the same JSON contract**
(`ExecutionResult`). The Python side produces it in
`python_app/skillbridge_exec.py`, and that file is the single source of truth
for *how code is executed*. The desktop/dev path and the on-device path call the
same `execute()` function, so behaviour verified in CI is the behaviour that
ships.

`ExecutionResult` carries `status`, `stdout`, `stderr`, `exception` (with
`type`, `message`, `traceback`, `line`), `durationMs`, truncation flags and the
interpreter version. Truncation flags exist because a runaway `print` loop must
not lock up a phone.

## The offline submission queue

This is the most safety-critical flow, so its invariants are spelled out:

1. `EditorController.submit()` **writes the submission to SQLite first**. If the
   app is killed immediately afterwards, the submission survives.
2. The client-generated UUID doubles as the `Idempotency-Key`. Retrying reuses
   it, so the server can de-duplicate.
3. `SubmissionSyncService` drains the queue oldest-first. Each item may fail
   transiently inside one pass; it backs off `base * 2^n` (capped) between
   attempts, then leaves the row in the retryable `failed` state for the next
   pass. It is never deleted.
4. Only two transitions are terminal, and only the server can cause them:
   `accepted` and `rejected`. A network error, an auth expiry, or exhausting the
   in-pass attempts all leave the row retryable.
5. Displayed points and achievements are read back from the LMS. The app has no
   code path that increments a score locally.

The state machine is documented on `SubmissionSyncState` and covered by
`test/submission_sync_service_test.dart`, including the "must not discard"
invariant and the "must not double-reward" invariant.

## Error handling

All failures surface through one sealed hierarchy, `AppException`:

* `OfflineException` — the network was needed and unavailable.
* `NetworkException` — transient; retried.
* `AuthenticationException` — session expired; stops the sync pass, discards nothing.
* `LmsException` — permanent server-side rejection; not retried.
* `NotFoundException`, `StorageException`, `RuntimeException`.

The UI shows `userMessage` and never a stack trace. Learner-facing Python errors
additionally go through `ExecutionException.friendlyLabel`, which turns
`IndexError` into "You asked for an item that is outside the list."

## Presentation

Three-tab `NavigationBar` shell (Home / Progress / Settings) with pushed routes
for the editor and the exercise details. Widgets are kept dumb: they render a
controller's state and forward intents. The one exception is `EditorScreen`,
which owns the `CodeEditingController` and `FocusNode` because they must be
disposed with the widget.

Editor internals live in `lib/features/editor/widgets/` and are individually
unit-tested:

* `PythonSyntaxHighlighter` — a forgiving tokenizer whose invariant is "the
  highlighted spans concatenate back to the exact source text".
* `PythonInputFormatter` — a `TextInputFormatter` that auto-closes, wraps
  selections, skips over an existing quote, and auto-indents after `:`.
* `CodeEditingController` — a `TextEditingController` that runs the formatter on
  every edit so the tests do not need a keyboard.

## Testing strategy

| Layer | Approach |
| --- | --- |
| Tokenizer / formatter | Pure unit tests, no widgets |
| Execution | Real CPython subprocess; skipped with a clear message if no interpreter |
| Storage | Real SQLite via `sqflite_common_ffi` on a temp file |
| Sync / LMS | Real SQLite + `MockLmsClient` + fake connectivity; delay function injected so backoff is asserted exactly |
| UI | `flutter test` with `FakePythonRuntime`, mocked `SharedPreferences`, in-memory SQLite |

Widget tests deliberately avoid `pumpAndSettle`, because an indeterminate
progress indicator makes it hang forever; `pumpFrames()` advances fake time a
fixed number of steps instead.

## Extension points

* **New LMS:** implement `LmsClient`. Nothing else changes.
* **New runtime:** implement `PythonRuntime` and add a case to
  `python_runtime_factory.dart`.
* **New storage fields:** add a migration in `AppDatabase` (`_schemaVersion`)
  and extend the repository round-trip tests, which already assert every field.
