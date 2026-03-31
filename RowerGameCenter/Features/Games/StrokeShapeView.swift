import SwiftUI

struct StrokeShapeView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    private var assessment: StrokeShapeAssessment? {
        StrokeShapeAnalyzer.assessment(for: bluetoothManager.latestForceCurve)
    }

    private var referenceCurve: [Double] {
        StrokeShapeAnalyzer.referenceCurve()
    }

    private var liveCurve: [Double]? {
        bluetoothManager.latestForceCurve.map {
            StrokeShapeAnalyzer.normalizedCurve(from: $0.samples)
        }
    }

    private var livePreviewCurve: [Double]? {
        bluetoothManager.liveForceCurvePreview.map {
            StrokeShapeAnalyzer.normalizedCurve(from: $0.samples)
        }
    }

    private var displayedCurve: [Double]? {
        livePreviewCurve ?? liveCurve
    }

    private var isPreviewingLiveCurve: Bool {
        livePreviewCurve != nil
    }

    private var historicalCurves: [[Double]] {
        bluetoothManager.recentForceCurves
            .suffix(10)
            .map { StrokeShapeAnalyzer.normalizedCurve(from: $0.samples) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        Group {
            if !bluetoothManager.metrics.connected {
                disconnectedState
            } else if !bluetoothManager.supportsForceCurve {
                unsupportedState
            } else if bluetoothManager.latestForceCurve == nil {
                waitingForFirstStrokeState
            } else {
                liveSession
            }
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Stroke Shape")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var disconnectedState: some View {
        ContentUnavailableView {
            Label("Connect a PM5 to Inspect Technique", systemImage: "waveform.path.ecg.rectangle")
        } description: {
            Text("Stroke Shape needs a live PM5 connection so it can read the force-curve packets and overlay them against the coaching reference.")
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

    private var unsupportedState: some View {
        ContentUnavailableView {
            Label("Force Curve Not Exposed", systemImage: "antenna.radiowaves.left.and.right")
        } description: {
            Text("This PM5 did not advertise the official Concept2 force-curve characteristic. PM5v1 monitors do not support that BLE feature, so the overlay cannot be drawn on this device.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var waitingForFirstStrokeState: some View {
        VStack(spacing: 20) {
            PanelCard(
                title: "Force Curve Ready",
                subtitle: "The PM5 exposed the technique stream. Pull a few full strokes to populate the first live curve."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    StatusBadge(title: "Waiting for first stroke", systemImage: "waveform", tint: AppTheme.tint)

                    Text(waitingMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            StrokeShapeGraphView(
                referenceCurve: referenceCurve,
                liveCurve: livePreviewCurve,
                historicalCurves: [],
                tint: AppTheme.tint,
                liveCurveIsPreview: isPreviewingLiveCurve
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .safeAreaInset(edge: .bottom) {
            waitingHUD
        }
    }

    private var liveSession: some View {
        VStack(spacing: 20) {
            sessionHeader

            StrokeShapeGraphView(
                referenceCurve: referenceCurve,
                liveCurve: displayedCurve,
                historicalCurves: historicalCurves,
                tint: feedbackTint,
                liveCurveIsPreview: isPreviewingLiveCurve
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

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    StatusBadge(title: feedbackTitle, systemImage: feedbackImage, tint: feedbackTint)

                    Text(feedbackHeadline)
                        .font(.title3.weight(.semibold))

                    Text(feedbackMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Match")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(assessment?.score ?? 0)")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var waitingHUD: some View {
        HStack(spacing: 0) {
            sessionMetric(title: "Device", value: bluetoothManager.metrics.deviceName ?? "PM5")
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Stroke Rate", value: AppFormatters.strokeRate(bluetoothManager.metrics.strokeRate))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Updated", value: AppFormatters.relativeTimestamp(bluetoothManager.metrics.lastUpdatedAt))
        }
        .modifier(SessionHUDStyle())
    }

    private var sessionHUD: some View {
        HStack(spacing: 0) {
            sessionMetric(title: "Peak", value: AppFormatters.force(bluetoothManager.metrics.peakDriveForcePounds))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Drive", value: AppFormatters.shortSeconds(bluetoothManager.metrics.driveTime))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Recovery", value: AppFormatters.shortSeconds(bluetoothManager.metrics.recoveryTime))
            Divider()
                .frame(height: 34)
            sessionMetric(title: "Work", value: AppFormatters.energy(bluetoothManager.metrics.workPerStrokeJoules))
        }
        .modifier(SessionHUDStyle())
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

    private var feedbackTitle: String {
        switch assessment?.feedback ?? .balanced {
        case .balanced: "Balanced drive"
        case .earlyPeak: "Early peak"
        case .latePeak: "Late peak"
        case .spikyDrive: "Spiky drive"
        case .flatDrive: "Flat drive"
        }
    }

    private var feedbackHeadline: String {
        switch assessment?.feedback ?? .balanced {
        case .balanced: "Live curve is close to the broad reference arc."
        case .earlyPeak: "The force arrives too early, then falls away."
        case .latePeak: "The drive builds too slowly and peaks late."
        case .spikyDrive: "The live curve has extra bumps instead of one clean build."
        case .flatDrive: "The drive is not filling the middle of the stroke yet."
        }
    }

    private var feedbackMessage: String {
        switch assessment?.feedback ?? .balanced {
        case .balanced: "Keep the smooth rise and controlled release. The gray line is a coaching reference, not a fixed ideal for every rower."
        case .earlyPeak: "Try loading the legs a touch longer before the peak so the curve stays fuller through the middle of the drive."
        case .latePeak: "Bring pressure on earlier in the drive. Aim for a quicker rise without turning the stroke into a sharp spike."
        case .spikyDrive: "Look for one continuous build in pressure. Extra bumps usually mean the handle force is arriving in separate surges."
        case .flatDrive: "Build a fuller middle section instead of a low, short push. Drive length and steady pressure usually matter more than chasing one peak."
        }
    }

    private var feedbackImage: String {
        switch assessment?.feedback ?? .balanced {
        case .balanced: "checkmark.circle.fill"
        case .earlyPeak: "arrow.left.circle.fill"
        case .latePeak: "arrow.right.circle.fill"
        case .spikyDrive: "waveform.path.ecg"
        case .flatDrive: "minus.circle.fill"
        }
    }

    private var feedbackTint: Color {
        switch assessment?.feedback ?? .balanced {
        case .balanced: AppTheme.success
        case .earlyPeak, .latePeak, .spikyDrive, .flatDrive: AppTheme.tint
        }
    }

    private var waitingMessage: String {
        if isPreviewingLiveCurve {
            return "The PM5 has started streaming curve samples. Finish the stroke and the first full overlay plus coaching score will lock in automatically."
        }

        return "If the graph stays empty while you row, the monitor may require an explicit curve read on each stroke. The app is already attempting that when the PM5 enters recovery."
    }
}

private struct SessionHUDStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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
}
