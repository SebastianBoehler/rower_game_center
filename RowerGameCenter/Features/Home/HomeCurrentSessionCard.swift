import SwiftUI

struct HomeCurrentSessionCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    @State private var showConnectSheet = false

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        PanelCard(title: "Current Session", subtitle: subtitle) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    StatusBadge(
                        title: bluetoothManager.connectionPhase.title,
                        systemImage: bluetoothManager.connectionPhase.systemImage,
                        tint: badgeTint
                    )

                    Spacer(minLength: 12)

                    Text(AppFormatters.relativeTimestamp(bluetoothManager.metrics.lastUpdatedAt))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if bluetoothManager.metrics.connected {
                    LabeledContent("Connected device", value: bluetoothManager.metrics.deviceName ?? "PM5")
                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        MetricTile(title: "Elapsed", value: AppFormatters.duration(bluetoothManager.metrics.elapsedTime))
                        MetricTile(title: "Distance", value: AppFormatters.distance(bluetoothManager.metrics.distance))
                        MetricTile(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
                        MetricTile(title: "Calories", value: AppFormatters.calories(bluetoothManager.metrics.calories))
                    }
                } else {
                    Text("The PM5 is not connected yet. Scan now to unlock the live dashboard and game input.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Connect PM5") {
                        showConnectSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .sheet(isPresented: $showConnectSheet) {
                        PM5QuickConnectSheet()
                    }
                }
            }
        }
    }

    private var subtitle: String {
        bluetoothManager.metrics.connected
            ? "Live PM5 metrics are front and center."
            : "Home now focuses on today’s rowing state and shortcuts."
    }

    private var badgeTint: Color {
        switch bluetoothManager.connectionPhase {
        case .connected:
            AppTheme.success
        case .error:
            AppTheme.warning
        case .scanning, .connecting:
            AppTheme.tint
        case .idle, .disconnecting:
            .secondary
        }
    }
}
