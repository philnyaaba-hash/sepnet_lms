# Security and privacy

The learners this app is built for are minors. That raises the bar, and it also
means the honest answer to "is this secure?" is **mostly no, and here is
exactly where the line is.**

## What is *not* claimed

* Running learner code through `exec()` in a CPython interpreter is **not** a
  security sandbox. Isolates, WebViews, and embedded interpreters are not
  sandboxes either. Nothing in this app should be described as one.
* The app does not encrypt the local database. A rooted device can read drafts
  and submitted code.
* There is no code signing, no jailbreak/root detection, no certificate
  pinning, and no remote attestation.

## What *is* done, and what it actually buys

### Execution guard rails

`python_app/skillbridge_exec.py` provides practical limits, not isolation:

| Guard rail | Effect | What it does *not* prevent |
| --- | --- | --- |
| `input()` is backed by a list of supplied lines | The app can never freeze waiting for stdin | Anything |
| Output cap (`maxOutputChars`, default 200 000) | A runaway `print` loop cannot exhaust memory or lock the UI | Deliberate CPU burn |
| Hard process kill on timeout (`ProcessPythonRuntime`) | An infinite loop is stopped with a real `SIGKILL` | — (this one does work, for the dev/test runtime) |
| Optional `SIGALRM` CPU limit (POSIX only) | Best-effort in-interpreter timeout | Windows, and most mobile builds |
| Traceback filtering | Internal executor frames are hidden so learners only see their own code | — |

**On device, timeout enforcement is weaker than on the desktop.** The embedded
runtime runs inside the app's own interpreter and exposes no kill primitive, so
a runaway loop can only be stopped by the in-interpreter alarm, which is
POSIX-only. This is recorded in `docs/KNOWN_LIMITATIONS.md`.

### Threat model, stated plainly

| Threat | Mitigation | Residual risk |
| --- | --- | --- |
| Learner code hangs the app | Timeout + output cap | Lower on desktop than on device |
| Learner code reads the app's files | Nothing meaningful | **Accepted.** On device the code runs inside the app's private data directory |
| Learner code reaches the network | Nothing meaningful | **Accepted** for now |
| Stolen device exposes learner work | Device lock screen | **Accepted**; drafts are plaintext |
| Token theft | Token held by an `AuthTokenProvider`, never in SQLite or `shared_preferences` | Provider not yet implemented |
| Tampered app binary | Play App Signing / platform signing | Out of scope here |

The realistic threat in a classroom is not a malicious learner; it is a learner
accidentally hanging their own phone. That is why timeout and output caps are
the two guard rails worth having, and both are tested.

**Recommended next step:** run the embedded interpreter in a separate Android
process with a restrictive seccomp/SELinux profile, and cap it with cgroups.
That is real isolation. Until then, do not market the app as sandboxed.

## Secrets

**No secret exists in this repository.** Specifically:

* No HMAC key, signing key, or shared secret in Dart or Python.
* No `--dart-define` value is a credential at rest; `SB_LMS_TOKEN` is supplied
  per build and lives only in the build process's memory.
* No client-side "computation" of rewards. There is no code path that could be
  patched to mint SkillCoins, because the device never awards them — it only
  displays server values.

`docs/LMS_INTEGRATION.md` lists the tokens the client expects. The
`AuthTokenProvider` interface exists precisely so that the eventual token
storage (platform secure storage / Keychain / Keystore) is a drop-in and is
reviewable on its own.

## Privacy defaults

| Data | Where it lives | Leaves the device | Control |
| --- | --- | --- | --- |
| Learner reference (`learnerRef`) | `shared_preferences` | Only as a request header once an LMS exists | Settings → Clear local data |
| Draft code | SQLite `drafts` | No | Settings → Clear local data |
| Submitted code | SQLite `submissions` | On submit (queued if offline) | Settings → Clear local data |
| Exercise cache | SQLite `exercises` | No | Re-downloadable |
| Theme / font size / tab width | `shared_preferences` | No | Settings screen |
| Auth token | Not stored by this app | On API calls | Held by `AuthTokenProvider` |

Deliberate choices:

* **No phone number, email, name, or location is collected.** `learnerRef` is a
  random local id; binding it to a real identity is a server-side decision that
  has not been made (see the open questions in `docs/LMS_INTEGRATION.md`).
* **No advertising, no analytics, no crash reporting SDK.** None is bundled.
  Adding one later requires a review of whether it is appropriate for minors.
* **No social features, no links out of the app, no webview.**
* The submission payload (`Submission.toApiJson()`) contains only
  `submissionId`, `exerciseId`, `exerciseVersion`, `code`, and a timestamp —
  there is no field for personal data, and there is a test asserting the queue's
  contents.
* `Settings → Clear local data` removes drafts, the submission queue, and the
  local learner reference in one action.

## Child-safety design details

* Error messages are written for a beginner and never contain stack traces or
  internal paths (`ExecutionException.friendlyLabel`).
* The app never shames a wrong answer; a rejected verdict reads "Not quite yet.
  Review the requirements and try again."
* No in-app purchases, no ads, no external links.
* All interactive targets are at least 48 dp, and the editor is designed for a
  phone keyboard rather than a mouse.

## Reporting a security issue

Do not open a public issue. Contact the project maintainer directly with the
version, the platform, and reproduction steps. There is no bug bounty.
