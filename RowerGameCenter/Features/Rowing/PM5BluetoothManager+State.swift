@preconcurrency import CoreBluetooth

extension PM5BluetoothManager {
    func clearError() {
        errorMessage = nil
    }

    var connectionSummary: String {
        if metrics.connected {
            return "Connected to \(metrics.deviceName ?? "PM5")"
        }

        if isScanning {
            return "Scanning for nearby Concept2 PM5 monitors"
        }

        return "No PM5 connected"
    }

    func bluetoothStateErrorMessage(for state: CBManagerState) -> String? {
        switch state {
        case .poweredOn:
            nil
        case .unknown:
            "Bluetooth is still initializing. Try scanning again in a moment."
        case .resetting:
            "Bluetooth is resetting. Try scanning again in a moment."
        case .unsupported:
            "This device does not support Bluetooth Low Energy scanning."
        case .unauthorized:
            "Bluetooth access is not allowed for this app. Allow Bluetooth in Settings > Privacy & Security > Bluetooth."
        case .poweredOff:
            "Bluetooth is turned off. Enable Bluetooth to use a real PM5 connection."
        @unknown default:
            "Bluetooth is unavailable right now."
        }
    }

    func isBluetoothStateError(_ message: String) -> Bool {
        [
            CBManagerState.unknown,
            .resetting,
            .unsupported,
            .unauthorized,
            .poweredOff,
        ]
        .compactMap(bluetoothStateErrorMessage(for:))
        .contains(message)
    }
}
