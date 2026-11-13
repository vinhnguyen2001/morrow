import Foundation

/// The three views of Home (the design's Journey / Notes / Places; "Journey" is "Moments" here, ADR 0010).
enum HomeTab: String, CaseIterable, Identifiable, Equatable {
    case moments
    case notes
    case places

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moments: return "Moments"
        case .notes: return "Notes"
        case .places: return "Places"
        }
    }
}
