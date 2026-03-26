# Contributing

Thanks for contributing to `rower_game_center`.

## Ground Rules

- Keep the app native on iOS unless there is a strong technical reason not to.
- Use real Bluetooth integration paths only.
- Do not add mock rowing telemetry unless a maintainer explicitly asks for it.
- Do not add fake BLE devices, fake providers, or silent fallbacks.
- Keep files modular. Files over roughly 300 lines are a smell and should usually be split.
- Prefer small, focused commits with conventional commit messages.

## Development Setup

1. Install Xcode 26.4 or newer.
2. Install XcodeGen: `brew install xcodegen`
3. Generate the project: `xcodegen generate`
4. Build locally:

```bash
xcodebuild \
  -project RowerGameCenter.xcodeproj \
  -scheme RowerGameCenter \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Pull Requests

Please keep pull requests narrow and explain:

- what changed
- why it changed
- whether it was validated on real PM5 hardware
- any remaining risks or unknowns

If you change PM5 BLE behavior, include:

- the device/firmware you tested
- the observed service and characteristic UUIDs
- a short note about packet samples or payload interpretation

## Code Style

- SwiftUI-first UI
- modern Swift concurrency where it actually improves clarity
- small view files and small support types
- clear naming over clever naming
- no dead scaffolding

## Documentation

Update documentation when you change:

- public setup steps
- project structure
- BLE assumptions
- contribution workflow

## Before Opening a PR

- run `xcodegen generate`
- ensure the project builds
- update docs if behavior changed
- avoid unrelated formatting churn
