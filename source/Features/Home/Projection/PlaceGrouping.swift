import Foundation

/// One tile of the Places tab with everything it shows, already computed.
struct PlaceCard: Identifiable, Equatable {
    /// The normalised name (see `PlaceGrouping.key`): stable while the place exists.
    let id: String
    /// Spelling of the most recent memory.
    let name: String
    let count: Int
    /// "1 memory", "3 memories".
    let countText: String
    /// "Last: Nov 12" (replaces the design's region line; no coordinates needed).
    let lastText: String
    /// Photo of the newest memory that has one; nil shows the pin glyph.
    let coverFileName: String?
    let imageHeight: CGFloat
    let accessibilityLabel: String
}

/// Pure projection of memories into Places tiles (Main.dc.html lines 1292-1297, 181-205).
/// Memories are grouped by place name ignoring case, diacritics and surrounding spaces ("Hội An",
/// "hội an ", "Hoi An" are one place). Memories without a place name are skipped.
/// "Đà Nẵng" and "Da Nang" are one place (`TextMatching.key` maps `đ` to `d`).
enum PlaceGrouping {
    /// Photo heights by display index (design varies them per place).
    static let imageHeights: [CGFloat] = [135, 150, 165]

    static func key(for name: String?) -> String? {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return TextMatching.key(trimmed)
    }

    static func countText(_ count: Int) -> String {
        count == 1 ? "1 memory" : "\(count) memories"
    }

    static func build(memories: [Memory], calendar: Calendar, now: Date) -> TwoColumns<PlaceCard> {
        // Newest first with a deterministic tie-break, so "first seen" means "most recent".
        let newestFirst = memories.sorted { ($0.createdAt, $0.id.uuidString) > ($1.createdAt, $1.id.uuidString) }
        var groups: [String: [Memory]] = [:]
        var order: [String] = []
        for memory in newestFirst {
            guard let key = key(for: memory.placeName) else { continue }
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(memory)
        }
        // `order` is already by most recent visit (the first memory of each group is its newest).
        let cards = order.enumerated().compactMap { index, key -> PlaceCard? in
            guard let group = groups[key], let latest = group.first else { return nil }
            let name = (latest.placeName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lastDate = DateText.short(latest.createdAt, calendar: calendar, now: now)
            let countText = countText(group.count)
            return PlaceCard(
                id: key, name: name, count: group.count, countText: countText, lastText: "Last: \(lastDate)",
                coverFileName: group.first { $0.photoFileName != nil }?.photoFileName,
                imageHeight: imageHeights[index % imageHeights.count],
                accessibilityLabel: "\(name), \(countText), last visit \(lastDate)"
            )
        }
        return TwoColumns(cards)
    }
}
