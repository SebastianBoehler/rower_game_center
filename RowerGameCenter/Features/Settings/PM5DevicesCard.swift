import SwiftUI

struct PM5DevicesCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    var body: some View {
        PanelCard(title: "Nearby PM5 Monitors", subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 16) {
                if bluetoothManager.devices.isEmpty {
                    ContentUnavailableView {
                        Label(emptyStateTitle, systemImage: emptyStateIcon)
                    } description: {
                        Text(emptyStateDescription)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(bluetoothManager.devices.enumerated()), id: \.element.id) { index, device in
                        PM5DeviceRow(
                            device: device,
                            isConnecting: bluetoothManager.connectionPhase == .connecting,
                            isCurrentDevice: bluetoothManager.connectedDeviceID == device.id,
                            connectAction: {
                                bluetoothManager.connect(to: device.id)
                            }
                        )

                        if index < bluetoothManager.devices.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
            }
        }
    }

    private var subtitle: String {
        if bluetoothManager.isScanning {
            return "Scanning is active. Nearby PM5 matches appear here automatically."
        }

        return "Wake the monitor and run a scan to populate the list."
    }

    private var emptyStateTitle: String {
        bluetoothManager.isScanning ? "Scanning for PM5" : "No PM5 Found"
    }

    private var emptyStateIcon: String {
        bluetoothManager.isScanning ? "rays" : "dot.radiowaves.left.and.right"
    }

    private var emptyStateDescription: String {
        if bluetoothManager.isScanning {
            return "Keep the monitor awake and nearby. Results appear as soon as the advertisement is detected."
        }

        return "Start a scan when the monitor is awake. Nearby matches will show up here."
    }
}
