# Architecture Decision Record (DRAFT)

Status: DRAFT. Nothing below has been verified by running code. Items marked
UNVERIFIED must be checked before they are relied on.

## 1. Scope
Android-first Flutter app that lets learners edit and run Python offline,
save drafts, queue submissions, and sync with the existing SkillBridge LMS.
The LMS is the authority for grading, XP, SkillCoins and certificates.

## 2. Decisions

| Area | Choice | Status |
|---|---|---|
| App framework | Flutter + Dart, Material 3, dark theme first | Decided |
| Editor | CodeMirror 6 in a WebView, bundled locally in `assets/editor/` | UNVERIFIED: must test cursor/selection, keyboard resize, performance on a budget phone |
| Python runtime | Serious Python (CPython embedded) | UNVERIFIED: must confirm it can run arbitrary learner code dynamically, capture stdout/stderr/exceptions, support input(), and be cancelled |
| Runtime fallback | Pyodide (WASM) in a WebView | Only if Serious Python fails the checks above |
| Local DB | SQLite via sqflite | UNVERIFIED: pick maintained version |
| Auth tokens | flutter_secure_storage (not SQLite) | UNVERIFIED |
| LMS | Interface + mock service until real API docs are supplied | Decided |

Do not use two Python runtimes unless a requirement proves it necessary.

## 3. Runtime spike (first technical task)
Pass/fail checks, run on a real Android phone:
1. Run `print("Hello")` from a string typed in the app.
2. Capture stdout and stderr separately.
3. Syntax error returns a readable message, app does not crash.
4. `while True: pass` can be stopped (timeout/kill).
5. `input()` does not freeze the app.
6. Output over a size limit is truncated.
7. Works in airplane mode.
8. Measure cold start and run latency (record real numbers).

If checks 1-5 fail with Serious Python, evaluate Pyodide before changing anything.

## 4. Screen map (original SkillBridge design, inspired by common learning-app flow)
- Welcome, onboarding questions, optional reminders (off by default)
- LMS login, nickname step
- Home: unit/lesson path, streak, XP, SkillCoins
- Lesson player: theory cards, offline-cached
- Python IDE: tabs, save, undo, redo, run, console, shortcut bar
- Exercise details and results
- Leaderboard (opt-in, nickname + avatar only, online)
- AI tutor (online only, via LMS backend with child-safety filtering)
- More: Profile, Notebook, Certificate, Summary, Settings

## 5. Security notes
- Learner code is untrusted. Local execution is not a full sandbox.
- No LMS secrets, HMAC keys or API keys in the app.
- Scores and rewards are decided by the server only.
- Submissions carry a client-generated unique ID for server-side dedupe.

## 6. Open questions for SkillBridge
- LMS API documentation and auth method (token, OAuth, session)?
- Does the LMS already have XP, streaks, leaderboard, certificates, AI tutor endpoints?
- Parental-consent and age rules the app must respect?
- Official logo, brand colours, mascot?
