import SwiftUI

struct LaneSprintView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let goalDistance = 500.0

    var body: some View {
        Group {
            if bluetoothManager.metrics.connected {
                content
            } else {
                unavailableState
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Lane Sprint")
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }

    private var content: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Live session")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .textCase(.uppercase)

                Text("Your boat only moves from real PM5 distance.")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)

                Text("This screen keeps the playfield clear and uses a compact HUD, not a dashboard wall.")
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            PanelCard(title: "Track") {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppTheme.accentSoft)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppTheme.ink)
                            .frame(width: 4)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.vertical, 10)
                            .padding(.trailing, 16)

                        Circle()
                            .fill(AppTheme.ink)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: "figure.rower")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: boatOffset(for: geometry.size.width))
                            .animation(reduceMotion ? nil : .snappy(duration: 0.32), value: bluetoothManager.metrics.distance)
                    }
                }
                .frame(height: 92)

                HStack {
                    statView(title: "Distance", value: AppFormatters.distance(bluetoothManager.metrics.distance))
                    Spacer()
                    statView(title: "Pace", value: AppFormatters.pace(bluetoothManager.metrics.pace))
                    Spacer()
                    statView(title: "Power", value: AppFormatters.watts(bluetoothManager.metrics.powerWatts))
                }
            }

            Spacer()
        }
        .padding(20)
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Text("Connect a PM5 to play")
                .font(.title.weight(.heavy))
                .foregroundStyle(AppTheme.ink)

            Text("Lane Sprint does not simulate rowing. It only reads live BLE metrics from a real Concept2 PM5.")
                .font(.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private func boatOffset(for totalWidth: CGFloat) -> CGFloat {
        let progress = min((bluetoothManager.metrics.distance ?? 0) / goalDistance, 1)
        let usableWidth = max(totalWidth - 70, 0)
        return usableWidth * progress
    }

    private func statView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.mutedInk)

            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(AppTheme.ink)
        }
    }
}
