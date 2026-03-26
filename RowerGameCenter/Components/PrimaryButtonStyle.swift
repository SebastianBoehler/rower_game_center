import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let variant: Variant

    enum Variant {
        case primary
        case secondary
        case danger
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.84 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            AppTheme.action
        case .secondary:
            AppTheme.accentSoft
        case .danger:
            AppTheme.warning
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .secondary:
            AppTheme.ink
        case .primary, .danger:
            .white
        }
    }
}
