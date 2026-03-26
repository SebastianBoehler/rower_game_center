# Native iOS rewrite

This repository was pivoted from an Expo proof-of-concept to a native SwiftUI/CoreBluetooth app because the PM5 BLE path is better served by first-party iOS APIs.

## Stack

- SwiftUI for the app shell and game UI
- CoreBluetooth for PM5 discovery, connection, service discovery, and notifications
- Observation (`@Observable`) for shared app state
- XcodeGen for reproducible project generation

## BLE constraints

- Real Bluetooth only
- No Web Bluetooth
- No mock metrics or fake providers
- PM5 UUIDs and packet offsets are isolated in `PM5Protocol.swift` and `PM5Parsers.swift`

## Remaining validation before shipping

1. Confirm the provisional PM5 UUID map against the official Concept2 Bluetooth Smart interface definition.
2. Inspect a real PM5 GATT session and verify each notification payload on hardware.
3. Expand the game catalog once the live telemetry feed is confirmed across multiple workout modes.
