@preconcurrency import CoreBluetooth

extension PM5BluetoothManager: @MainActor CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothStateDescription = central.state.label

        if central.state == .poweredOn {
            if let errorMessage, isBluetoothStateError(errorMessage) {
                clearError()

                if connectedDeviceID == nil, !isScanning {
                    connectionPhase = .idle
                }
            }

            return
        }

        stopScan()

        if let message = bluetoothStateErrorMessage(for: central.state) {
            setError(message)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard PM5Discovery.matches(peripheral: peripheral, advertisementData: advertisementData) else {
            return
        }

        register(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        handleConnectedPeripheral(peripheral)
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        clearConnectionState()
        setError("Failed to connect to PM5: \(error?.localizedDescription ?? "Unknown error")")
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        handleDisconnection(for: peripheral, error: error)
    }
}
