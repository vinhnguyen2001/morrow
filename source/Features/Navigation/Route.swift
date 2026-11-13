import Foundation

/// Pushed screens of the one `NavigationStack` (ADR 0009). Routes carry ids, never models, so a screen
/// always reads the current state.
enum Route: Hashable {
    case memory(UUID)
    case map

    /// The path without `.memory` routes whose memory no longer exists. Other routes stay.
    static func trimmed(_ path: [Route], alive: Set<UUID>) -> [Route] {
        path.filter { route in
            if case .memory(let id) = route { return alive.contains(id) }
            return true
        }
    }
}
