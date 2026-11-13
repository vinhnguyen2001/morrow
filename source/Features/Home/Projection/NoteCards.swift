import Foundation

/// One tile of the Notes tab with everything it shows, already computed.
struct NoteCard: Identifiable, Equatable {
    enum Tone: Equatable { case lavender, peach }

    /// The memory's id: stable, and what a tap opens.
    let id: UUID
    let title: String
    let preview: String?
    let tone: Tone
    /// Degrees (Main.dc.html line 1285). Zeroed by the view under Reduce Motion and at accessibility sizes.
    let tilt: Double
    let lineLimit: Int
    let dateText: String
    let placeName: String?
    let accessibilityLabel: String
}

/// Pure projection of memories into Notes tiles (Main.dc.html lines 1281-1290).
/// Tone, tilt and line limit use the index counted from the OLDEST note, so adding a note never changes
/// the look of old ones (same rule as `Stagger`). Columns are dealt by display position, newest first.
enum NoteCards {
    static let tilts: [Double] = [0.6, -0.8, 0.3, -0.4]

    static func build(memories: [Memory], calendar: Calendar, now: Date) -> TwoColumns<NoteCard> {
        let ascending = memories
            .filter { $0.kind == .note }
            .sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
        let cards = ascending.enumerated().reversed().map { index, memory in
            card(for: memory, index: index, calendar: calendar, now: now)
        }
        return TwoColumns(cards)
    }

    private static func card(for memory: Memory, index: Int, calendar: Calendar, now: Date) -> NoteCard {
        let place = memory.placeName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeName = (place?.isEmpty ?? true) ? nil : place
        let body = memory.body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateText = DateText.short(memory.createdAt, calendar: calendar, now: now)
        var spoken = ["Note", memory.title]
        if let placeName { spoken.append("at \(placeName)") }
        spoken.append(dateText)
        return NoteCard(
            id: memory.id,
            title: memory.title,
            preview: (body?.isEmpty ?? true) ? nil : body,
            tone: index % 3 == 2 ? .peach : .lavender,
            tilt: tilts[index % tilts.count],
            lineLimit: index % 2 == 1 ? 4 : 6,
            dateText: dateText,
            placeName: placeName,
            accessibilityLabel: spoken.joined(separator: ", ")
        )
    }
}
