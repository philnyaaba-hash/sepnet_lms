# Product reference: peer app notes

## What this file is

Notes on apps in our category, kept so that design decisions during
implementation are deliberate rather than improvised. Adding a competitor's idea
is fine; adding it *because a competitor has it* is not.

## Source and confidence — read this first

Everything below is from the **Google Play store description** of
*Learn Python with IDE - Codino* (Zynith Studio, package
`com.codino_official2.codino`), fetched 2026-10-10. It has 1K+ downloads and was
updated the same day.

**I have not used the app.** Nothing here is a claim about how Codino actually
behaves, how it feels, or whether it delivers on its description. Store copy is
marketing written by the developer; treat every item as "they say". Where a
feature is listed twice in their own description with different wording, that is
noted, because it is a small signal about how carefully the listing was written.

Screenshots were not part of the fetch, so there are **no interface observations
here** — only what the text asserts.

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
twice with different follow-on wording. Nothing about the app, but it suggests
the description was assembled rather than edited.

Their listing also names its own limits honestly enough for a store page: an
AI tutor needs a connection, and their data-safety section says they share app
activity and device identifiers with third parties. Our child-safety posture is a
higher bar than that, deliberately.

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
