import Foundation

/// Pure text for the Detail screen. Unit tested; no SwiftUI.
enum MemoryDetailPresentation {
    /// "November 12, 2026 at 8:30 PM". Calendar (and its locale and time zone) are injected so tests are stable.
    static func dateText(for memory: Memory, calendar: Calendar) -> String {
        let style = Date.FormatStyle(date: .long, time: .shortened,
                                     locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
        return memory.createdAt.formatted(style)
    }

    /// Small line above the title in the coloured header (design "a note").
    static func kicker(for kind: MemoryKind) -> String {
        switch kind {
        case .photo: return "a photo"
        case .note: return "a note"
        }
    }

    /// Place name without surrounding spaces; nil when empty, so no empty chip is drawn.
    static func placeText(for memory: Memory) -> String? {
        guard let place = memory.placeName?.trimmingCharacters(in: .whitespacesAndNewlines), !place.isEmpty else { return nil }
        return place
    }

    /// Note text, nil when empty.
    static func bodyText(for memory: Memory) -> String? {
        guard let body = memory.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty else { return nil }
        return body
    }
}
