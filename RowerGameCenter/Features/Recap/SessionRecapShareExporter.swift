import SwiftUI
import UIKit

enum SessionRecapShareError: LocalizedError {
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            "The recap image could not be generated."
        }
    }
}

@MainActor
enum SessionRecapShareExporter {
    static func exportImage(for recap: SessionRecap) throws -> URL {
        let poster = SessionRecapSharePoster(recap: recap)
        let renderer = ImageRenderer(content: poster)
        renderer.scale = 1
        renderer.proposedSize = .init(width: 1080, height: 1350)

        guard let image = renderer.uiImage,
              let data = image.pngData() else {
            throw SessionRecapShareError.renderFailed
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(recap.fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }
}
