# Rounds Companion

An offline-first golf round companion for iPhone. Log shots in plain shorthand
("7i 162y pushed right, greenside bunker") and an on-device model turns them
into structured shot records, even with no signal on the course. Back online,
a cloud model writes the post-round debrief.

Built for #BuildHybridAI 2026 with the Firebase AI Logic hybrid inference SDK:
on-device first through Apple Foundation Models, cloud fallback through Gemini.

> Status: planning. See [docs/PLAN.md](docs/PLAN.md).

## Platforms

- **iOS** (primary): SwiftUI, Apple Foundation Models on-device via Firebase AI Logic.
- **Web** (stretch): desktop Chrome round review, Gemini Nano on-device via Firebase AI Logic.

## Setup

_To be written as the app is built._ Firebase config files
(`GoogleService-Info.plist`, `.env`) and App Check debug tokens are never
committed; copy the `.example` files and follow the steps here.

## License

Apache 2.0. See [LICENSE](LICENSE).
