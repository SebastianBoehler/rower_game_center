import SwiftUI

struct DiagnosticsSettingsCard: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager

    var body: some View {
        PanelCard(title: "Logs & Diagnostics", subtitle: "Inspect the Bluetooth trace, PM5 events, and sync issues.") {
            NavigationLink {
                PM5DiagnosticsView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tint)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Diagnostics")
                            .font(.headline)

                        Text("\(bluetoothManager.diagnostics.count) recent entries across discovery, telemetry, and errors.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
