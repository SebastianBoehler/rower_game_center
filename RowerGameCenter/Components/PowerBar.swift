import SwiftUI

struct PowerBar: View {
    let watts: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var normalizedPower: CGFloat {
        guard let watts else { return 0 }
        return min(CGFloat(watts) / 600, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Power")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent.opacity(0.9))
                    .textCase(.uppercase)

                Spacer()

                Text(AppFormatters.watts(watts))
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))

                    Capsule()
                        .fill(AppTheme.accent)
                        .frame(width: geometry.size.width * normalizedPower)
                        .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: normalizedPower)
                }
            }
            .frame(height: 16)

            Text("Live PM5 watts mapped against a 600 W sprint ceiling.")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
