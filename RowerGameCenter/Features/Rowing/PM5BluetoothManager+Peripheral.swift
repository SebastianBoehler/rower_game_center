@preconcurrency import CoreBluetooth

extension PM5BluetoothManager: @MainActor CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            setError("Service discovery failed: \(error.localizedDescription)")
            return
        }

        replaceDiscoveredServices(from: peripheral)

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        if let error {
            setError("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        replaceDiscoveredServices(from: peripheral)

        let matchingDefinitions = PM5Protocol.notificationDefinitions.filter {
            $0.serviceUUID == service.uuid.uuidString.uppercased()
        }

        for characteristic in service.characteristics ?? [] {
            guard matchingDefinitions.contains(where: { $0.characteristicUUID == characteristic.uuid.uuidString.uppercased() }) else {
                continue
            }

            peripheral.setNotifyValue(true, for: characteristic)
        }

        validateNotificationCoverage(for: peripheral)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            setError("PM5 notification error: \(error.localizedDescription)")
            return
        }

        updateMetrics(using: characteristic)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            setError("Failed to subscribe to \(characteristic.uuid.uuidString): \(error.localizedDescription)")
        }
    }
}
