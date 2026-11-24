# Rounds Companion: agent contract

Read [docs/PLAN.md](docs/PLAN.md) before your first edit. It holds the
deadline, the routing table and the schedule. Then
[docs/SETUP.md](docs/SETUP.md): owner setup, the build path, the secrets
contract and the reference docs.

## Start here (state as of 2026-11-23)

- **Kill check passed (2026-11-23).** TestFlight build 0.1.0 (6) ran the
  hybrid call on the owner's iPhone: badge On-device, `modelVersion`
  `apple-foundation-models-system-language-model`, ~2.4 s, also in Airplane Mode.
- **Build path works end to end.** Every push to `main` runs
  `.github/workflows/ios.yml`: RoundsKit tests (`swift test`), an unsigned
  compile, then a manually signed archive uploaded to TestFlight (build
  number = run number). Signing uses this app's own Apple Distribution
  certificate and "Rounds Companion App Store" profile from secrets; the API
  key is App Manager and only uploads. Never switch to cloud signing (needs Admin).
- **Code layout.** `ios/RoundsKit` holds the tested pure logic (shot records,
  shorthand parser, merge of parser + model output, round stats, caddie
  facts). `ios/RoundsCompanion` holds the app (SwiftData rounds, hybrid calls
  in `AI/`, screens in `Rounds/`, the probe as Diagnostics).
- **Firebase SDK is pinned to 12.19.3 on purpose.** 13.0.0 removed the
  hybrid API (`HybridModel` and related types). See `docs/SETUP.md` before
  touching the version.
- **Scope is locked in `docs/PLAN.md`** (judging favours Firebase AI Logic
  hybrid use). Another agent session may be editing docs in this tree: stage
  files by path, never `git add -A`.

## Environment and conventions

- Agents run on **Windows** (PowerShell and Git Bash). Swift cannot be
  compiled locally; every iOS build goes through CI (see `docs/SETUP.md`).
- Owner: Luh Labs LLC owns this repo and its code. The owner's iPhone is
  the only test device with Apple Intelligence.
- Commit identity is set in this repo's local git config (the owner's GitHub
  no-reply address). Never change it, and never set git config `--global`.
- End every commit message with a `Co-Authored-By:` trailer naming the model
  that wrote it.
- Evidence before claims: say which command or build ran and what it
  printed. "It should work" is not a result; a green CI build is not proof
  the on-device path ran on the phone.

## Non-negotiables

1. **This repo is public and open source.** Never commit a secret:
   `GoogleService-Info.plist`, `.env*`, App Check debug tokens, `*.p8` signing
   keys. Check `git status` before every commit. Provide `.example` files.
2. **Original work only.** No code, schemas, assets or course data copied
   from any other project. Every file here is written fresh for this repo.
   Disclose any third-party library or template in the README.
3. **Verify SDK APIs against installed packages or current Firebase docs.**
   Do not write Firebase AI Logic calls from memory; names and signatures
   changed recently (`FirebaseAILogic`, SPM-only hybrid, Xcode 27 / iOS 27,
   hybrid removed in 13.0.0). The docs pages lag the SDK; the SDK source wins.
4. **No invented precision.** Stats are computed in code; the model only
   describes them. No strokes-gained figures. Club suggestions are plain math.
5. **The routing must be visible.** Every AI result shows whether it ran
   on-device or in the cloud, from the SDK's own report, never a guess.
6. **No personal data** in code, fixtures, screenshots or docs.
7. **Do not commit after Mon Nov 30, 2:00 PM PT** unless the owner says so.
