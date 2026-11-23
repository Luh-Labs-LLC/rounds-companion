# Setup: accounts, secrets and the build path

## Owner setup (the owner does these; an agent cannot)

Confirm each with the owner at the start of a session; do not assume.

| Item | Status | Notes |
|---|---|---|
| Devpost registration for #BuildHybridAI, entered as an organization (Luh Labs LLC) | Confirm | Submitter type "Organization", name "Luh Labs LLC" |
| iPhone on **iOS 27** with Apple Intelligence on and its model downloaded | Confirm | Settings → Apple Intelligence & Siri |
| Firebase project for this app (not any other product's project), Spark plan | Confirm | AI Logic enabled with the **Gemini Developer API**; App Check enabled |
| Apple app ID / bundle ID for this app | Confirm | Proposed `com.luhlabs.roundscompanion`; use whatever the owner creates |
| App Store Connect record + TestFlight internal group | Confirm | Internal builds need no App Review |
| GitHub Actions secrets (below) | Confirm | The owner adds them in repo Settings → Secrets |

## The build path

Agents work on Windows and cannot compile Swift. Builds run on GitHub
Actions macOS runners (free for public repos), then go to TestFlight:

1. Push to `main`.
2. The workflow (to be written) selects **Xcode 27**, writes the Firebase
   config from a secret, archives with automatic signing via an App Store
   Connect API key, and uploads to TestFlight.
3. The owner installs from TestFlight on the iPhone and reports back.

Before relying on it, confirm a GitHub-hosted macOS image ships Xcode 27
(the Firebase hybrid SDK requires it). If none does, the owner has access to
a rented Mac over SSH as a fallback.

## Secrets contract

Names the workflow expects. Values never appear in the repo, logs or docs.

| Secret | Contents |
|---|---|
| `APPLE_TEAM_ID` | Apple developer team ID |
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect API issuer ID |
| `ASC_KEY_P8_BASE64` | The `.p8` API key, base64-encoded |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `GoogleService-Info.plist`, base64-encoded |

The App Check **debug token** is not a CI secret: the debug provider prints
it on the device, and the owner registers it in the Firebase console.
Release/TestFlight builds use App Attest.

## Reference docs (checked 2026-11-23)

- Hybrid inference overview: https://firebase.google.com/docs/ai-logic/hybrid
- iOS get started: https://firebase.google.com/docs/ai-logic/hybrid/ios/get-started
- iOS configuration options (inference modes): https://firebase.google.com/docs/ai-logic/hybrid/ios/configuration-options
- Apple Foundation Models framework via AI Logic: https://firebase.google.com/docs/ai-logic/apple-foundation-models-framework/get-started
- Web get started (stretch goal): https://firebase.google.com/docs/ai-logic/hybrid/web/get-started

Facts from those pages: SDK 12.13.0+, product `FirebaseAILogic`, Swift
Package Manager only, Xcode 27 and iOS 27; on-device supports text
generation and streaming from text input; structured output on-device is
supported but its detailed docs were marked "coming soon". Not yet
confirmed: the exact inference-mode API on iOS and the property reporting
which model answered. Read the configuration-options page or the SDK source.
