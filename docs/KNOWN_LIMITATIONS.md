# Known limitations

This is the honest list. Anything not mentioned here as "verified" has **not**
been verified. If a limitation below stops being true, delete it — do not leave
stale caveats behind.

## Status of every claim in this repo

| Claim | Verified how | Confidence |
| --- | --- | --- |
| Python really executes, with stdout/stderr/exception/timeout/cancel | 15 tests against host CPython 3.14.8 (`test/python_runtime_process_test.dart`) | High — runs on a laptop |
| Syntax highlighting and editor input behaviour | `test/python_highlighter_test.dart`, `test/python_input_formatter_test.dart` | High |
| Offline drafts and the submission queue in SQLite | `test/storage_test.dart` (real SQLite via ffi) | High |
| Retry, backoff, idempotency, no-duplicate-rewards | `test/submission_sync_service_test.dart` | High |
| The UI works end to end | 10 tests in `test/widget_test.dart`, real SQLite behind a fake runtime | Medium — headless `flutter_test` only |
| The editor and a real interpreter meet | `test/editor_real_runtime_test.dart` drives the real editor, `EditorController` and `harness_cli.py` against host CPython 3.14.8 | High — but the **desktop** runtime only (see limitation 4) |
| The app runs end to end on a desktop | `flutter build windows --debug` → `skillbridge_python_lab.exe` launched and rendered the seeded home screen (screenshot taken); the harness executes from the same working directory it uses | High that it *runs*; the UI is driven by hand, not by a script |
| The whole suite is green | `flutter test` → 122 tests, all passing | High, in this environment only |
| The Windows desktop build needs no admin | Plugin links are pre-created as junctions by `tool/link_windows_plugins.ps1`, which exploits Flutter's "skip existing link" branch; Developer Mode is **off** here | High — verified by building on this machine |
| The Android toolchain is correctly installed | `flutter doctor` reports no issues; SDK 36, build-tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1 all present | High |
| The Python app packages for Android | `dart run serious_python:main package python_app -p Android` succeeds and stages `build/python-app/` | High |
| The app builds an APK | `flutter build apk --debug` → `app-debug.apk`, 209 MB, contents inspected with `aapt2` and by unzipping: `libpython3.14.so`, `libdart_bridge.so`, `stdlib.zip`, `app.zip` all present | High that it *builds*; **zero** evidence it *runs* |
| The APK runs on a real phone | **No** | None — no device or emulator |
| The embedded Python runtime works on device | **No** | None — never executed on hardware |
| The web build compiles and boots | `flutter build web --release` → 40 MB, served and screenshotted with SQLite running through `sqflite_common_ffi_web` | High that it *runs* |
| The web build executes Python | **No** | None — a browser has neither `dart:io` nor `dart:ffi`, so web always selects `FakePythonRuntime` |
| iOS builds | **No** | None — no macOS host |

## Runtime

1. **The embedded (on-device) runtime has never been executed.**
   `SeriousPythonRuntime` is implemented, type-checks, and follows the Serious
   Python 5.0.0 API, but it has never run on Android or iOS hardware because no
   Android SDK or device is available here. Everything about the loopback HTTP
   server (port allocation, startup timeout, behaviour under app
   suspension) is untested. The desktop `ProcessPythonRuntime` is the
   verified path, and it calls the same `skillbridge_exec.execute()`.
2. **`cancel()` is only a hard kill on the desktop.** `ProcessPythonRuntime`
   really `SIGKILL`s the child process (tested). The embedded runtime has no
   such primitive; there the interpreter owns its thread and the only mechanism
   is an in-interpreter `SIGALRM`, which is POSIX-only. A `while True: pass`
   on device is therefore only stoppable by that alarm, which has not been
   tested on a phone.
3. **The in-interpreter CPU limit is POSIX-only.** `SIGALRM` does not exist on
   Windows or in most Android interpreter builds, so `maxWallSeconds` is
   inert there. Output caps still apply everywhere.
4. **The editor and the *on-device* interpreter have still never met.**
   `test/editor_real_runtime_test.dart` closes the "type here, run there" gap
   for the desktop path: it drives the real editor widget, the real
   `EditorController` and the real `harness_cli.py` against host CPython, and
   asserts on real stdout and a real `SyntaxError`. What it does *not* cover is
   `SeriousPythonRuntime` — the runtime phones actually use — which remains
   untested end to end for the same reason as limitation 1. Desktop success is
   not evidence about the embedded runtime: they share `skillbridge_exec.py`,
   but not the transport, the packaging or the lifecycle.
5. **Startup time and peak memory on low-end hardware are unmeasured.** The
   Serious Python packaging step embeds a full CPython build; how long that
   takes to launch on a low-end Android phone is unknown and matters a lot for
   the target audience.

6. **The web build cannot execute Python.** A browser provides neither
   `dart:io` nor `dart:ffi`, so `AppConfig` always resolves to
   `FakePythonRuntime` on web, and the web factory throws a clear
   `UnsupportedError` if `SB_PYTHON_RUNTIME` is forced to a native value. The
   web target is therefore a UI and offline-storage demonstration only. A
   real browser interpreter would mean something like Pyodide, which is a
   different runtime with different semantics and has not been evaluated
   here (see `docs/ADR_001_PYTHON_RUNTIME.md`).

## Editor

7. **No syntax *diagnostics*.** The highlighter colours tokens; it cannot tell
   a learner their program is wrong. The only real feedback is running the
   code. See `docs/CODEMIRROR_EVALUATION.md` for why this was accepted.
8. **Highlighting is token-based, not parse-based.** It cannot understand
   f-string interpolation, `match` statements, or contextual keywords. It is
   deliberately forgiving — the tested invariant is that highlighted spans
   concatenate back to the exact source text, never that they are *correct*.
9. **The tokenizer is not a performance-tested on multi-megabyte files.**
   Exercises are small, so this has not been a concern, but nothing has been
   measured.
10. **Auto-close always appends a closing bracket**, even when one already
   follows the caret. Only quotes have the "step over the existing closing
   character" behaviour. This is a deliberate simplification and reads as a
   minor annoyance.
11. **No autocomplete, no code folding, no multi-cursor, no find/replace.**
12. **Indent width is two independent settings.** `Settings → Indent width`
    controls the editor's auto-indent, but the shortcut bar's indent button
    always inserts four spaces — it is constructed with the default
    `indentUnit` rather than the configured one (`editor_screen.dart:233`).

## Storage and sync

13. **The database is not encrypted.** A rooted device can read drafts and
    submitted code. See `docs/SECURITY_AND_PRIVACY.md`.
14. **There is no `onUpgrade` migration handler.** `AppDatabase` is at
    `_schemaVersion = 1` with only `onCreate`. Bumping that constant today
    would either throw or leave an old-schema database in place while the code
    expects new columns — and in an offline-first app that "loses" the learner's
    work either way. Real, tested migrations must be written before the version
    is ever incremented, and that path is currently untested.
15. **No `sync_meta` bookkeeping is written yet.** The table exists; the "last
    successful sync" timestamp is held in `shared_preferences`, which is not
    the right long-term home for it.
16. **Backoff is per pass, not global.** Each `syncPending()` pass retries each
    item a bounded number of times with exponential delay. There is no
    cross-restart attempt counter persisted across app launches beyond
    `attemptCount`, and no jitter, so a classroom of devices coming back online
    together will retry in lockstep.
17. **No upload of "still editing" state.** Drafts stay local; only submissions
    are sent.

## LMS and rewards

18. **There is no LMS API.** `MockLmsClient` is authoritative;
    `HttpLmsClient` implements a *proposed* contract that has never received a
    response. `docs/LMS_INTEGRATION.md` lists seven open questions that can
    each change the client.
19. **`HttpLmsClient` has no tests**, deliberately: writing them would mean
    inventing an API and then verifying the client against our own invention.
20. **No `AuthTokenProvider` implementation ships.** Only the interface and a
    dev-only `StaticTokenProvider` exist. There is no sign-in flow, and
    therefore no real session-expiry handling beyond what the mock can prove.
21. **Achievements are a single screen reading server values.** There is no
    local award logic — which is the point — but it also means the screen is
    thin until the LMS exists.

## Android / release

22. **The APK builds; it has never been launched.** `flutter build apk --debug`
    succeeds and the artifact contains the real embedded CPython, but no device
    or emulator was available, so nothing about run time has been observed:
    whether `SeriousPython.run` starts the interpreter, how long the first
    launch takes, or whether the loopback server answers. Every claim about
    on-device execution is untested. This is the single largest gap in the
    project.
23. **The debug APK is ~209 MB.** Three ABIs, unstripped debug symbols, and the
    debug-only `libVkLayer_khronos_validation.so` (14.5 MB per ABI). Release
    builds with `--split-per-abi` will be far smaller, but no size has been
    measured, and download size is a first-order constraint for the target
    audience.
24. **`assets/sitepackages.zip` is empty**, because `python_app/` declares no
    `requirements.txt`. That is fine today and wrong as soon as a dependency is
    added: nothing in CI fails when the requirements are silently not installed
    on device.
25. **Release signing is not configured.** The release build currently signs
    with the debug key so that `flutter run --release` works during
    development. This must be replaced before any distribution.
26. **`minSdk` is Flutter's default**, not a chosen floor. Serious Python
    embeds a CPython build whose minimum ABI level has not been checked against
    the phones this app is for.
27. **`android/app/build.gradle.kts` still carries the `flutter create`
    TODO comment** about choosing a unique application id.
28. **iOS has never been built.** The `ios/` directory is scaffolding only.

## Product and policy

29. **`learnerRef` is an anonymous local id.** Nothing binds it to a real
    learner. Doing so is a server-side decision with real privacy consequences
    for minors and has not been made.
30. **No parental/guardian consent flow, no data-deletion request flow, no
    terms of service, no privacy policy text.** These are required before this
    app is used by under-13s in most jurisdictions, including Ghana's Data
    Protection Act, 2012 (Act 843).
31. **Accessibility is designed for, not audited.** Touch targets are ≥48 dp,
    text uses scalable styles, and there are no fixed-size text boxes — but
    nothing has been checked with TalkBack, a large font scale, or by anyone
    with a visual impairment.
32. **English only.** No localisation, and no right-to-left support.
33. **The exercise set is eight hard-coded items** inside `MockLmsClient`
    (hello-world, variables, arithmetic, conditions, loops, functions, lists,
    input), plus whatever the LMS eventually sends. There is no authoring tool.
34. **No onboarding or tutorial.** The first-run experience is the home
    screen.

## Test suite caveats

35. **The real-execution tests skip (they do not fail) when no interpreter is
    available**, and print an explicit skip message naming the interpreter they
    looked for. A CI machine without Python would show them as skipped, not
    green.
36. **Widget tests cannot touch the database directly.** `testWidgets` runs its
    body in a fake-async zone where timers only fire when the clock is
    advanced, but SQLite's FFI path schedules a real internal timer. Awaiting
    the database straight from a test body therefore hangs until the test
    times out. Every storage read in `test/widget_test.dart` goes through a
    `real()` helper that wraps `tester.runAsync`, and frames are rendered by
    pairing a real delay with `tester.pump`. This is a property of the
    harness, not of the app — but it means a future contributor who writes
    `await deps.drafts.find(...)` directly inside `testWidgets` will see a
    hang, not a failure message. The app itself uses the isolate-backed
    `databaseFactoryFfi` on device; only the tests use
    `databaseFactoryFfiNoIsolate`.
37. **The widget tests use a fake Python runtime**, so they prove the UI
    wiring, not interpreter behaviour; real execution is covered separately
    by `python_runtime_process_test.dart`. Likewise they use a fake
    connectivity service, so no test has ever observed a real network change.
38. **Widget tests still avoid `pumpAndSettle`** and advance time in fixed
    steps, because an indeterminate progress indicator makes `pumpAndSettle`
    hang forever. This means they can pass while an animation is still
    running.
39. **There are no integration tests** (`integration_test/`), no golden tests,
    and no performance tests.
40. **No fuzzing of the executor.** The Python executor runs arbitrary learner
    code; a fuzzer over the job-file parser would be a cheap, high-value
    addition.

## Desktop and web builds

41. **The Windows desktop build works only because of a workaround.**
    `flutter build windows` needs one symlink per Windows plugin, and creating
    a real symlink on Windows requires `SeCreateSymbolicLinkPrivilege`, which a
    non-administrator only has when Developer Mode is enabled. Developer Mode is
    **off** on this machine, so the build failed with "Building with plugins
    requires symlink support". `tool/link_windows_plugins.ps1` pre-creates those
    entries as **directory junctions**, which need no privilege. Flutter skips
    any link that already exists (`if (link.existsSync()) continue;` in
    `flutter_plugins.dart`), and Dart's `Link.existsSync()` returns `true` for a
    junction but `false` for a plain directory - that was checked directly
    before it was relied on. Enabling Developer Mode is still the supported
    route; run the script after `flutter pub get` and before the build, because
    a `pub get` that changes the plugin list recreates the directory.
42. **The desktop artifact is a Debug build.** `skillbridge_python_lab.exe`
    (1.2 MB) links `flutter_windows.dll` (46 MB) and an unstripped
    `python314_d.dll` (~14 MB), and has not been optimised. No release build
    has been produced.
