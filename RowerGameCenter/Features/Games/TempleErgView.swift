import SwiftUI

struct TempleErgView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(SessionRecapManager.self) private var sessionRecapManager

    @State private var gameState = TempleErgEngine.makeInitialState()
    @State private var runBaseline = SessionBaseline()

    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    private var runDistance: Double {
        runBaseline.distanceDelta(for: bluetoothManager.metrics) ?? 0
    }

    private var runElapsed: TimeInterval? {
        runBaseline.elapsedDelta(for: bluetoothManager.metrics)
    }

    private var currentPace: TimeInterval? {
        guard let elapsed = runElapsed, runDistance > 0 else { return nil }
        return elapsed / runDistance * 500
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Track fills the full screen, behind the nav bar and the HUD bar
            TempleErgTrackView(
                obstacles: gameState.obstacles,
                currentReading: gameState.currentReading,
                lives: gameState.lives
            )
            .ignoresSafeArea()

            // Header card floats on top, stays within the readable content area
            TempleErgHeaderCard(
                currentReading: gameState.currentReading,
                hint: gameState.currentHint,
                isConnected: bluetoothManager.metrics.connected,
                restartGame: restartGame
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .navigationTitle("Temple Erg")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear(perform: captureBaselineIfNeeded)
        .onReceive(timer, perform: handleTick)
        .onChange(of: bluetoothManager.metrics.connected) { _, isConnected in
            if isConnected {
                captureBaselineIfNeeded()
            } else {
                restartGame()
            }
        }
        .overlay {
            if !bluetoothManager.metrics.connected {
                TempleErgUnavailableOverlay(
                    isScanning: bluetoothManager.isScanning,
                    startScan: startScan,
                    stopScan: stopScan
                )
            } else if gameState.isGameOver {
                TempleErgGameOverOverlay(
                    score: gameState.score,
                    clearedObstacles: gameState.clearedObstacles,
                    bestCombo: gameState.bestCombo,
                    restartGame: restartGame
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            if bluetoothManager.metrics.connected {
                TempleErgHUDBar(
                    score: gameState.score,
                    combo: gameState.combo,
                    clearedObstacles: gameState.clearedObstacles,
                    distance: runDistance,
                    pace: currentPace
                )
            }
        }
    }

    private func handleTick(_ date: Date) {
        guard bluetoothManager.metrics.connected else { return }
        captureBaselineIfNeeded()

        if let summary = TempleErgEngine.advance(
            state: &gameState,
            metrics: bluetoothManager.metrics,
            now: date
        ) {
            presentRecap(for: summary)
        }
    }

    private func captureBaselineIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        runBaseline.captureIfNeeded(from: bluetoothManager.metrics)
    }

    private func presentRecap(for summary: TempleErgRunSummary) {
        sessionRecapManager.present(
            SessionRecapBuilder.templeErg(
                score: summary.score,
                clearedObstacles: summary.clearedObstacles,
                bestCombo: summary.bestCombo,
                distanceMeters: runDistance,
                elapsedTime: runElapsed,
                dominantAction: summary.dominantAction
            )
        )
    }

    private func restartGame() {
        gameState = TempleErgEngine.makeInitialState()
        runBaseline.reset()
        captureBaselineIfNeeded()
    }

    private func startScan() {
        bluetoothManager.startScan()
    }

    private func stopScan() {
        bluetoothManager.stopScan()
    }
}
