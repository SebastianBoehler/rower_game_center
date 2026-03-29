@preconcurrency import CoreBluetooth
import Foundation
import OSLog

extension PM5BluetoothManager {
    var diagnosticsReport: String {
        diagnostics.map(\.consoleLine).joined(separator: "\n")
    }

    func clearDiagnostics() {
        diagnostics = []
    }

    func logInfo(_ message: String, category: String = "general") {
        appendDiagnostic(level: .info, message: message, category: category)
    }

    func logNotice(_ message: String, category: String = "general") {
        appendDiagnostic(level: .notice, message: message, category: category)
    }

    func logError(_ message: String, category: String = "general") {
        appendDiagnostic(level: .error, message: message, category: category)
    }

    func logFirstNotificationIfNeeded(from characteristic: CBCharacteristic, byteCount: Int) {
        let uuid = characteristic.uuid.uuidString.uppercased()
        guard seenNotificationCharacteristicUUIDs.insert(uuid).inserted else {
            return
        }

        logInfo(
            "First packet received from \(uuid) (\(byteCount) bytes).",
            category: "telemetry"
        )
    }
}

private extension PM5BluetoothManager {
    func appendDiagnostic(
        level: PM5DiagnosticLevel,
        message: String,
        category: String
    ) {
        let entry = PM5DiagnosticEntry(
            timestamp: .now,
            level: level,
            category: category,
            message: message
        )

        diagnostics.append(entry)

        let overflow = diagnostics.count - PM5DiagnosticsLog.limit
        if overflow > 0 {
            diagnostics.removeFirst(overflow)
        }

        let renderedMessage = entry.consoleLine
        switch level {
        case .info:
            PM5DiagnosticsLog.logger.info("\(renderedMessage, privacy: .public)")
        case .notice:
            PM5DiagnosticsLog.logger.notice("\(renderedMessage, privacy: .public)")
        case .error:
            PM5DiagnosticsLog.logger.error("\(renderedMessage, privacy: .public)")
        }
    }
}

private enum PM5DiagnosticsLog {
    static let limit = 160
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.sebastianboehler.rowergamecenter",
        category: "PM5"
    )
}
