import SwiftUI

struct LaneSprintView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(SessionRecapManager.self) private var sessionRecapManager

    private let goalDistance = 500.0

    @State private var attemptBaseline = SessionBaseline()
    @State private var hasPresentedRecap = false

    private var attemptDistance: Double {
        attemptBaseline.distanceDelta(for: bluetoothManager.metrics) ?? 0
    }

    private var attemptElapsed: TimeInterval? {
        attemptBaseline.elapsedDelta(for: bluetoothManager.metrics)
    }

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
        .onAppear(perform: captureBaselineIfNeeded)
        .onChange(of: bluetoothManager.metrics.connected) { _, isConnected in
            if isConnected {
                captureBaselineIfNeeded()
            } else {
                resetAttempt()
            }
        }
        .onChange(of: bluetoothManager.metrics.distance) { _, _ in
            captureBaselineIfNeeded()
            presentRecapIfNeeded()
        }
    }

    private var liveSession: some View {
        VStack(spacing: 20) {
            sessionHeader

            LaneSprintTrackView(
                distance: attemptDistance,
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

                Button("Restart Attempt", action: resetAttempt)
                    .buttonStyle(.bordered)
            }

            Text("Your boat advances only from distance earned after this attempt started, so every 500 m run gets a clean finish and a shareable recap.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            sessionMetric(title: "Distance", value: AppFormatters.distance(attemptDistance))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Pace", value: AppFormatters.pace(pace))
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

    private var pace: TimeInterval? {
        guard let attemptElapsed, attemptDistance > 0 else { return nil }
        return attemptElapsed / attemptDistance * 500
    }

    private func captureBaselineIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        attemptBaseline.captureIfNeeded(from: bluetoothManager.metrics)
    }

    private func presentRecapIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        guard attemptDistance >= goalDistance, !hasPresentedRecap else { return }

        hasPresentedRecap = true
        sessionRecapManager.present(
            SessionRecapBuilder.laneSprint(
                metrics: bluetoothManager.metrics,
                elapsedTime: attemptElapsed,
                distanceMeters: attemptDistance
            )
        )
    }

    private func resetAttempt() {
        attemptBaseline.reset()
        hasPresentedRecap = false
        captureBaselineIfNeeded()
    }
}
