import Foundation

/// Part of the day, computed from the hour. Replaces the design's "mood" (there is no mood data).
enum DayPart: Equatable, CaseIterable {
    case morning, afternoon, evening, night

    /// Morning 05-11, afternoon 12-16, evening 17-20, night 21-04.
    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        case 17..<21: self = .evening
        default: self = .night
        }
    }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
}
