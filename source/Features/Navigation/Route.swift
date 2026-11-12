import Foundation

/// Pushed screens of the one `NavigationStack` (ADR 0009). Routes carry ids, never models, so a screen
/// always reads the current state. `.map` joins in T-004 step 4.
enum Route: Hashable {
    case memory(UUID)
}
