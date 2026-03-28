import SwiftUI

struct DisconnectedRowingDashboardSections: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    var body: some View {
        Group {
            connectionSection
            devicesSection
        }
    }

    private var connectionSection: some View {
        PanelCard(title: "Get Connected", subtitle: "Wake the PM5, then use one clear action to bring the monitor online.") {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Bluetooth", value: bluetoothManager.bluetoothStateDescription)
                LabeledContent("Monitor status", value: bluetoothManager.connectionPhase.title)

                Button {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScan()
                    } else {
                        bluetoothManager.startScan()
                    }
                } label: {
                    Label(
                        bluetoothManager.isScanning ? "Stop Scanning" : "Scan for PM5",
                        systemImage: bluetoothManager.isScanning ? "stop.circle.fill" : "dot.radiowaves.left.and.right"
                    )
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var devicesSection: some View {
        PanelCard(title: "Nearby PM5 Monitors", subtitle: devicesSubtitle) {
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

    private var devicesSubtitle: String {
        if bluetoothManager.isScanning {
            return "Scanning is active. Nearby PM5 matches appear here as soon as they advertise."
        }

        return "Only peripherals matching the current PM5 heuristics are shown."
    }

    private var emptyStateTitle: String {
        bluetoothManager.isScanning ? "Scanning for PM5" : "No PM5 Found"
    }

    private var emptyStateIcon: String {
        bluetoothManager.isScanning ? "rays" : "dot.radiowaves.left.and.right"
    }

    private var emptyStateDescription: String {
        if bluetoothManager.isScanning {
            return "Keep the monitor awake and nearby. Results will appear automatically while the scan is running."
        }

        return "Start a scan when the monitor is awake. Nearby matches will appear here as soon as the advertisement is detected."
    }
}
