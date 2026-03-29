import SwiftUI

struct RowingDashboardView: View {
    @Environment(PM5BluetoothManager.self) private var bluetoothManager
    @State private var showingDiagnostics = false

    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    overviewSection

                    if bluetoothManager.metrics.connected {
                        ConnectedRowingDashboardSections()
                    } else {
                        DisconnectedRowingDashboardSections()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Rower")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(AppTheme.groupedBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingDiagnostics = true
                } label: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                }
                .accessibilityLabel("Open diagnostics")
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            PM5DiagnosticsView()
        }
    }

    private var overviewSection: some View {
        PanelCard(
            title: "Concept2 PM5",
            subtitle: "Designed around a real Bluetooth workout connection, not simulated data."
        ) {
            ViewThatFits {
                HStack(alignment: .top, spacing: 16) {
                    overviewIcon
                    overviewSummary
                    Spacer(minLength: 12)
                    overviewBadge
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        overviewIcon
                        Spacer(minLength: 12)
                        overviewBadge
                    }

                    overviewSummary
                }
            }

            if let errorMessage = bluetoothManager.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warning)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            LabeledContent("Last update", value: AppFormatters.relativeTimestamp(bluetoothManager.metrics.lastUpdatedAt))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var overviewDetail: String {
        if bluetoothManager.metrics.connected {
            return "Live metrics are flowing into the dashboard and gameplay surfaces."
        }

        if bluetoothManager.isScanning {
            return "Scanning nearby Bluetooth devices for a compatible PM5."
        }

        return "Scan for a nearby monitor to start a real rowing session."
    }

    private var overviewIcon: some View {
        Image(systemName: bluetoothManager.metrics.connected ? "figure.rower" : "dot.radiowaves.left.and.right")
            .font(.title2.weight(.semibold))
            .foregroundStyle(AppTheme.tint)
            .frame(width: 48, height: 48)
            .background(AppTheme.tertiaryGroupedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var overviewSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bluetoothManager.connectionSummary)
                .font(.title3.weight(.semibold))
                .layoutPriority(1)

            Text(overviewDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var overviewBadge: some View {
        StatusBadge(
            title: bluetoothManager.connectionPhase.title,
            systemImage: bluetoothManager.connectionPhase.systemImage,
            tint: phaseTint
        )
    }

    private var phaseTint: Color {
        switch bluetoothManager.connectionPhase {
        case .connected:
            AppTheme.success
        case .error:
            AppTheme.warning
        case .scanning, .connecting:
            AppTheme.tint
        case .idle, .disconnecting:
            .secondary
        }
    }
}
