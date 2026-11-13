import Foundation

/// One marker on the Map: only what drawing and VoiceOver need. Holds a `Coordinate`, whose description is redacted,
/// so printing a pin never leaks a position.
struct MapPin: Identifiable, Equatable, Sendable {
    let id: UUID
    let coordinate: Coordinate
    let kind: MemoryKind
    let title: String
    let place: String?

    /// "Photo, Sunrise over the old harbour, Hội An": kind, title, place, same words as the peek row.
    var accessibilityLabel: String {
        MapPins.label(kind: kind, title: title, place: place)
    }
}

/// Pure helpers behind the Map screen. Computed outside `body` and unit tested with fake coordinates.
enum MapPins {
    /// Memories that have a coordinate, in the same order. Memories without one never reach the Map.
    static func pins(from memories: [Memory]) -> [MapPin] {
        memories.compactMap { memory in
            guard let coordinate = memory.coordinate else { return nil }
            return MapPin(id: memory.id, coordinate: coordinate, kind: memory.kind, title: memory.title,
                          place: MemoryDetailPresentation.placeText(for: memory))
        }
    }

    /// The selected id only if its pin still exists. A deleted memory therefore closes the peek sheet.
    static func validSelection(_ selection: UUID?, in pins: [MapPin]) -> UUID? {
        guard let selection, pins.contains(where: { $0.id == selection }) else { return nil }
        return selection
    }

    static func label(kind: MemoryKind, title: String, place: String?) -> String {
        [MemoryKindStyle.style(for: kind).displayName, title, place].compactMap { $0 }.joined(separator: ", ")
    }
}
