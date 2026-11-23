# Rounds Companion: agent contract

Read [docs/PLAN.md](docs/PLAN.md) before your first edit. It holds the
deadline, the routing table and the schedule.

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
