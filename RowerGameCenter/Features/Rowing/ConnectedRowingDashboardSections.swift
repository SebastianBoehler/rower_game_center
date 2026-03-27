import SwiftUI

struct ConnectedRowingDashboardSections: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            sessionSection
            PowerBar(watts: bluetoothManager.metrics.powerWatts)
            metricsSection
            gamesSection
        }
    }

    private var sessionSection: some View {
        PanelCard(title: "Current Session", subtitle: "The PM5 is connected and actively driving the dashboard.") {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Connected device", value: bluetoothManager.metrics.deviceName ?? "PM5")
                LabeledContent("Monitor status", value: bluetoothManager.connectionPhase.title)
                LabeledContent("Bluetooth", value: bluetoothManager.bluetoothStateDescription)

                Button("Disconnect", role: .destructive) {
                    bluetoothManager.disconnect()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
        }
    }

    private var metricsSection: some View {
        PanelCard(title: "Live Metrics", subtitle: "These values update directly from PM5 notifications while you row.") {
            LazyVGrid(columns: metricColumns, spacing: 12) {
                MetricTile(title: "Elapsed", value: AppFormatters.duration(bluetoothManager.metrics.elapsedTime))
                MetricTile(title: "Distance", value: AppFormatters.distance(bluetoothManager.metrics.distance))
                MetricTile(title: "Stroke Rate", value: AppFormatters.strokeRate(bluetoothManager.metrics.strokeRate))
                MetricTile(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
                MetricTile(title: "Watts", value: AppFormatters.watts(bluetoothManager.metrics.powerWatts))
                MetricTile(title: "Heart Rate", value: AppFormatters.heartRate(bluetoothManager.metrics.heartRate))
                MetricTile(title: "Calories", value: AppFormatters.calories(bluetoothManager.metrics.calories))
                MetricTile(title: "Feed", value: "Live")
            }
        }
    }

    private var gamesSection: some View {
        PanelCard(title: "Games", subtitle: "Start a workout view only when the PM5 feed is live.") {
            VStack(spacing: 12) {
                gameCard(
                    title: "Lane Sprint",
                    subtitle: "A clean 500 m race view driven by live PM5 distance.",
                    systemImage: "flag.checkered.circle.fill"
                ) {
                    LaneSprintView()
                }

                gameCard(
                    title: "Cadence Lock",
                    subtitle: "Match the shifting stroke-rate target and build a streak.",
                    systemImage: "metronome.fill"
                ) {
                    CadenceLockView()
                }
            }
        }
    }

    private func gameCard<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(AppTheme.tint)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
