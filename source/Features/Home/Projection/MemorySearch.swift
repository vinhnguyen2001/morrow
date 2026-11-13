import Foundation

/// Local search over title, place name and body (T-005 step 5). Pure, no logging: the query is user text.
/// Matching goes through `TextMatching.key`, so "hoi an" finds "Hội An" and "da nang" finds "Đà Nẵng".
enum MemorySearch {
    /// Longest query kept (same size as the other short text fields).
    static let maxLength = 100

    /// The query without surrounding spaces and newlines; nil when nothing is left (no filtering then).
    static func normalized(_ query: String) -> String? {
        let trimmed = String(query.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func filter(_ memories: [Memory], query: String) -> [Memory] {
        guard let query = normalized(query) else { return memories }
        let folded = TextMatching.key(query)
        return memories.filter { memory in
            TextMatching.key(memory.title).contains(folded)
                || TextMatching.key(memory.placeName ?? "").contains(folded)
                || TextMatching.key(memory.body ?? "").contains(folded)
        }
    }
}
