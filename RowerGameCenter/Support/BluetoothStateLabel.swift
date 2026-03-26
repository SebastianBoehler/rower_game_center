import CoreBluetooth

extension CBManagerState {
    var label: String {
        switch self {
        case .unknown:
            "Unknown"
        case .resetting:
            "Resetting"
        case .unsupported:
            "Unsupported"
        case .unauthorized:
            "Unauthorized"
        case .poweredOff:
            "Powered Off"
        case .poweredOn:
            "Powered On"
        @unknown default:
            "Unknown"
        }
    }
}
