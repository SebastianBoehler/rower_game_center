import SwiftUI

struct PowerBar: View {
    let watts: Int?

    private var normalizedPower: Double {
        guard let watts else { return 0 }
        return min(Double(watts) / 600, 1)
    }

    var body: some View {
        PanelCard(title: "Power Output", subtitle: "Relative to a 600 W sprint ceiling.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Current power", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(AppFormatters.watts(watts))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }

                Gauge(value: normalizedPower) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(AppTheme.tint)
                .accessibilityValue(AppFormatters.watts(watts))
            }
        }
    }
}
