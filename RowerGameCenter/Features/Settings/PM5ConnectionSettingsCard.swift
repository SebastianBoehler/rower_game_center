import SwiftUI

struct PM5ConnectionSettingsCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    var body: some View {
        PanelCard(title: "PM5 Connection", subtitle: "Manage the live Bluetooth session and monitor state.") {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Bluetooth", value: bluetoothManager.bluetoothStateDescription)
                LabeledContent("Status", value: bluetoothManager.connectionPhase.title)
                LabeledContent("Device", value: bluetoothManager.metrics.deviceName ?? "No PM5 connected")

                if bluetoothManager.metrics.connected {
                    Button("Disconnect", role: .destructive) {
                        bluetoothManager.disconnect()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(bluetoothManager.isScanning ? "Stop Scanning" : "Scan for PM5") {
                        if bluetoothManager.isScanning {
                            bluetoothManager.stopScan()
                        } else {
                            bluetoothManager.startScan()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }
}
