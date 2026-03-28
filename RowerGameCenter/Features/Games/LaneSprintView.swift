import SwiftUI

struct LaneSprintView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    private let goalDistance = 500.0

    var body: some View {
        Group {
            if bluetoothManager.metrics.connected {
                liveSession
            } else {
                unavailableState
            }
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Lane Sprint")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var liveSession: some View {
        VStack(spacing: 20) {
            sessionHeader

            LaneSprintTrackView(
                distance: bluetoothManager.metrics.distance,
                goalDistance: goalDistance
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .safeAreaInset(edge: .bottom) {
            sessionHUD
        }
    }

    private var unavailableState: some View {
        ContentUnavailableView {
            Label("Connect a PM5 to Play", systemImage: "figure.rower")
        } description: {
            Text("Lane Sprint only reacts to live PM5 distance. Start a scan here or connect from the main dashboard.")
        } actions: {
            Button(bluetoothManager.isScanning ? "Stop Scan" : "Scan for PM5") {
                if bluetoothManager.isScanning {
                    bluetoothManager.stopScan()
                } else {
                    bluetoothManager.startScan()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadge(title: "Live PM5", systemImage: "bolt.horizontal.fill", tint: AppTheme.success)

                Spacer()

                Text("500 m target")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text("Your boat advances only from live PM5 distance, keeping the playfield clear and glanceable while you row.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            sessionMetric(title: "Distance", value: AppFormatters.distance(bluetoothManager.metrics.distance))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Power", value: AppFormatters.watts(bluetoothManager.metrics.powerWatts))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.separator.opacity(0.12), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func sessionMetric(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
