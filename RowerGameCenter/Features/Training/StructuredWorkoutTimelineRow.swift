import SwiftUI

struct StructuredWorkoutTimelineRow: View {
    let step: StructuredWorkoutStep
    let isCurrent: Bool
    let isComplete: Bool
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : isCurrent ? "play.circle.fill" : "circle")
                .foregroundStyle(isComplete || isCurrent ? tint : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.subheadline.weight(.semibold))

                Text(step.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(AppFormatters.totalDuration(step.duration))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
