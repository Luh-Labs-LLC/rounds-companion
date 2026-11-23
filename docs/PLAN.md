# Rounds Companion: build plan

Deadline: **Mon Nov 30, 2026, 2:00 PM PT** (#BuildHybridAI 2026). Commits after
that are not evaluated, so the repo freezes at submission.

## The problem

Golf courses have dead zones, and a round's data is personal. A companion that
needs signal to log a shot fails exactly where it is used. On-device inference
makes the on-course part work offline and privately; the cloud handles the
heavy post-round analysis once there is signal again.

## Platform facts (Firebase docs, checked 2026-11-23)

| | iOS (primary) | Web (stretch) |
|---|---|---|
| SDK | `firebase-ios-sdk` **pinned to 12.19.3**, product `FirebaseAILogic` (hybrid exists only in 12.13.0–12.19.x; 13.0.0 removed it) | `firebase` 12.5.0+, `firebase/ai` |
| Install | Swift Package Manager only (hybrid is SPM-only) | npm |
| Runtime | **Xcode 27, iOS 27**, Apple Intelligence enabled | **Desktop Chrome 139+** with the Prompt API flag; no mobile browser |
| On-device scope | Text generation and streaming from text input; structured output supported (detailed docs "coming soon") | Single-turn text only; multi-turn falls back to cloud |
| Notes | | Call `initializeDeviceModel()` on a user gesture; requests sent before the model finishes downloading go to the cloud |

Backend: Gemini Developer API on the free Spark plan. App Check is required;
the debug provider is acceptable for judging.

Verified in the SDK source on 2026-11-23 (details in `docs/SETUP.md`):
prefer-on-device is `HybridModel(primary: SystemLanguageModel.default,
secondary: geminiModel(name:))` passed to `generativeModelSession(model:)`;
the answering model is `response.rawResponse.modelVersion`; the cloud model
is `gemini-3.5-flash-lite` (no billing required).

## Routing: what runs where

| Job | Where | Why |
|---|---|---|
| Club suggestion for a distance | **No AI**: plain math over the golfer's stored carry yardages | Deterministic; an LLM adds nothing |
| Spoken shot (on-device speech recognition) to text | **On-device** (Apple Speech) | Hands-free between swings, airplane mode |
| Shot text to a structured record `{ club, distanceYards, outcome, missDirection, lie, notes }` | **On-device first** (hybrid) | Must work in airplane mode, mid-round |
| In-round caddie: today's miss pattern phrased in 2 sentences from stats computed in code | **On-device first** (hybrid) | Small context, private, offline |
| Scorecard or tee-sign photo to hole pars and yardages (before the round), or a finished card (after) | **Cloud by capability**: the on-device model takes text only, so the hybrid session falls back to Gemini and the badge flips | Removes manual course setup; shows routing by capability |
| Post-round debrief | **Cloud** | Whole round, longer output |

Image fallback verified in firebase-ios-sdk 12.19.3: a non-text prompt part
makes the on-device session throw `unsupportedPromptContent`
(`FirebaseAI/Sources/Types/Public/Part.swift`) and `HybridModelSession` retries
on the secondary model, **unless the on-device session already has history**.
Use a fresh session per scan.

Out of scope (owner, 2026-11-23): phone launch monitor (ball/club speed),
LiDAR green reading, swing tempo. None uses Firebase AI Logic, and the first
two cannot be measured honestly or tested on a real green before the deadline.

### Judging (owner-supplied rules)

Four equally weighted criteria; ties broken in this order: **Technological
Implementation** (how effectively the app uses Firebase AI Logic hybrid
inference), **Design** (a complete, coherent product), **Potential Impact**,
**Quality of the Idea**. Multi-platform entries get strong Grand Prize
consideration. App Check debug tokens are accepted.

Guardrails:
- A deterministic shorthand parser covers common forms (`7i 162y`, `PW 95`,
  `driver 240 left`). It validates the model's output and catches it if the
  model returns something malformed. A bad response never corrupts a shot record.
- Round statistics (fairways, greens, putts, misses by direction) are
  **computed in code**. The cloud model only narrates numbers the app computed.
  No strokes-gained or "strokes lost" figures: there is no benchmark dataset
  behind them.
- Every AI result shows a badge (**On-device** / **Cloud**) driven by the SDK's
  own report of which model answered, plus latency. The model state
  (available / downloading / unavailable) is visible, with graceful fallback
  when Apple Intelligence is off.

## Data

- Local first: SwiftData on iOS (IndexedDB on web).
- Optional sync: Firebase Anonymous Auth + Firestore, keyed by a round sync
  code so a round logged on the phone opens in the web review.
- Firestore rules: a round can be fetched by its code but rounds can never be
  listed or enumerated; only the creating user writes. Rules tested against
  the emulator.
- No personal data in the repo, the submission form, or test instructions.

## Secrets

Never committed: `GoogleService-Info.plist`, `.env*`, App Check debug tokens,
App Store Connect keys (`*.p8`). Ship `.example` files and setup steps instead.
Signing credentials live in GitHub Actions secrets, set by the owner by hand.

## Builds

The repo is public, so GitHub-hosted macOS runners are free. Use the image
with Xcode 27 (confirm it exists before relying on it). CI builds, signs,
and uploads to TestFlight. Agents on Windows cannot compile Swift locally.

## Schedule

| Day | Work | Gate |
|---|---|---|
| Mon Nov 23 | Repos, Firebase project, app ID; confirm the phone is on iOS 27 with Apple Intelligence on | |
| Tue Nov 24 | SwiftUI skeleton; one on-device call through Firebase AI Logic; internal TestFlight build | |
| Wed Nov 25 | Shot logging (voice and shorthand), local storage, on-device caddie; **submit external TestFlight build for beta review** | No working on-device call on the phone by end of day: stop |
| Thu Nov 26 | Scorecard / tee-sign photo (cloud by capability), cloud debrief, Firestore sync (Thanksgiving: no owner time needed) | |
| Fri Nov 27 | Thin Chrome web companion synced via Firestore (multi-platform; insurance if TestFlight review stalls) **only if the iOS core is solid Thursday night**; otherwise polish | |
| Sat Nov 28 | Web review or more polish; README, setup guide, "built during the contest" notes | |
| Sun Nov 29 | Final fixes; record the video (under 3 min, YouTube, English) | |
| Mon Nov 30 | Submit by noon PT; freeze the repo | |

## Submission checklist

- [ ] Public repo, Apache 2.0 detected in the About section
- [ ] Firebase AI Logic imported **and called** at runtime (not just named in the README)
- [ ] README: value proposition, how Firebase AI Logic is used, setup, testing instructions
- [ ] Summary of what was built during the contest; any pre-existing code disclosed
- [ ] Demo video on YouTube, under 3 minutes, showing it running on the phone and the airplane-mode switch
- [ ] Test build link (public TestFlight if beta review clears), otherwise build instructions
- [ ] No keys, secrets or personal data anywhere in the repo or form
