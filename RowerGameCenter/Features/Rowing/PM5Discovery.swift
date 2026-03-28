@preconcurrency import CoreBluetooth
import Foundation

enum PM5Discovery {
    static func matches(
        peripheral: CBPeripheral,
        advertisementData: [String: Any]
    ) -> Bool {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let joinedNames = [peripheral.name, localName]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        let nameMatch = PM5Protocol.nameHints.contains { joinedNames.contains($0) }
        let serviceMatch = serviceUUIDs.contains(PM5UUIDs.uuid(PM5UUIDs.deviceService))

        return nameMatch || serviceMatch
    }

    static func summary(
        for peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber
    ) -> PM5DeviceSummary {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []

        return PM5DeviceSummary(
            id: peripheral.identifier,
            name: peripheral.name ?? localName ?? "Unnamed PM5",
            localName: localName,
            rssi: rssi.intValue,
            serviceUUIDs: serviceUUIDs.map(\.uuidString)
        )
    }

    static func availableNotificationDefinitions(
        in services: [PM5DiscoveredServiceSnapshot]
    ) -> [PM5NotificationDefinition] {
        let serviceMap = Dictionary(uniqueKeysWithValues: services.map { ($0.uuid, $0.characteristics) })

        return PM5Protocol.notificationDefinitions.filter { definition in
            serviceMap[definition.serviceUUID.lowercased()]?.contains(
                definition.characteristicUUID.lowercased()
            ) == true
        }
    }

    static func hasCharacteristic(
        serviceUUID: String,
        characteristicUUID: String,
        in services: [PM5DiscoveredServiceSnapshot]
    ) -> Bool {
        services.contains { service in
            service.uuid.caseInsensitiveCompare(serviceUUID) == .orderedSame
                && service.characteristics.contains {
                    $0.caseInsensitiveCompare(characteristicUUID) == .orderedSame
                }
        }
    }
}
