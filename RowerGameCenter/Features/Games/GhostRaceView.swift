import SwiftUI

struct GhostRaceView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(HealthSyncManager.self) private var healthSyncManager
    @Environment(SessionRecapManager.self) private var sessionRecapManager

    @State private var selectedDistance: StandardRaceDistance = .sprint500
    @State private var attemptBaseline = SessionBaseline()
    @State private var hasPresentedRecap = false

    private var selectedBenchmark: TrainingBenchmark? {
        healthSyncManager.ghostBenchmarks.first { $0.distance == selectedDistance }
    }

    private var attemptDistance: Double {
        attemptBaseline.distanceDelta(for: bluetoothManager.metrics) ?? 0
    }

    private var attemptElapsed: TimeInterval? {
        attemptBaseline.elapsedDelta(for: bluetoothManager.metrics)
    }

    private var playerProgress: Double {
        min(max(attemptDistance / selectedDistance.meters, 0), 1)
    }

    private var ghostProgress: Double {
        guard let bestTime = selectedBenchmark?.bestTime, bestTime > 0 else { return 0 }
        let elapsed = attemptElapsed ?? 0
        return min(max(elapsed / bestTime, 0), 1)
    }

    private var gapMeters: Double {
        guard let bestTime = selectedBenchmark?.bestTime, bestTime > 0 else { return 0 }
        let elapsed = attemptElapsed ?? 0
        let ghostDistance = min(selectedDistance.meters, selectedDistance.meters * elapsed / bestTime)
        return attemptDistance - ghostDistance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                raceCard
                summaryCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, bluetoothManager.metrics.connected ? 110 : 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Ghost Race")
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
        .onChange(of: selectedDistance) { _, _ in
            resetAttempt()
        }
        .safeAreaInset(edge: .bottom) {
            if bluetoothManager.metrics.connected, selectedBenchmark?.bestTime != nil {
                sessionHUD
            }
        }
    }

    private var headerCard: some View {
        PanelCard(
            title: "Personal Ghosts",
            subtitle: "Race your own synced benchmark over standard Concept2 distances."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Distance", selection: $selectedDistance) {
                    ForEach(StandardRaceDistance.allCases) { distance in
                        Text(distance.title).tag(distance)
                    }
                }
                .pickerStyle(.segmented)

                Button("Restart Attempt", action: resetAttempt)
                    .buttonStyle(.bordered)

                benchmarkStatus
            }
        }
    }

    @ViewBuilder
    private var benchmarkStatus: some View {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            Text("Apple Health is unavailable on this device, so Ghost Race cannot generate personal targets here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .notDetermined, .denied:
            Text("Enable Apple Health first so the app can build your benchmark ghost from synced rows.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .authorized:
            if let benchmark = selectedBenchmark, let bestTime = benchmark.bestTime {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(AppFormatters.duration(bestTime))
                            .font(.title3.weight(.bold))
                            .monospacedDigit()

                        Spacer(minLength: 12)

                        Text(AppFormatters.pace(benchmark.pace))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(benchmark.sourceSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No ghost exists for this distance yet. Finish a synced workout first, then come back here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var raceCard: some View {
        PanelCard(title: selectedDistance.title, subtitle: "Your live boat tracks PM5 distance while the ghost follows your benchmark clock.") {
            VStack(alignment: .leading, spacing: 16) {
                GhostRaceTrackView(
                    playerProgress: playerProgress,
                    ghostProgress: ghostProgress,
                    distanceTitle: selectedDistance.title
                )
                .frame(height: 210)

                if !bluetoothManager.metrics.connected {
                    Button(bluetoothManager.isScanning ? "Stop Scan" : "Scan for PM5") {
                        if bluetoothManager.isScanning {
                            bluetoothManager.stopScan()
                        } else {
                            bluetoothManager.startScan()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var summaryCard: some View {
        PanelCard(title: "Segment Readout", subtitle: "Stay ahead of the ghost clock or close the gap stroke by stroke.") {
            VStack(spacing: 12) {
                HStack {
                    MetricTile(title: "Gap", value: AppFormatters.gapMeters(gapMeters))
                    MetricTile(title: "Distance", value: AppFormatters.distance(attemptDistance))
                }

                HStack {
                    MetricTile(title: "Pace", value: AppFormatters.pace(attemptPace))
                    MetricTile(title: "Ghost", value: AppFormatters.duration(selectedBenchmark?.bestTime))
                }
            }
        }
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            hudMetric(title: "Elapsed", value: AppFormatters.duration(attemptElapsed))
            Divider()
                .frame(height: 34)
            hudMetric(title: "Gap", value: AppFormatters.gapMeters(gapMeters))
            Divider()
                .frame(height: 34)
            hudMetric(title: "Pace", value: AppFormatters.pace(attemptPace))
            Divider()
                .frame(height: 34)
            hudMetric(title: "Rate", value: AppFormatters.strokeRate(bluetoothManager.metrics.strokeRate))
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

    private func hudMetric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
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

    private var attemptPace: TimeInterval? {
        guard let attemptElapsed, attemptDistance > 0 else { return nil }
        return attemptElapsed / attemptDistance * 500
    }

    private func captureBaselineIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        attemptBaseline.captureIfNeeded(from: bluetoothManager.metrics)
    }

    private func presentRecapIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        guard selectedBenchmark?.bestTime != nil else { return }
        guard (playerProgress >= 1 || ghostProgress >= 1), !hasPresentedRecap else { return }

        hasPresentedRecap = true
        sessionRecapManager.present(
            SessionRecapBuilder.ghostRace(
                distance: selectedDistance,
                elapsedTime: attemptElapsed,
                gapMeters: gapMeters,
                didBeatGhost: gapMeters >= 0,
                benchmark: selectedBenchmark
            )
        )
    }

    private func resetAttempt() {
        attemptBaseline.reset()
        hasPresentedRecap = false
        captureBaselineIfNeeded()
    }
}
