# PM5 Hardware Validation

This project is intentionally strict about real-device behavior.

## Current State

The app uses native CoreBluetooth and only consumes live BLE notifications, but the PM5 UUID map and some payload assumptions are still provisional.

That means contributors should treat the current PM5 implementation as:

- real transport
- real subscription flow
- partially validated protocol map

## Validation Checklist

Before claiming PM5 support is production-ready, verify on real hardware:

1. Scan results consistently expose the expected PM5 identity hints.
2. Service discovery returns the expected Concept2 services.
3. Characteristic discovery confirms the currently configured notification UUIDs.
4. Notification payloads match the parser assumptions for:
   - elapsed time
   - distance
   - stroke rate
   - pace
   - power
   - calories
   - heart rate
5. Disconnect and reconnect flows behave correctly.
6. Error states are visible and do not fall back to simulated data.

## When Updating the BLE Map

If you confirm or change a UUID or payload offset:

- update `PM5Protocol.swift`
- update `PM5Parsers.swift`
- document the evidence in the PR
- note the tested PM5 firmware if known
