import Foundation

/// The parts of a reverse-geocode result that matter for a name. A plain value so the formatter needs no CoreLocation.
struct PlaceParts: Sendable, Equatable {
    var areasOfInterest: [String] = []
    var name: String?
    var thoroughfare: String?
    var locality: String?
}

/// Pure: "Point of interest, City", else "Street, City", else the placemark name, else the city.
enum PlaceNameFormatter {
    static func format(_ parts: PlaceParts) -> String {
        let locality = clean(parts.locality)
        let head = clean(parts.areasOfInterest.first) ?? clean(parts.thoroughfare) ?? clean(parts.name)
        let pieces = [head?.caseInsensitiveCompare(locality ?? "") == .orderedSame ? nil : head, locality].compactMap { $0 }
        return String(pieces.joined(separator: ", ").prefix(Memory.Limits.place))
    }

    private static func clean(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
