@preconcurrency import CoreBluetooth

enum PM5UUIDs {
    static let deviceService = "CE060000-43E5-11E4-916C-0800200C9A66"
    static let controlService = "CE060020-43E5-11E4-916C-0800200C9A66"
    static let rowingService = "CE060030-43E5-11E4-916C-0800200C9A66"
    static let transmitToPM = "CE060021-43E5-11E4-916C-0800200C9A66"
    static let receiveFromPM = "CE060022-43E5-11E4-916C-0800200C9A66"
    static let rowingStatus = "CE060031-43E5-11E4-916C-0800200C9A66"
    static let extraStatus1 = "CE060032-43E5-11E4-916C-0800200C9A66"
    static let extraStatus2 = "CE060033-43E5-11E4-916C-0800200C9A66"
    static let rowingStrokeData = "CE060035-43E5-11E4-916C-0800200C9A66"
    static let extraStrokeData = "CE060036-43E5-11E4-916C-0800200C9A66"
    static let forceCurveData = "CE06003D-43E5-11E4-916C-0800200C9A66"

    static func uuid(_ value: String) -> CBUUID {
        CBUUID(string: value)
    }
}

struct PM5NotificationDefinition {
    let serviceUUID: String
    let characteristicUUID: String
    let label: String
}

enum PM5Protocol {
    static let nameHints = ["concept2", "pm5", "rowerg", "erg"]

    static let notificationDefinitions = [
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.controlService,
            characteristicUUID: PM5UUIDs.receiveFromPM,
            label: "Receive from PM"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.rowingStatus,
            label: "Rowing Status"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.extraStatus1,
            label: "Additional Status 1"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.extraStatus2,
            label: "Additional Status 2"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.rowingStrokeData,
            label: "Rowing Stroke Data"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.extraStrokeData,
            label: "Extra Stroke Data"
        ),
        PM5NotificationDefinition(
            serviceUUID: PM5UUIDs.rowingService,
            characteristicUUID: PM5UUIDs.forceCurveData,
            label: "Force Curve Data"
        ),
    ]
}
