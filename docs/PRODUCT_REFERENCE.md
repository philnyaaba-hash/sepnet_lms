# Product reference: peer app notes

## What this file is

Notes on apps in our category, kept so that design decisions during
implementation are deliberate rather than improvised. Adding a competitor's idea
is fine; adding it *because a competitor has it* is not.

## Source and confidence — read this first

Everything below is from the **Google Play store description** *and the eight
store screenshots* of *Learn Python with IDE - Codino* (Zynith Studio, package
`com.codino_official2.codino`), fetched 2026-10-10/11. It has 1K+ downloads.

**I have not used the app.** Nothing here is a claim about how Codino actually
behaves, how it feels, or whether it delivers on its description. Store copy is
marketing written by the developer; treat every item as "they say". Screenshots
are the developer's chosen promotional frames — they show what the developer
*wants* shown, not the app at its worst.

### What the screenshots actually show (verified visually)

The screenshots use a light-blue marketing band around a **dark navy in-app
UI**. Reading them:

| Screen | What is visibly there |
| --- | --- |
| Lesson ("Learn Python Step-by-Step") | `X` close, a **lesson progress bar**, a **star**, and a **lightning bolt with a count (⚡5)**. Body prose with **inline bordered code chips** (`if`, `else` set as boxed tokens inside the sentence), a magnifier callout card, full-width blue **CONTINUE**. |
| Fill-in-the-blank ("Interactive Bite-Sized Lessons") | Same top chrome. Inline code chips *and* inline syntax-highlighted string literals in the prose. An input line with a caret box and a **`me` avatar chip**. Tappable **answer chips** along the bottom (`if` / `when` / `is`), then flag / refresh / undo icons and a **CHECK** button. |
| Editor ("Run Code 100% Offline") | **Multi-file tabs** (`main.py`, `Nth_fibonacci.py`, `+`), a left **file rail**, blue **Run** button top-right, line numbers, highlighted current line, normal Android keyboard. |
| Recaps ("Quick Recaps & Cheat Sheets") | Back arrow, lesson title, a **breadcrumb** (`Python Kickstart → Variables, Numbers & Strings`), headed prose sections with bullet lists and inline code chips, a dark **code block**, and an **"Open in IDE"** button that hands off to the editor. |
| Notebook ("Free Notebook With 20+ Packages") | Jupyter-style: Files / Download / Run all / Add Code / Add Text, with matplotlib output rendered below the cell. |
| AI tutor ("24/7 AI Coding Tutor") | Chat, suggestion chips, a model picker labelled **"Lite"**, and a **"Free Certificate Included!"** starburst. |

### What the screenshots do *not* show

**No leaderboard, no streak screen, no currency balance.** The store *text*
claims daily streaks, a global podium, and Lux/Gold/Energy — but of those only
**⚡5 energy** and a **⭐** are visible, both as small top-bar counters. The
streak and leaderboard claims are **unverified by anything I can see**. My
earlier draft listed streaks as a top adoption; treat it as "they claim it",
not "they shipped it".

### Correction — device screenshots supersede everything above

On 2026-10-11 the user supplied **19 real device screenshots** of the installed
app. They are better evidence than the store's promotional frames and they
**overturn one claim made earlier in this file**: streaks, a leaderboard and a
gem currency do exist and are shipped. They were listed above as "unverified"
only because the store's chosen screenshots did not show them.

What the device screenshots establish, in the order they appear:

**Onboarding** — a full, well-built flow, and the clearest thing to learn from.
Mascot + a speech-bubble prompt + a top progress bar, then radio-card
questions:

| Screen | Prompt | Options |
| --- | --- | --- |
| 1 | (splash) "Learn Python for free with simple, bite-sized lessons!" | START LEARNING / I AM AN EXISTING USER |
| 2 | "Hey there! Ready to master Python?" | — |
| 3 | "Why are you learning Python?" | Just exploring · Boost my career · Just for fun · School stuff · Build my own things |
| 4 | "How much time can you spend a day?" | 5 min/**Easygoing** · 15 min/**Standard** · 30 min/**Committed** · 60 min/**Immersive** |
| 5 | "Want me to remind you to practice?" | Smart Reminders — "Get a friendly nudge to keep your Python streak alive!" ALLOW / LATER |
| 6 | (after allowing) "Perfect! Consistency is key." | ALLOW disabled — real feedback, not a dead end |
| 7 | "Alright, you're all set! Let's dive in." | AI Tutor · Easy Lessons · Python IDE · Quick Recaps |
| 8 | "Join Codino" / "Complete Profile" | Continue with Google · Sign up with email · Nickname field |

Two things stand out. **Every question is one line and answerable in a tap** —
no typing until the final nickname. And the time-per-day answers pair a
duration with a personality label ("15 min per day" → *Standard*), which makes
a commitment feel like an identity rather than a setting.

**Home** — a Duolingo-style node path: section/unit card, pentagon nodes
connected by a curve, a "Start" bubble on the active node, 5-tab bottom nav
(home · IDE · leaderboard · AI · more). **Top bar: 🔥 0 streak, ⚡ 5 energy,
💎 50 gems.**

**Node card → lesson** — tapping a node raises a card with a **`THEORY` badge**,
a title, a one-line description, and **`START +10 XP`**. The lesson itself is
minimal: `X` close, progress bar, ⭐, 🚩, plain prose, `CONTINUE`. Generous
line height, ~20 px, one idea per screen.

**Leaderboard** — real and populated. Tabs for *7 Days XP* / *All Time Streak*,
a 1-2-3 podium, avatars, a live countdown chip ("REFRESHES IN 4D 6H 34M"),
and per-row streaks ("🔥 2d streak") beside real usernames.

**IDE** — `main.py` tab, `+`, a folder icon, filename header with save / undo /
redo, and a blue **▶ Run**. Single file here; the store screenshot showed
multi-file tabs.

**AI tutor** — "Hey, let's learn Python", four action cards (Explain loops ·
Quiz me · Fix my code · Challenge), a model picker set to **"Auto"**, and a
mic. **Overflow menu** — Profile · Notebook · Certificate · Summary.

### Copy worth stealing, quoted verbatim from the device screenshots

> "Think of Python as a super-fast robot translator. It takes the simple
> instructions you write in English and translates them into a language that
> computers can understand instantly."

> "Every single line matters. Python reads top-to-bottom, one at a time — just
> like you're reading this. It finishes line one before it even glances at
> line two."

That is the whole style in two paragraphs: **a concrete metaphor, second
person, present tense, and a comparison to something the learner is already
doing** ("just like you're reading this"). No jargon, no "note that", no
definitions. It is markedly better than what we currently ship, and it is the
single most useful thing to copy.

Note also what the lesson screens do *not* contain: no inline boxed code
tokens. Those appear only in the fill-in-the-blank exercise (store
screenshot), where the learner picks `if` / `when` / `is` as tappable chips.
So the two features are separate: **prose lessons** and **chip-based fill-in
the blank**.

Everything below the fold of this section is therefore **text-sourced** unless
it appears in a table above.

## Why this peer matters

It is not a market leader; it is roughly our size, aimed at the same
constraints: emerging market, low-cost devices, learners with intermittent
connectivity, no budget. Its headline claims are *free, no ads, offline IDE,
100% of the curriculum*.

That is our bet too. The useful signal is not "they are winning", it is "a peer
is selling the same promises we are building toward", which says the positioning
is plausible.

One small quality signal in the listing itself: two of its bullets ("Develop
good coding habits…" and "Stay motivated with daily streaks…") are each printed
twice, verbatim, with different follow-on wording. Confirmed against the full
description, not just the truncated preview. Nothing about the app, but it
suggests the description was assembled rather than edited.

### Data safety, as declared (2026-10-11)

| Field | Their declaration |
| --- | --- |
| Shares with third parties | App activity, App info and performance, and Device or other IDs |
| Collects | Personal info, App activity and 2 others |
| Transit | Encrypted |
| Deletion | Can be requested |
| Store category | **Education**, not "Kids" |

No COPPA / GDPR-K style statement appears anywhere on the listing. That is the
clearest single reason our posture must differ rather than match: our audience
is explicitly 10–18, so under-13s are in scope by construction, and Ghana's
Data Protection Act, 2012 (Act 843) applies. See
`docs/SECURITY_AND_PRIVACY.md`.

Their listing also names its own limits honestly enough for a store page: an
AI tutor needs a connection, and they share app activity and device identifiers
with third parties. Our child-safety posture is a higher bar than that,
deliberately.

## Language and copy — the part worth studying

Their copy is consistently **benefit-first and second-person**, and it *names*
its mechanics. Compare:

| Their copy | What makes it work |
| --- | --- |
| "Learn to code anytime, anywhere." | Benefit, not feature. No jargon. |
| "Python can feel overwhelming, but Codino makes it simple." | Names the anxiety, then dissolves it. Speaks to the beginner directly. |
| "No experience? Start with the basics and build skills gradually." | Asks a question the reader is already asking themself. |
| "Learning by doing?" | Three words. A section header that is also a promise. |
| "Practice with interactive quizzes that test your understanding immediately." | Feature *plus* the payoff ("immediately"). |
| "Get 10 Free Lux as a welcome gift when you set up your profile!" | Warmth, and a reason to complete the first step. |
| "**Competitive Leaderboards:** Compete globally and showcase your Streak and XP counts on the podium." | Bold mechanic name, then what you get from it. |

### How our copy reads today

Ours is accurate and neutral — which is not the same as welcoming. For a
12-year-old opening the app for the first time, several strings read like a
system dialog.

| Ours | Problem | Direction |
| --- | --- | --- |
| "Instructions" | A label a teacher uses, not a learner. | "What to do" |
| "What you will learn" | Fine, but flat. | "In this challenge" |
| "Requirements" | Reads like a spec. | "You'll know you've got it when…" |
| "Not accepted yet - try again" | Leads with the negative. | "Not quite — have another go" |
| "Saved - waiting to send" | Mechanical. | "Saved on your phone. We'll send it when you're back online." |
| "Complete a challenge to earn your first achievement." | Correct, cold. | "Finish a challenge and your first badge is yours." |
| "SkillCoins are confirmed by the SkillBridge LMS after it grades your submission. This app never awards coins on its own." | Right message, wrong shape — it is a *trust* guarantee buried as a footnote. | Keep the guarantee, lead with the reward: "Earn SkillCoins when your work is marked. We only count what your teacher's system has confirmed." |

The last one matters most. "This app never awards coins on its own" is a real
security property (`docs/SECURITY_AND_PRIVACY.md`) and it should be a *selling
point*, not a disclaimer. Codino sells rewards; we can sell **rewards you can
trust**, which is a stronger and more honest claim.

## Gamification

They run three currencies — **Lux, Gold, Energy** — plus daily streaks, XP, a
global leaderboard, and a **Streak Saver** that spends Lux to protect a streak.

### Worth adopting

1. **Daily streaks, with a grace token.** We have no retention mechanic at all,
   and this is the biggest gap in the list. Crucially, a *streak saver* is more
   humane for our audience than for theirs: a child on a shared phone with
   unpredictable power will miss a day through no fault of their own. Ours
   should be **earned by mastery, never bought**.
2. **A currency needs a sink.** "SkillCoins" already exists as a name, which is
   good — but there is nothing to spend them on, so the number has no meaning.
   Codino's Lux→Streak Saver loop is the pattern: earn, then *use* it for
   something the learner wants.
3. **Quizzes between exercises.** They sell "test your understanding
   immediately". Multiple-choice checks are cheap, work fully offline, and fill a
   real hole: right now the only feedback available is running code.
4. **Short teaching content before the task.** They describe "short, simple
   lessons" and "interactive slides". Our `Exercise.instructions` is a single
   sentence. Three or four sentences of teaching before the challenge would help
   a beginner far more than another hint, and it ships offline as plain text in
   the exercise payload.
5. **A certificate on completion.** Motivational and shareable. Ours must be
   LMS-verified — consistent with rewards coming only from a trusted server.
6. **A first-run welcome moment.** They gift currency on profile setup. Our
   first-run experience is currently just the home screen
   (`docs/KNOWN_LIMITATIONS.md`, onboarding). A single welcome beat with a small
   gift is cheap and sets the tone.

### Deliberately not adopting

1. **The AI tutor.** It needs a connection, which contradicts our offline-first
   rule, and an unfiltered LLM talking to under-13s is precisely the risk
   `docs/SECURITY_AND_PRIVACY.md` exists to prevent. If it ever arrives it must
   be server-side, moderated, logged and under guardian control. This is a
   recorded rejection, not an oversight.
2. **Energy gating.** Time-based energy that depletes punishes exactly our
   learner: one shared phone, an hour in the evening, a flat battery. If we gate
   anything, gate by **mastery**, never by the clock.
3. **A public global leaderboard.** `learnerRef` is deliberately anonymous
   (`docs/KNOWN_LIMITATIONS.md`). A leaderboard for children needs consent and
   identity questions answered first, and the teacher-mediated classroom version
   is the right shape — not a global podium.

## Where this would land in our codebase

| Idea | Touches | Blocked on |
| --- | --- | --- |
| Streaks + streak saver | new `features/streaks/`, `SettingsRepository`, achievements screen | Nothing — buildable now |
| SkillCoin sink | achievements screen, `MockLmsClient` | The 7 LMS open questions |
| Quizzes | new `features/quizzes/`, exercise payload | Nothing — buildable now |
| Lesson text before the task | `Exercise` model, `mock_lms_client.dart`, `exercise_details_screen.dart` | Nothing — buildable now |
| Line-by-line execution trace | `python_app/skillbridge_exec.py`, editor console | Nothing — buildable now |
| Certificate | achievements screen | LMS verification |
| Onboarding welcome | new screen, `shared_preferences` first-run flag | Nothing — buildable now |

Line-by-line execution is the strongest idea in their listing and the one we can
do most honestly: we already run a real interpreter and already parse structured
results, so a step trace would be **real execution**, not an animation of what
execution is supposed to look like.
