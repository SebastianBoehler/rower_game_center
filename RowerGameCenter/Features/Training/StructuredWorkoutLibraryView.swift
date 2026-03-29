import SwiftUI

struct StructuredWorkoutLibraryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(StructuredWorkoutLibrary.templates) { template in
                    NavigationLink {
                        StructuredWorkoutSessionView(template: template)
                    } label: {
                        LibraryTemplateCard(template: template)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(AppTheme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Workout Plans")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct LibraryTemplateCard: View {
    let template: StructuredWorkoutTemplate

    var body: some View {
        PanelCard(title: template.title, subtitle: template.summary) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(template.focus.title, systemImage: template.focus.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(template.focus.tint)

                    Spacer(minLength: 12)

                    Text(AppFormatters.totalDuration(template.totalDuration))
                        .font(.subheadline.weight(.semibold))
                }

                Text(template.expectedOutcome)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(template.steps.prefix(3)) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(template.focus.tint)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))

                            Text("\(AppFormatters.totalDuration(step.duration)) • \(step.detail)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Text("\(template.steps.count) steps")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
