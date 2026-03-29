import SwiftUI

struct StructuredWorkoutSessionView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(SessionRecapManager.self) private var sessionRecapManager

    let template: StructuredWorkoutTemplate

    @State private var sessionBaseline = SessionBaseline()
    @State private var hasPresentedRecap = false

    private var sessionElapsed: TimeInterval {
        sessionBaseline.elapsedDelta(for: bluetoothManager.metrics) ?? 0
    }

    private var sessionProgress: Double {
        min(max(sessionElapsed / template.totalDuration, 0), 1)
    }

    private var currentStepState: WorkoutStepState {
        WorkoutStepState(template: template, elapsedTime: sessionElapsed)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sessionHeader
                currentStepCard
                timelineCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, bluetoothManager.metrics.connected ? 110 : 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle(template.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: captureBaselineIfNeeded)
        .onChange(of: bluetoothManager.metrics.connected) { _, isConnected in
            if isConnected {
                captureBaselineIfNeeded()
            } else {
                resetSession()
            }
        }
        .onChange(of: bluetoothManager.metrics.elapsedTime) { _, _ in
            captureBaselineIfNeeded()
            presentRecapIfNeeded()
        }
        .safeAreaInset(edge: .bottom) {
            if bluetoothManager.metrics.connected {
                sessionHUD
            }
        }
    }

    private var sessionHeader: some View {
        PanelCard(title: template.focus.title, subtitle: template.expectedOutcome) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    StatusBadge(
                        title: bluetoothManager.metrics.connected ? "PM5 Live" : "Waiting for PM5",
                        systemImage: bluetoothManager.metrics.connected ? "bolt.horizontal.fill" : "bolt.horizontal.circle",
                        tint: bluetoothManager.metrics.connected ? AppTheme.success : template.focus.tint
                    )

                    Spacer(minLength: 12)

                    Button("Restart Plan", action: resetSession)
                        .buttonStyle(.bordered)
                }

                Text(template.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: sessionProgress)
                    .tint(template.focus.tint)

                HStack {
                    Text(bluetoothManager.metrics.connected ? "Following live PM5 elapsed time." : "Connect the PM5 to turn this plan into a live workout guide.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    if !bluetoothManager.metrics.connected {
                        Button(bluetoothManager.isScanning ? "Stop Scan" : "Scan for PM5") {
                            if bluetoothManager.isScanning {
                                bluetoothManager.stopScan()
                            } else {
                                bluetoothManager.startScan()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var currentStepCard: some View {
        PanelCard(
            title: currentStepState.currentStep?.title ?? "Ready to Start",
            subtitle: currentStepState.currentStep?.detail ?? "The workout will lock onto the first block as soon as the PM5 timer starts moving."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Block \(currentStepState.currentStepNumber) of \(template.steps.count)", systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(template.focus.tint)

                    Spacer(minLength: 12)

                    Text(currentStepState.remainingLabel)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }

                ProgressView(value: currentStepState.stepProgress)
                    .tint(template.focus.tint)

                if let nextStep = currentStepState.nextStep {
                    Text("Next: \(nextStep.title) • \(nextStep.detail)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("This closes the session. Cool down with easy paddling once the timer ends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var timelineCard: some View {
        PanelCard(title: "Timeline", subtitle: "Each block follows the live PM5 elapsed timer.") {
            VStack(spacing: 12) {
                ForEach(Array(template.steps.enumerated()), id: \.element.id) { index, step in
                    StructuredWorkoutTimelineRow(
                        step: step,
                        isCurrent: index == currentStepState.currentIndex,
                        isComplete: index < currentStepState.currentIndex,
                        tint: template.focus.tint
                    )
                }
            }
        }
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            hudMetric(title: "Elapsed", value: AppFormatters.duration(sessionElapsed))
            Divider()
                .frame(height: 34)
            hudMetric(title: "Distance", value: AppFormatters.distance(sessionDistance))
            Divider()
                .frame(height: 34)
            hudMetric(title: "Pace", value: AppFormatters.pace(sessionPace))
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

    private var sessionDistance: Double? {
        sessionBaseline.distanceDelta(for: bluetoothManager.metrics)
    }

    private var sessionPace: TimeInterval? {
        guard let sessionDistance, sessionDistance > 0 else { return nil }
        return sessionElapsed / sessionDistance * 500
    }

    private func captureBaselineIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        sessionBaseline.captureIfNeeded(from: bluetoothManager.metrics)
    }

    private func presentRecapIfNeeded() {
        guard bluetoothManager.metrics.connected else { return }
        guard sessionElapsed >= template.totalDuration, !hasPresentedRecap else { return }

        hasPresentedRecap = true
        let recapMetrics = RowingMetrics(
            connected: bluetoothManager.metrics.connected,
            deviceName: bluetoothManager.metrics.deviceName,
            elapsedTime: sessionElapsed,
            distance: sessionDistance,
            strokeRate: bluetoothManager.metrics.strokeRate,
            strokeState: bluetoothManager.metrics.strokeState,
            pace: sessionPace,
            averagePace: bluetoothManager.metrics.averagePace,
            averagePowerWatts: bluetoothManager.metrics.averagePowerWatts,
            powerWatts: bluetoothManager.metrics.powerWatts,
            calories: bluetoothManager.metrics.calories,
            heartRate: bluetoothManager.metrics.heartRate,
            strokeCount: bluetoothManager.metrics.strokeCount,
            driveLengthMeters: bluetoothManager.metrics.driveLengthMeters,
            driveTime: bluetoothManager.metrics.driveTime,
            recoveryTime: bluetoothManager.metrics.recoveryTime,
            strokeDistanceMeters: bluetoothManager.metrics.strokeDistanceMeters,
            peakDriveForcePounds: bluetoothManager.metrics.peakDriveForcePounds,
            averageDriveForcePounds: bluetoothManager.metrics.averageDriveForcePounds,
            projectedWorkTime: bluetoothManager.metrics.projectedWorkTime,
            projectedWorkDistanceMeters: bluetoothManager.metrics.projectedWorkDistanceMeters,
            workPerStrokeJoules: bluetoothManager.metrics.workPerStrokeJoules,
            lastUpdatedAt: bluetoothManager.metrics.lastUpdatedAt
        )

        sessionRecapManager.present(
            SessionRecapBuilder.structuredWorkout(
                template: template,
                metrics: recapMetrics,
                elapsedTime: sessionElapsed
            )
        )
    }

    private func resetSession() {
        sessionBaseline.reset()
        hasPresentedRecap = false
        captureBaselineIfNeeded()
    }
}
