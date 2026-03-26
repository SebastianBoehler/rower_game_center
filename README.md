# Rower Game Center

Native iOS rowing game platform for the Concept2 RowErg PM5.

This repository is building a mobile-first game platform where real rowing data from a live PM5 BLE connection powers gameplay. The current app is written in SwiftUI and CoreBluetooth and intentionally avoids mock telemetry, fake providers, and Web Bluetooth.

## Status

This project is early, but the repository is already structured as a real native app:

- SwiftUI app shell
- CoreBluetooth PM5 scan/connect/subscribe flow
- live metrics parsing pipeline
- first game prototype: `Lane Sprint`

Important:

- iOS only for now
- Android is planned later
- PM5 UUIDs and packet offsets are still marked provisional and must be validated on hardware before production use

## Principles

- Real Bluetooth only
- No mock data
- No fake device layer
- No Web Bluetooth
- Keep files modular and small
- Prefer native platform APIs when hardware integration matters

## Repository Layout

```text
RowerGameCenter/
  App/
  Components/
  DesignSystem/
  Features/
    Games/
    Rowing/
  Resources/
  Support/
docs/
project.yml
```

## Requirements

- macOS
- Xcode 26.4 or newer
- `xcodegen`
- iPhone or iOS Simulator for builds
- a real Concept2 PM5 for BLE validation

Install XcodeGen with Homebrew if needed:

```bash
brew install xcodegen
```

## Getting Started

Generate the Xcode project:

```bash
xcodegen generate
```

Build for the simulator:

```bash
xcodebuild \
  -project RowerGameCenter.xcodeproj \
  -scheme RowerGameCenter \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Open in Xcode:

```bash
open RowerGameCenter.xcodeproj
```

## PM5 Integration Notes

The PM5 transport lives in:

- `RowerGameCenter/Features/Rowing/PM5BluetoothManager.swift`
- `RowerGameCenter/Features/Rowing/PM5Protocol.swift`
- `RowerGameCenter/Features/Rowing/PM5Parsers.swift`

Current behavior:

1. Scan for likely PM5 peripherals
2. Connect via CoreBluetooth
3. Discover services and characteristics
4. Subscribe to known metric notification characteristics
5. Parse incoming packets into rowing metrics
6. Feed the game UI from live data

Current limitation:

- The UUID map and packet offsets are seeded from public PM5 BLE references but still need confirmation against a real PM5 session and official Concept2 documentation

See [docs/native-architecture.md](./docs/native-architecture.md) and [docs/pm5-hardware-validation.md](./docs/pm5-hardware-validation.md).

## Contributing

Contributions are welcome, but please read [CONTRIBUTING.md](./CONTRIBUTING.md) first.

For hardware work:

- do not introduce mock telemetry
- do not add fake BLE providers
- do not silently fall back to simulated game input

## Security

Please report security issues privately. See [SECURITY.md](./SECURITY.md).

## License

This project is released under the [MIT License](./LICENSE).
