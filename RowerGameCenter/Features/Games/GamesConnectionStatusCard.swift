import SwiftUI

struct GamesConnectionStatusCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(HealthSyncManager.self) private var healthSyncManager

    @State private var showConnectSheet = false

    var body: some View {
        if bluetoothManager.metrics.connected {
            connectedBadge
        } else {
            offlineCard
        }
    }

    // Minimal status strip — no card chrome when already live
    private var connectedBadge: some View {
        HStack {
            StatusBadge(
                title: "PM5 Live",
                systemImage: "figure.rower",
                tint: AppTheme.success
            )

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                Text(bluetoothManager.metrics.deviceName ?? "Connected")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if healthSyncManager.canFinishWorkout {
                    Button("Finish Workout") {
                        bluetoothManager.finishHealthWorkoutIfNeeded()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // Full card only when offline — CTA opens inline sheet, no tab switch
    private var offlineCard: some View {
        PanelCard(
            title: "Live Game Center",
            subtitle: "Connect the PM5 to unlock live racing, structured workouts, and technique feedback."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StatusBadge(
                        title: "PM5 Offline",
                        systemImage: "bolt.horizontal.circle",
                        tint: AppTheme.tint
                    )

                    Spacer(minLength: 12)

                    Text("No monitor connected")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

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
