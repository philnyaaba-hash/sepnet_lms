# AI Developer Brief: SkillBridge Python Lab

## 1. What this is
SkillBridge Python Lab is a mobile app (Flutter, Android first, iOS later) for SKILLBRIDGE DIGITAL TALENT & OUTSOURCING ACADEMY. It is a companion to the academy's existing LMS. Learners watch lessons in the LMS, then use this app to write and run real Python on their phones.

Audience: learners aged 10-18, mostly on affordable Android phones in Ghana, often with unreliable internet. The app must be lightweight, beginner-friendly, accessible, and work offline.

The master specification is the separate "MASTER DEVELOPMENT PROMPT: SKILLBRIDGE PYTHON LAB". This brief summarises it and adds the screen design. Where they conflict, the master prompt wins.

## 2. Current status (honest)
- Created: `.gitignore`, `README.md`, `docs/ARCHITECTURE_DECISION_RECORD.md`, `lib/app/theme.dart`, `lib/app/app.dart`, `lib/features/onboarding/welcome_screen.dart`.
- NOT done: Flutter platform folders (`flutter create` not yet run), `main.dart`, `pubspec.yaml`, editor, Python runtime, storage, LMS layer, all other screens.
- Nothing has been compiled, run or tested. Flutter has not been verified on the developer's machine.

## 3. What to build (core features)
1. Real Python code editor (CodeMirror 6 in a WebView, bundled offline; fall back to a Flutter-native editor if it performs badly).
2. Real embedded Python execution (evaluate Serious Python first; Pyodide only if Serious Python fails the runtime spike in the ADR). Never fake output.
3. Output console with stdout, stderr, exceptions, exit status, duration, timeout and truncation handling.
4. Coding shortcut bar: ( ) [ ] { } ' " : = indent and common operators, inserting at the cursor without losing selection.
5. SQLite storage (drafts, exercise metadata, run history, pending submissions, sync state, last-known progress).
6. Offline-first: edit and run with no internet; persistent submission queue; sync when online with bounded exponential backoff and idempotency keys.
7. LMS integration behind an interface, with a mock service until real API docs exist.
8. Display of server-verified XP, SkillCoins, achievements, certificates.

## 4. Non-negotiable rules
- Learner code is untrusted. Local execution is NOT a full sandbox; document the limits. Add timeouts, output caps, no file/network access to app data.
- The server decides grading and rewards. The app never awards SkillCoins, never trusts local scores, and never contains secrets, HMAC keys or LMS service keys.
- Each submission has a client-generated unique ID; the backend dedupes.
- Child privacy: no ads, minimal analytics, no uploading code without an explicit Submit action, no phone numbers or real names on public screens, reminders and leaderboard are opt-in, respect LMS login and parental-consent rules.
- Do not copy another product's name, mascot, artwork or lesson text.
- Do not claim a feature works until it is implemented and tested. Never fabricate command output.

## 5. Visual design
- Dark-first Material 3 theme. Palette (see `lib/app/theme.dart`): background #12151C, surface #1B2029, raised surface #262D3A, primary teal #14B8A6, accent amber #FFB020 (XP and SkillCoins), text #F2F5F9, muted text #9AA5B8, error #FF6B6B, success #4ADE80.
- Large rounded buttons (min height 56, radius 16), generous padding, readable 16-18 sp body text, high contrast, minimal animation.
- Friendly original mascot (to be designed; icon placeholder for now) speaking in a rounded speech bubble during onboarding.
- Bottom navigation with 5 tabs: Learn (home path), Code (IDE), Ranks (leaderboard), Tutor (AI), More.

## 6. Screens

### 6.1 Welcome
Centered wordmark "SkillBridge / PYTHON LAB" at top, mascot illustration in the middle, one-line tagline, then a filled teal "START LEARNING" button and an outlined "I ALREADY HAVE AN ACCOUNT" button at the bottom. (Implemented as a first draft.)

### 6.2 Onboarding (full-screen steps with back arrow and a thin progress bar at top)
Each step shows the mascot at top-left with a speech bubble asking a question, then options below and a bottom "CONTINUE" button that stays disabled until a choice is made.
1. Greeting: "Ready to master Python?"
2. Why are you learning Python? Single-choice cards with icon and radio circle: Just exploring, Boost my career, Just for fun, School stuff, Build my own things.
3. How much time per day? 5 / 15 / 30 / 60 minutes, each with a label (Easygoing, Standard, Committed, Immersive).
4. Reminders: explain benefit, "ALLOW" and "LATER" options. Only trigger the Android notification permission when the learner taps Allow.
5. Summary of what the app offers: AI tutor, short lessons, offline Python editor, quick recaps. CONTINUE enters the app.
Answers are stored locally and may be synced to the LMS profile only if the LMS supports it.

### 6.3 Login and profile
Bottom sheet over the home screen. Primary path: log in with the existing LMS account. Do not add Google or email sign-up unless the LMS supports it. A second sheet, "Complete Profile", asks for a nickname (no real name required) and a FINISH button.

### 6.4 Home (Learn tab)
- Top bar: logo, streak (flame + number), XP (lightning + number), SkillCoins (gem + number). Values come from the LMS; show last-known values offline with an "offline" indicator.
- A rounded header card: "Section" label and unit title, for example "Unit 1: Python Kickstart".
- Below it, a winding vertical path of rounded pentagon-style nodes. Node icons show type: theory (head/gear), practice (terminal), code (angle brackets), quiz (numbered list). The current node is bright blue/teal with a "Start" tooltip; locked nodes are grey.
- Tapping a node opens a bubble popup: type tag (THEORY, PRACTICE, CODE, QUIZ), lesson title, one-line description, and a white "START +10 XP" button. The XP value is a display of what the LMS will grant, not something the app awards.

### 6.5 Lesson player
Full-screen. Top row: close (X), progress bar, and small icons for help and report. Content is short text cards with one idea each, revealed one at a time, with a big "CONTINUE" button fixed at the bottom. Content is fetched from the LMS and cached for offline use.

### 6.6 Python IDE (Code tab)
- Top: back arrow, file tabs (for example `main.py`), "+" to add a file, folder icon to open files.
- Toolbar row: current file name, Save, Undo, Redo, and a prominent blue "Run" button (becomes "Stop" while running).
- Main area: dark code editor with line numbers and Python syntax highlighting.
- Bottom, above the system keyboard: the shortcut bar (brackets, quotes, colon, equals, indent, operators), horizontally scrollable.
- Below or sliding up from the editor: output console showing stdout, errors in red with a friendly explanation, execution status and time. For exercises, show test results and a Submit button.
- Layout must resize correctly when the keyboard opens.
- If code uses input(), show an input field in the console instead of blocking.

### 6.7 Exercise details and results
Details: title, instructions, learning objectives, starter code, requirements, collapsible hints, submission status (Not submitted / Pending / Accepted / Rejected). Results: output, syntax errors, test results, beginner-friendly feedback, Retry, and a confirmation shown only when the server confirms receipt.

### 6.8 Leaderboard (Ranks tab, online only)
Title, a "refreshes in ..." pill, tabs "7 Days XP" and "All Time Streak". A podium with the top 3 (avatar, nickname, XP; crown on first), then a ranked list showing rank, avatar, nickname, streak and XP. Opt-in only; nicknames and avatars only.

### 6.9 AI Tutor (online only)
Header with a menu button, a mode selector (Auto), and an info button. Centered mascot-style icon and greeting "Let's learn Python". A 2x2 grid of quick-prompt cards: Explain loops, Quiz me, Fix my code, Today's challenge. A chat input at the bottom with a voice button and send button. The AI key must NEVER be in the app: all requests go through an LMS backend with child-safety filtering. Build with a mock until that endpoint exists.

### 6.10 More menu
Bottom sheet list: Profile, Notebook (saved notes and snippets), Certificate (server-issued), Summary (recap of completed lessons), Settings (theme, font size, editor preferences, offline storage, app version, privacy and safety info, clear local drafts).

## 7. Suggested architecture
Feature-first folders under `lib/`: `app/`, `core/` (config, errors, networking, storage, security), `features/` (home, editor, python_runtime, exercises, submissions, offline_sync, achievements, settings, onboarding), `integrations/lms/`, `shared/widgets/`. Keep presentation, business logic, local storage, runtime execution and remote services separate. Use a simple, maintained state-management solution; do not over-engineer.

## 8. Build order
1. Run `flutter create`, add `main.dart`, confirm the Welcome screen runs on a real Android phone.
2. Runtime spike (ADR section 3). Decide Serious Python vs Pyodide using real results.
3. Editor, shortcut bar, console.
4. SQLite drafts and restore.
5. Exercises, submission queue, mock LMS, sync.
6. Onboarding, login, profile, home path, lesson player.
7. Achievements, leaderboard, AI tutor mock, More menu screens.
8. Tests, docs, debug APK, release checklist.

## 9. Open questions for SkillBridge
LMS API docs and auth method; whether the LMS already has XP, streaks, leaderboard, certificate and AI tutor endpoints; parental-consent rules; official logo, colours and mascot.
