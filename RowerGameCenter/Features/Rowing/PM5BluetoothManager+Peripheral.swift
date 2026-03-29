@preconcurrency import CoreBluetooth

extension PM5BluetoothManager: @MainActor CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            setError("Service discovery failed: \(error.localizedDescription)")
            return
        }

        replaceDiscoveredServices(from: peripheral)
        logInfo(
            "Discovered \(peripheral.services?.count ?? 0) services on \(peripheral.name ?? "PM5").",
            category: "discovery"
        )

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
        logInfo(
            "Discovered \(service.characteristics?.count ?? 0) characteristics for service \(service.uuid.uuidString.lowercased()).",
            category: "discovery"
        )

        let matchingDefinitions = PM5Protocol.notificationDefinitions.filter {
            $0.serviceUUID == service.uuid.uuidString.uppercased()
        }

        for characteristic in service.characteristics ?? [] {
            registerDiscoveredCharacteristic(characteristic)

            guard matchingDefinitions.contains(where: { $0.characteristicUUID == characteristic.uuid.uuidString.uppercased() }) else {
                continue
            }

            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
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

        handleNotification(from: characteristic)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            setError("Failed to subscribe to \(characteristic.uuid.uuidString): \(error.localizedDescription)")
        } else if characteristic.isNotifying {
            logInfo(
                "Subscribed to \(characteristic.uuid.uuidString.lowercased()).",
                category: "subscription"
            )
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        guard characteristic.uuid.uuidString.uppercased() == PM5UUIDs.transmitToPM else {
            return
        }

        if let error {
            controlForceCurveRequestInFlight = false
            setError("Failed to request PM5 force curve data: \(error.localizedDescription)")
        } else {
            logInfo("Sent PM control request for force-curve data.", category: "forceCurve")
        }
    }
}
