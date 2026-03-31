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
    private var attemptPace: TimeInterval? {
        guard let attemptElapsed, attemptDistance > 0 else { return nil }
        return attemptElapsed / attemptDistance * 500
    }
    var body: some View {
        GeometryReader(content: content)
        .navigationTitle("Ghost Race")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
    }

    private func content(_ geometry: GeometryProxy) -> some View {
        ZStack {
            backdrop
            mainLayout(bottomInset: max(12, geometry.safeAreaInsets.bottom + 6))
            overlayLayout(bottomInset: max(34, geometry.safeAreaInsets.bottom + 24))
        }
    }

    private func mainLayout(bottomInset: CGFloat) -> some View {
        VStack(spacing: 14) {
            GhostRaceControlStrip(
                selectedDistance: $selectedDistance,
                status: controlStatus,
                benchmark: selectedBenchmark,
                primaryActionTitle: primaryActionTitle,
                primaryActionTint: primaryActionTint,
                primaryAction: performPrimaryAction
            )

            GhostRaceTrackView(
                playerProgress: playerProgress,
                ghostProgress: ghostProgress,
                gapMeters: gapMeters,
                distanceTitle: selectedDistance.title,
                ghostReady: selectedBenchmark?.bestTime != nil,
                isConnected: bluetoothManager.metrics.connected
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GhostRaceMetricBar(
                elapsed: attemptElapsed,
                gapMeters: gapMeters,
                pace: attemptPace,
                strokeRate: bluetoothManager.metrics.strokeRate
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, bottomInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func overlayLayout(bottomInset: CGFloat) -> some View {
        if let overlayContent {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            GhostRaceSetupOverlay(
                content: overlayContent,
                primaryAction: overlayContent.actionTitle == nil ? nil : { performPrimaryAction() }
            )
            .padding(.horizontal, 28)
            .padding(.bottom, bottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.07, blue: 0.13),
                Color(red: 0.04, green: 0.14, blue: 0.19),
                Color(red: 0.03, green: 0.08, blue: 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.tint.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 52)
                .offset(x: 60, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(AppTheme.success.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 56)
                .offset(x: -40, y: 100)
        }
        .ignoresSafeArea()
    }

    private var controlStatus: GhostRaceStatusStyle {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            return GhostRaceStatusStyle(title: "Health unavailable", systemImage: "heart.slash.fill", tint: AppTheme.warning)
        case .notDetermined, .denied:
            return GhostRaceStatusStyle(title: "Enable Health", systemImage: "heart.text.square.fill", tint: AppTheme.warning)
        case .authorized where selectedBenchmark?.bestTime == nil:
            return GhostRaceStatusStyle(title: "No ghost yet", systemImage: "hare.fill", tint: AppTheme.tint)
        case .authorized where !bluetoothManager.metrics.connected:
            return GhostRaceStatusStyle(title: "Awaiting PM5", systemImage: "bolt.slash.fill", tint: Color.orange)
        case .authorized:
            return GhostRaceStatusStyle(title: "Race live", systemImage: "flag.checkered.2.crossed", tint: AppTheme.success)
        }
    }

    private var overlayContent: GhostRaceOverlayContent? {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            return GhostRaceOverlayContent(
                title: "Ghost Race Needs Apple Health",
                message: "Use this mode on an iPhone where Apple Health is available and your rowing history can sync.",
                systemImage: "iphone.slash",
                tint: AppTheme.warning,
                actionTitle: nil
            )
        case .notDetermined, .denied:
            return GhostRaceOverlayContent(
                title: "Enable Apple Health",
                message: "Ghost Race builds its rival boat from your synced rows. Turn Health access on to load a benchmark.",
                systemImage: "heart.text.square.fill",
                tint: AppTheme.warning,
                actionTitle: primaryActionTitle
            )
        case .authorized where selectedBenchmark?.bestTime == nil:
            return GhostRaceOverlayContent(
                title: "No Ghost For \(selectedDistance.title)",
                message: "Finish one synced row at this distance, then come back and race your own benchmark live.",
                systemImage: "hare.fill",
                tint: AppTheme.tint,
                actionTitle: primaryActionTitle
            )
        default:
            guard !bluetoothManager.metrics.connected else { return nil }

            return GhostRaceOverlayContent(
                title: "Connect A PM5",
                message: "Your shell only moves from live distance off the rower, so connect the PM5 before the start.",
                systemImage: "figure.rower",
                tint: AppTheme.success,
                actionTitle: primaryActionTitle
            )
        }
    }

    private var primaryActionTitle: String? {
        switch primaryActionKind {
        case .requestHealthAccess:
            "Enable Health"
        case .refreshGhost:
            "Refresh Ghost"
        case .startScan:
            "Scan for PM5"
        case .stopScan:
            "Stop Scan"
        case .restart:
            "Restart"
        case .none:
            nil
        }
    }

    private var primaryActionTint: Color {
        switch primaryActionKind {
        case .requestHealthAccess:
            AppTheme.warning
        case .refreshGhost:
            AppTheme.tint
        case .startScan, .stopScan:
            AppTheme.success
        case .restart:
            AppTheme.tint
        case .none:
            .clear
        }
    }

    private var primaryActionKind: GhostRacePrimaryAction {
        switch healthSyncManager.authorizationState {
        case .unavailable:
            .none
        case .notDetermined, .denied:
            .requestHealthAccess
        case .authorized where selectedBenchmark?.bestTime == nil:
            .refreshGhost
        case .authorized where !bluetoothManager.metrics.connected:
            bluetoothManager.isScanning ? .stopScan : .startScan
        case .authorized:
            .restart
        }
    }

    private func performPrimaryAction() {
        switch primaryActionKind {
        case .requestHealthAccess:
            healthSyncManager.requestAuthorization()
        case .refreshGhost:
            healthSyncManager.refreshTrainingInsights()
        case .startScan:
            bluetoothManager.startScan()
        case .stopScan:
            bluetoothManager.stopScan()
        case .restart:
            resetAttempt()
        case .none:
            break
        }
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

private enum GhostRacePrimaryAction {
    case requestHealthAccess
    case refreshGhost
    case startScan
    case stopScan
    case restart
    case none
}
