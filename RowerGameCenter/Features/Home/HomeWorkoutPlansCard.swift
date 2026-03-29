import SwiftUI

struct HomeWorkoutPlansCard: View {
    private let featuredTemplates = Array(StructuredWorkoutLibrary.templates.prefix(3))

    var body: some View {
        PanelCard(title: "Workout Plans", subtitle: "Guided interval structures you can follow live from the PM5 timer.") {
            VStack(spacing: 12) {
                ForEach(featuredTemplates) { template in
                    NavigationLink {
                        StructuredWorkoutSessionView(template: template)
                    } label: {
                        WorkoutPlanRow(template: template)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    StructuredWorkoutLibraryView()
                } label: {
                    HStack {
                        Text("Open Full Workout Library")
                            .font(.subheadline.weight(.semibold))

                        Spacer(minLength: 12)

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(AppTheme.tint)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WorkoutPlanRow: View {
    let template: StructuredWorkoutTemplate

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: template.focus.systemImage)
                .font(.headline)
                .foregroundStyle(template.focus.tint)
                .frame(width: 42, height: 42)
                .background(template.focus.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(template.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(AppFormatters.totalDuration(template.totalDuration))
                    .font(.subheadline.weight(.semibold))

                Text(template.focus.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
