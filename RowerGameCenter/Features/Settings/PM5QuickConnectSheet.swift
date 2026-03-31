import SwiftUI

/// Inline bottom-sheet for connecting a PM5 without leaving the current screen.
/// Replace any "Open Connection Settings" tab-nav with `.sheet(isPresented:) { PM5QuickConnectSheet() }`.
struct PM5QuickConnectSheet: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    connectionCard
                    PM5DevicesCard()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Connect PM5")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: bluetoothManager.metrics.connected) { _, connected in
            if connected { dismiss() }
        }
    }

    private var connectionCard: some View {
        PanelCard(
            title: "PM5 Monitor",
            subtitle: "Wake your monitor and tap Scan. The sheet closes automatically once connected."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusBadge(
                        title: bluetoothManager.connectionPhase.title,
                        systemImage: bluetoothManager.metrics.connected ? "figure.rower" : "bolt.horizontal.circle",
                        tint: bluetoothManager.metrics.connected ? AppTheme.success : AppTheme.tint
                    )

                    Spacer(minLength: 12)

                    if let name = bluetoothManager.metrics.deviceName {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

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
