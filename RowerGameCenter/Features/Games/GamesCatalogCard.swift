import SwiftUI

struct GamesCatalogCard: View {
    // Group routes by category, preserving the category display order
    private var groupedRoutes: [(GameCategory, [GameRoute])] {
        GameCategory.allCases.compactMap { category in
            let routes = GameRoute.allCases.filter { $0.category == category }
            return routes.isEmpty ? nil : (category, routes)
        }
    }

    var body: some View {
        PanelCard(title: "Games", subtitle: "Competitive, rhythm, and technique surfaces.") {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupedRoutes, id: \.0.rawValue) { category, routes in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.rawValue.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(routes) { route in
                                NavigationLink(value: route) {
                                    GameCatalogRow(route: route)
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
