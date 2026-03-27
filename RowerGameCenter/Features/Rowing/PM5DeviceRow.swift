import SwiftUI

struct PM5DeviceRow: View {
    let device: PM5DeviceSummary
    let isConnecting: Bool
    let isCurrentDevice: Bool
    let connectAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isCurrentDevice ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(isCurrentDevice ? AppTheme.success : AppTheme.tint)
                .frame(width: 40, height: 40)
                .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)

                Text(device.localName ?? "No local name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("RSSI \(device.rssi)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if isCurrentDevice {
                StatusBadge(title: "Connected", systemImage: "checkmark.circle.fill", tint: AppTheme.success)
            } else {
                Button("Connect", action: connectAction)
                    .buttonStyle(.bordered)
                    .disabled(isConnecting)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
