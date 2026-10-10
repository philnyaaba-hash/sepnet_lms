# LMS integration

## Current state — read this first

**There is no LMS API specification in this repository.** No endpoint has been
documented, implemented, or called. Everything in `HttpLmsClient` is a
*proposed* contract written by the app team so that the client is ready the day
the backend exists. It has never received a real response.

Until the backend exists, the app uses `MockLmsClient`, which is the
authoritative reference for the *semantics* the client depends on. If the real
LMS cannot provide those semantics, the client must change — not the other way
round.

## What the app needs from an LMS

These are the actual requirements, independent of any URL shape:

1. **Exercise content, versioned.** Enough to render an exercise offline after
   it has been seen once, with a monotonically increasing `version` so a stale
   submission can be recognised.
2. **A grading verdict per submission.** The device must never decide that a
   solution is correct.
3. **Idempotent submission acceptance.** The same submission sent twice (retry
   after a dropped connection) must be graded once and must not award points
   twice.
4. **Server-authoritative progress and achievements.** Points and badges are
   read back from the server.
5. **A distinguishable auth failure.** The client must be able to tell
   "your session expired" from "the network is down", because the first should
   stop syncing and prompt a sign-in, and the second should keep retrying.
6. **A distinguishable permanent failure.** A 4xx-style rejection must not be
   retried forever.

`MockLmsClient` implements all six, and
`test/submission_sync_service_test.dart` proves the client behaves correctly
against each of them.

## Proposed contract

All paths are relative to `SB_LMS_BASE_URL`. All requests send
`Content-Type: application/json` and, when a session exists,
`Authorization: Bearer <token>`.

### `GET /me`

Current learner identity.

```json
{ "id": "lrn_8f21", "displayName": "Ama" }
```

### `GET /exercises`

```json
{
  "exercises": [
    {
      "id": "ex-hello-world",
      "lessonId": "lesson-1",
      "title": "Hello, World!",
      "instructions": "Use print() to display a friendly greeting.",
      "objectives": ["Understand what a Python program is"],
      "requirements": ["Print the text: Hello, World!"],
      "starterCode": "# Write your code below\n",
      "hints": ["Text must be in quotes: print('Hello, World!')"],
      "version": 1,
      "sampleStdin": [],
      "expectedOutput": null
    }
  ]
}
```

`version` is required. `sampleStdin` is a list of lines fed to `input()` for
exercises that read input. `expectedOutput` is optional and used only for local
self-check hints — the authoritative grade is always the server's.

### `GET /exercises/{id}`

A single exercise object (same shape as one element above).

### `POST /submissions`

Request headers:

```
Idempotency-Key: <submissionId>     # client-generated UUID, required
```

Request body:

```json
{
  "submissionId": "3f1c…",
  "exerciseId": "ex-hello-world",
  "exerciseVersion": 1,
  "code": "print(\"Hello, World!\")\n",
  "clientCreatedAt": "2026-01-05T09:12:33.000Z"
}
```

Response `201` (or `200` on a replay):

```json
{
  "submissionId": "3f1c…",
  "verdict": "accepted",          // "accepted" | "rejected"
  "serverRef": "SRV-000123",
  "pointsAwarded": 10,
  "message": "Great work! Your solution was accepted.",
  "duplicate": false              // true when the id was already graded
}
```

**Server obligations:**

* Treat `submissionId` as an idempotency key. A replay must return the original
  receipt with `duplicate: true` and must not re-grade or re-award.
* Return `401`/`403` for an expired or invalid session.
* Return `400` for a malformed or empty submission (permanent; the client will
  not retry).

### `GET /submissions/{id}`

Returns the same receipt object. Used to reconcile after an ambiguous outcome.

### `GET /progress`

```json
{ "totalPoints": 30, "completedChallenges": 3, "totalChallenges": 8 }
```

### `GET /achievements`

```json
{
  "achievements": [
    { "id": "first-steps", "title": "First Steps",
      "description": "You submitted your first Python solution.", "points": 0 }
  ]
}
```

## Open questions that must be answered before production

These are genuinely unknown. Each one can change the client.

1. **Authentication.** Who issues the bearer token, for how long, and how does a
   12-year-old on a shared device sign in without a password manager? The
   client currently only defines an `AuthTokenProvider` seam.
2. **Grading.** Server-side unit tests? Static analysis? Human review? The
   verdict vocabulary is currently just `accepted` / `rejected`; a `graded`
   state with partial credit is plausible and would need a client change.
3. **Offline grading.** Can the server grade offline submissions in batches, or
   must every submission be individually acknowledged? Batching would change the
   receipt contract.
4. **Identity vs. privacy.** `learnerRef` is currently an anonymous local id.
   Binding it to a real learner record is a server-side decision with real
   privacy consequences for minors — see `docs/SECURITY_AND_PRIVACY.md`.
5. **Rate limits and payload size.** What is the maximum `code` length the
   server will accept, and what happens to a learner on a metered connection who
   submits a large solution repeatedly?
6. **Stale exercises.** When `exerciseVersion` does not match the server's
   current version, should the server reject, accept, or accept-with-warning?
   The client currently sends the version and does nothing special on mismatch.
7. **Retention.** How long does the LMS keep submitted code, and can a learner
   (or their guardian) request deletion? The local queue has a
   "clear local data" control; the server side has no equivalent yet.

## Testing the client without a backend

`MockLmsClient` is injectable and configurable:

```dart
MockLmsClient(
  latency: const Duration(milliseconds: 200),
  failNetworkTimes: 2,        // throw NetworkException twice
  failAuthenticationTimes: 1, // then throw AuthenticationException
  grader: (s) => GradeVerdict.rejected,
)
```

`HttpLmsClient` accepts an injected `http.Client`, so it can be tested against a
fake transport the moment a specification exists. That test has deliberately not
been written yet — writing it would mean inventing an API and then "verifying"
the client against our own invention.

## Replacing the mock

1. Confirm the seven open questions above in writing.
2. Build `HttpLmsClient` with an injected `http.Client` and write tests against
   the agreed specification.
3. Provide `SB_LMS_BASE_URL` at build time.
4. Implement a real `AuthTokenProvider` backed by platform secure storage.
5. Keep `MockLmsClient` — it remains the fixture for the offline and retry
   tests, which no real backend can reproduce deterministically.
