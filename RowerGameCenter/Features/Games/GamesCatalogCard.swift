import SwiftUI

struct GamesCatalogCard: View {
    var body: some View {
        PanelCard(title: "All Games", subtitle: "Competitive, rhythm, and technique surfaces.") {
            VStack(spacing: 12) {
                ForEach(Array(GameRoute.allCases.enumerated()), id: \.element.id) { index, route in
                    NavigationLink(value: route) {
                        GameCatalogRow(route: route)
                    }
                    .buttonStyle(.plain)

                    if index < GameRoute.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
        }
    }
}

private struct GameCatalogRow: View {
    let route: GameRoute

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: route.systemImage)
                .font(.title2)
                .foregroundStyle(route.tint)
                .frame(width: 44, height: 44)
                .background(route.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(route.title)
                    .font(.headline)

                Text(route.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
