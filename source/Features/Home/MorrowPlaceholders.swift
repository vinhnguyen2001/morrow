import Foundation

/// PLACEHOLDER chrome shown at the user's request (ADR 0010, T-005). None of this is real data.
/// RELEASE BLOCKER for TestFlight (M6): remove each item or make it real.
/// VoiceOver text for placeholders must never claim data that does not exist (no counts, no "new").
enum MorrowPlaceholders {
    /// The red dot on the bell. Decorative: hidden from VoiceOver, the bell label states no count.
    static let showsNotificationDot = true
    /// Shown when the bell is tapped. There is no notification system yet.
    static let notificationsMessage = "Notifications are coming soon"
}
