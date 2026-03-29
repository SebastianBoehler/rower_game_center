import Observation

@MainActor
@Observable
final class SessionRecapManager {
    var activeRecap: SessionRecap?

    @ObservationIgnored private var queuedRecaps: [SessionRecap] = []

    func present(_ recap: SessionRecap) {
        if activeRecap == nil {
            activeRecap = recap
        } else {
            queuedRecaps.append(recap)
        }
    }

    func dismissActiveRecap() {
        if queuedRecaps.isEmpty {
            activeRecap = nil
        } else {
            activeRecap = queuedRecaps.removeFirst()
        }
    }
}
