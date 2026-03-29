import SwiftUI

struct GamesConnectionStatusCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(AppNavigationModel.self) private var navigationModel

    var body: some View {
        PanelCard(
            title: "Live Game Center",
            subtitle: "Competitive and skill modes all read from the same PM5 feed."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StatusBadge(
                        title: bluetoothManager.metrics.connected ? "PM5 Live" : "PM5 Offline",
                        systemImage: bluetoothManager.metrics.connected ? "figure.rower" : "bolt.horizontal.circle",
                        tint: bluetoothManager.metrics.connected ? AppTheme.success : AppTheme.tint
                    )

                    Spacer()

                    Text(bluetoothManager.metrics.deviceName ?? "No monitor connected")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(bluetoothManager.metrics.connected
                    ? "Live metrics are already flowing. Ghost Race, cadence scoring, and technique views can react immediately."
                    : "Connect the PM5 in Settings to unlock live racing, structured workouts, and technique feedback."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !bluetoothManager.metrics.connected {
                    Button("Open Connection Settings") {
                        navigationModel.openSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }
}
