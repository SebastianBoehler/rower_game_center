import SwiftUI
import UIKit

struct PM5DiagnosticsView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if bluetoothManager.diagnostics.isEmpty {
                    ContentUnavailableView(
                        "No Diagnostics Yet",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Bluetooth state changes, PM5 discovery events, control-service requests, and rower errors will appear here.")
                    )
                } else {
                    List(reversedDiagnostics) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Label(entry.levelTitle, systemImage: entry.levelSystemImage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(entry.levelTint)

                                Text(entry.category.uppercased())
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(timestamp(for: entry.timestamp))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            Text(entry.message)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.secondaryGroupedBackground)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.groupedBackground)
                }
            }
            .background(AppTheme.groupedBackground)
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        bluetoothManager.clearDiagnostics()
                    }
                    .disabled(bluetoothManager.diagnostics.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Copy") {
                        UIPasteboard.general.string = bluetoothManager.diagnosticsReport
                    }
                    .disabled(bluetoothManager.diagnostics.isEmpty)
                }
            }
        }
    }

    private var reversedDiagnostics: [PM5DiagnosticEntry] {
        Array(bluetoothManager.diagnostics.reversed())
    }

    private func timestamp(for date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .second(.twoDigits)
        )
    }
}

private extension PM5DiagnosticEntry {
    var levelTitle: String {
        switch level {
        case .info:
            "Info"
        case .notice:
            "Notice"
        case .error:
            "Error"
        }
    }

    var levelSystemImage: String {
        switch level {
        case .info:
            "info.circle.fill"
        case .notice:
            "waveform.badge.magnifyingglass"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var levelTint: Color {
        switch level {
        case .info:
            .secondary
        case .notice:
            AppTheme.tint
        case .error:
            AppTheme.warning
        }
    }
}
