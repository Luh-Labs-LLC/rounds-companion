# Rounds Companion

An offline-first golf round companion for iPhone. Log shots in plain shorthand
("7i 162y pushed right, greenside bunker") and an on-device model turns them
into structured shot records, even with no signal on the course. Back online,
a cloud model writes the post-round debrief.

Built for #BuildHybridAI 2026 with the Firebase AI Logic hybrid inference SDK:
on-device first through Apple Foundation Models, cloud fallback through Gemini.

> Status: early build. A probe app makes one hybrid call and shows which
> model answered. See [docs/PLAN.md](docs/PLAN.md).

## Platforms

- **iOS** (primary): SwiftUI, Apple Foundation Models on-device via Firebase AI Logic.
- **Web** (stretch): desktop Chrome round review, Gemini Nano on-device via Firebase AI Logic.

## Setup

Firebase config files (`GoogleService-Info.plist`, `.env`) and App Check
debug tokens are never committed. Copy the `.example` files and follow
[docs/SETUP.md](docs/SETUP.md).

On a Mac with Xcode 27: put your `GoogleService-Info.plist` in
`ios/RoundsCompanion/`, run `brew install xcodegen`, then
`cd ios && xcodegen generate` and open `RoundsCompanion.xcodeproj`.

## Third-party code and tools

Everything in this repo was written fresh for it. It depends on:

- [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) 12.19.3
  (Apache 2.0): Firebase AI Logic, App Check, Core. Pulled by Swift Package Manager.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (MIT): build tool that
  generates the Xcode project from `ios/project.yml`. Not shipped in the app.
- [xcbeautify](https://github.com/cpisciotta/xcbeautify) (MIT): formats CI build
  logs; preinstalled on the GitHub runner. Not shipped in the app.

The app icon is original, drawn by `tools/make_icon.py`.

## License

Copyright 2026 Luh Labs LLC. Licensed under Apache 2.0; see [LICENSE](LICENSE).
