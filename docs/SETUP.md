# Setup: accounts, secrets and the build path

## Owner setup (the owner does these; an agent cannot)

Confirm each with the owner at the start of a session; do not assume.

| Item | Status | Notes |
|---|---|---|
| Devpost registration for #BuildHybridAI, entered as an organization (Luh Labs LLC) | **Done** (owner, 2026-11-23) | Submitter type "Organization", name "Luh Labs LLC" |
| iPhone on **iOS 27** with Apple Intelligence on and its model downloaded | Confirm | Settings → Apple Intelligence & Siri |
| Firebase project for this app (not any other product's project), Spark plan | Confirm | AI Logic enabled with the **Gemini Developer API**; App Check enabled |
| Apple app ID / bundle ID for this app, with the **App Attest** capability | Confirm | Proposed `com.luhlabs.roundscompanion`. If different, change `PRODUCT_BUNDLE_IDENTIFIER` in `ios/project.yml` (the only place it lives) |
| iOS app registered in the Firebase project, `GoogleService-Info.plist` downloaded | Confirm | Its `BUNDLE_ID` must match the app ID. It goes into a secret, never the repo |
| App Check: register the iOS app with the **App Attest** provider | Confirm | Firebase console → Security → App Check → Apps. TestFlight builds are Release builds and use App Attest, not the debug provider |
| The iPhone registered as a device (its UDID) in the developer account | Confirm | Certificates, Identifiers & Profiles → Devices. Automatic signing may refuse to archive with zero registered devices; to be verified on the first CI run |
| App Store Connect record + TestFlight internal group | Confirm | Internal builds need no App Review |
| App Store Connect API key for CI | Confirm | Users and Access → Integrations → Team keys. Use the **Admin** role: CI signs with cloud-managed certificates via `-allowProvisioningUpdates`, and lower roles may not be allowed to create them |
| GitHub Actions secrets (below) | Confirm | The owner adds them in repo Settings → Secrets |

## The build path

Agents work on Windows and cannot compile Swift. Builds run on GitHub
Actions macOS runners (free for public repos), then go to TestFlight:

1. Push to `main` (or run the workflow by hand).
2. `.github/workflows/ios.yml`, job **compile**: on the `xcode-27` runner
   (public preview; ships Xcode 27.0, 27.1 and 27.2, workflow selects 27.1),
   installs XcodeGen, generates the project from `ios/project.yml` with the
   placeholder Firebase config, and builds for device without signing. Needs
   no secrets; this is the only compile check agents get.
3. Job **testflight** (main only): skips with a notice if any secret is
   missing. Otherwise writes the Firebase config and API key from secrets,
   archives with automatic signing (`-allowProvisioningUpdates` plus the API
   key, build number = workflow run number), and exports with
   `destination=upload`, which uploads to App Store Connect.
4. The owner installs from TestFlight on the iPhone and reports back.

The owner has a rented Mac over SSH as a fallback if the runner fails.

## The app on disk

- `ios/project.yml`: XcodeGen spec. The `.xcodeproj` is generated and gitignored.
- `ios/RoundsCompanion/`: SwiftUI sources, asset catalog, and
  `GoogleService-Info.plist.example`. For a local Mac build, put the real
  plist next to the example, then `cd ios && xcodegen generate`.
- `tools/make_icon.py`: draws the app icon (Pillow).

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

Facts from those pages: product `FirebaseAILogic`, Swift Package Manager
only; on-device supports text generation and streaming from text input;
structured output on-device is supported but its detailed docs were marked
"coming soon". The pages are marked Experimental.

### SDK version: why 12.19.3 (verified in source, 2026-11-23)

- The hybrid docs describe an API that **13.0.0 removed**. The SDK's
  `FirebaseAI/CHANGELOG.md` for 13.0.0 says: "Removed
  `GenerativeModelSession`, `SystemLanguageModel`, `HybridModel` ... use
  `GeminiLanguageModel` via `ai.geminiLanguageModel(name:)` directly with
  Apple's native Foundation Models framework." The latest release is 13.2.0.
- In 13.x the on-device path is Apple's own `LanguageModelSession`, with no
  Firebase involvement and no SDK report of which model answered, so the
  app would have to do its own routing. That breaks the rule that the badge
  comes from the SDK's report.
- So `ios/project.yml` pins **12.19.3**, the last 12.x release. Do not bump it
  to 13.x without rewriting the routing and revisiting that rule.

API in 12.19.3 (read from `FirebaseAI/Sources`):

- `FirebaseAI.firebaseAI(backend: .googleAI())`
- `ai.geminiModel(name:)` → `GeminiModel`; `FirebaseAI.SystemLanguageModel.default`
- `HybridModel(primary:secondary:)`; prefer on-device = system model primary.
  This is the form the SDK's integration test uses.
  (`.hybridModel(primary:secondary:)` provider form also exists.)
- `ai.generativeModelSession(model:)` → `session.respond(to:)` →
  `Response<String>` with `.content` and `.rawResponse.modelVersion`.
- `modelVersion` is `"apple-foundation-models-system-language-model"` when on-device
  answered (that is the system model's `_modelName`), the Gemini version
  string when the cloud answered, `"unknown-model-version"` if absent.
- `SystemLanguageModel.default.availability`: `.available` or
  `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady | .unknown)`.
- Availability annotations are iOS 26+, so the deployment target is iOS 26.0;
  hybrid code compiles only with Swift ≥ 6.2.3 (any Xcode 27).
- App Check: `AppCheckDebugProviderFactory()` in Debug,
  `AppAttestProviderFactory()` in Release; entitlement
  `com.apple.developer.devicecheck.appattest-environment` = `production`
  (App Check rejects sandbox tokens).
- Cloud model: `gemini-3.5-flash-lite` (models page: stable, billing not required).
