import Foundation

/// Kinds of memory. `list` and `checkin` are planned and will be added here;
/// every `switch` over this enum is exhaustive so the compiler flags what to update.
enum MemoryKind: String, CaseIterable, Sendable {
    case photo
    case note
}

/// Pure domain value. No SwiftUI, no backend types.
struct Memory: Identifiable, Hashable, Sendable {
    let id: UUID
    var kind: MemoryKind
    var title: String
    /// Text body, used by notes.
    var body: String?
    var placeName: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: MemoryKind,
        title: String,
        body: String? = nil,
        placeName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.placeName = placeName
        self.createdAt = createdAt
    }
}
