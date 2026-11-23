# Rounds Companion: agent contract

Read [docs/PLAN.md](docs/PLAN.md) before your first edit. It holds the
deadline, the routing table and the schedule. Then
[docs/SETUP.md](docs/SETUP.md): owner setup, the build path, the secrets
contract and the reference docs.

## Start here (state as of 2026-11-23)

- **Nothing is built yet.** The repo holds the licence, `.gitignore`, README
  and docs. No Xcode project, no workflow.
- **Owner setup is unconfirmed.** Ask the owner which rows of the
  `docs/SETUP.md` table are done before depending on them.
- **First task (Tue Nov 24):** the smallest SwiftUI app that initialises
  Firebase and App Check (debug provider in debug builds) and makes **one**
  Firebase AI Logic call that prefers on-device. Show the text result plus
  the SDK's report of which model answered and the latency. Add the GitHub
  Actions workflow that builds it with Xcode 27 and uploads to TestFlight.
- **Kill check (end of Wed Nov 25):** if that call has not run on-device on
  the owner's iPhone, stop and tell the owner. The plan has no fallback that
  keeps the on-course story honest.

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
   changed recently (`FirebaseAILogic`, SPM-only hybrid, Xcode 27 / iOS 27).
4. **No invented precision.** Stats are computed in code; the model only
   describes them. No strokes-gained figures. Club suggestions are plain math.
5. **The routing must be visible.** Every AI result shows whether it ran
   on-device or in the cloud, from the SDK's own report, never a guess.
6. **No personal data** in code, fixtures, screenshots or docs.
7. **Do not commit after Mon Nov 30, 2:00 PM PT** unless the owner says so.
