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
        ZStack {
            AppTheme.groupedBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                TempleErgHeaderCard(
                    currentReading: gameState.currentReading,
                    hint: gameState.currentHint,
                    isConnected: bluetoothManager.metrics.connected,
                    restartGame: restartGame
                )

                TempleErgTrackView(
                    obstacles: gameState.obstacles,
                    currentReading: gameState.currentReading,
                    lives: gameState.lives
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, bluetoothManager.metrics.connected ? 118 : 32)
        }
        .navigationTitle("Temple Erg")
        .navigationBarTitleDisplayMode(.inline)
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

private struct TempleErgHeaderCard: View {
    let currentReading: TempleErgActionReading
    let hint: String
    let isConnected: Bool
    let restartGame: () -> Void

    var body: some View {
        PanelCard(
            title: "Temple Erg",
            subtitle: "Temple Run energy, adapted to PM5 inputs. Burst to jump, settle to duck, hammer to smash."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    StatusBadge(
                        title: isConnected ? currentReading.title : "Waiting for PM5",
                        systemImage: currentReading.systemImage,
                        tint: currentReading.tint
                    )

                    Spacer(minLength: 12)

                    Button("Restart Run", action: restartGame)
                        .buttonStyle(.glass)
                }

                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TempleErgActionLegend()
            }
        }
    }
}

private struct TempleErgActionLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(TempleErgAction.allCases) { action in
                HStack(spacing: 6) {
                    Image(systemName: action.systemImage)
                    Text(action.title)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(action.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(action.tint.opacity(0.12), in: Capsule())
            }
        }
    }
}

private struct TempleErgHUDBar: View {
    let score: Int
    let combo: Int
    let clearedObstacles: Int
    let distance: Double
    let pace: TimeInterval?

    var body: some View {
        HStack(spacing: 0) {
            metric(title: "Score", value: "\(score)")
            Divider()
                .frame(height: 34)
            metric(title: "Combo", value: "\(combo)x")
            Divider()
                .frame(height: 34)
            metric(title: "Clears", value: "\(clearedObstacles)")
            Divider()
                .frame(height: 34)
            metric(title: "Distance", value: AppFormatters.distance(distance))
            Divider()
                .frame(height: 34)
            metric(title: "Pace", value: AppFormatters.pace(pace))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular.tint(.orange.opacity(0.14)), in: .rect(cornerRadius: 24))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func metric(title: String, value: String) -> some View {
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
}

private struct TempleErgUnavailableOverlay: View {
    let isScanning: Bool
    let startScan: () -> Void
    let stopScan: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Connect a PM5 to Run", systemImage: "figure.rower")
        } description: {
            Text("Temple Erg reacts to live PM5 inputs. Strong bursts jump, calm recoveries duck, and heavy hits smash through gates.")
        } actions: {
            Button(isScanning ? "Stop Scan" : "Scan for PM5") {
                if isScanning {
                    stopScan()
                } else {
                    startScan()
                }
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, 20)
        .background(.regularMaterial)
    }
}

private struct TempleErgGameOverOverlay: View {
    let score: Int
    let clearedObstacles: Int
    let bestCombo: Int
    let restartGame: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Run Over")
                .font(.largeTitle.weight(.bold))

            Text("You cleared \(clearedObstacles) obstacles, stacked a \(bestCombo)x best combo, and finished with \(score) points.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Restart Run", action: restartGame)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        }
        .padding(28)
        .glassEffect(.regular.tint(.orange.opacity(0.16)), in: .rect(cornerRadius: 28))
        .padding(.horizontal, 40)
    }
}
