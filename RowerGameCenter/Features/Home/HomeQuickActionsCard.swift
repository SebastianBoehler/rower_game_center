import SwiftUI

struct HomeQuickActionsCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(AppNavigationModel.self) private var navigationModel

    var body: some View {
        PanelCard(title: "Quick Actions", subtitle: "Launch directly into a focused workout view.") {
            VStack(alignment: .leading, spacing: 16) {
                Text(bluetoothManager.metrics.connected
                    ? "The PM5 is already live, so every game can start immediately."
                    : "You can still open a game now, but it will wait for a PM5 connection before reacting."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                actionStack
            }
        }
    }

    @ViewBuilder
    private var actionStack: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(GameRoute.allCases) { route in
                        quickActionButton(for: route)
                    }
                }
            }
        } else {
            VStack(spacing: 12) {
                ForEach(GameRoute.allCases) { route in
                    quickActionButton(for: route)
                }
            }
        }
    }

    private func quickActionButton(for route: GameRoute) -> some View {
        Button {
            navigationModel.openGame(route)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: route.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(route.tint)
                    .frame(width: 42, height: 42)
                    .background(route.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(route.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .modifier(QuickActionSurface(tint: route.tint))
        }
        .buttonStyle(.plain)
    }
}

private struct QuickActionSurface: ViewModifier {
    let tint: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    .regular
                        .tint(tint.opacity(0.12))
                        .interactive(),
                    in: .rect(cornerRadius: 24)
                )
        } else {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppTheme.separator.opacity(0.12), lineWidth: 1)
                }
        }
    }
}
