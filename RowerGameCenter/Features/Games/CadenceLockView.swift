import SwiftUI

struct CadenceLockView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    @State private var score = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var roundIndex = 0
    @State private var remainingSeconds = roundDuration
    @State private var lastProcessedSecond = -1

    private static let targets = [18, 20, 22, 24, 26, 28, 24, 20]
    private static let roundDuration = 12
    private static let tolerance = 1

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if bluetoothManager.metrics.connected {
                liveSession
            } else {
                unavailableState
            }
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Cadence Lock")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: resetSession)
        .onReceive(timer, perform: processTick)
    }

    private var liveSession: some View {
        VStack(spacing: 20) {
            sessionHeader

            CadenceLockDialView(
                strokeRate: bluetoothManager.metrics.strokeRate,
                targetRate: currentTarget,
                tolerance: Self.tolerance
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
            Label("Connect a PM5 to Play", systemImage: "metronome")
        } description: {
            Text("Cadence Lock reacts to live stroke rate. Connect the PM5 first, then hold each target band as it shifts.")
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    StatusBadge(title: lockStatusTitle, systemImage: lockStatusImage, tint: lockStatusTint)

                    Text("Hold \(currentTarget) spm")
                        .font(.title3.weight(.semibold))

                    Text("The target changes every \(Self.roundDuration) seconds. Stay inside the green band to build score and streak.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Shift")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(remainingSeconds)s")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            sessionMetric(title: "Score", value: "\(score)")
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Streak", value: "\(streak)")
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
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

    private var currentTarget: Int {
        Self.targets[roundIndex % Self.targets.count]
    }

    private var isLocked: Bool {
        guard let strokeRate = bluetoothManager.metrics.strokeRate else { return false }
        return abs(strokeRate - currentTarget) <= Self.tolerance
    }

    private var lockStatusTitle: String {
        isLocked ? "Locked" : "Adjust"
    }

    private var lockStatusImage: String {
        isLocked ? "checkmark.circle.fill" : "dial.medium.fill"
    }

    private var lockStatusTint: Color {
        isLocked ? AppTheme.success : AppTheme.tint
    }

    private func resetSession() {
        score = 0
        streak = 0
        bestStreak = 0
        roundIndex = 0
        remainingSeconds = Self.roundDuration
        lastProcessedSecond = -1
    }

    private func processTick(_ date: Date) {
        guard bluetoothManager.metrics.connected else { return }

        let second = Int(date.timeIntervalSince1970.rounded(.down))
        guard second != lastProcessedSecond else { return }
        lastProcessedSecond = second

        if isLocked {
            streak += 1
            bestStreak = max(bestStreak, streak)
            score += 10 + min(streak, 12) * 2
        } else if bluetoothManager.metrics.strokeRate != nil {
            streak = 0
        }

        if remainingSeconds == 1 {
            roundIndex += 1
            remainingSeconds = Self.roundDuration
        } else {
            remainingSeconds -= 1
        }
    }
}
