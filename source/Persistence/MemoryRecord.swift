import Foundation
import SwiftData

/// SwiftData row. Persistence detail only: the rest of the app sees `Memory`.
@Model
final class MemoryRecord {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var title: String
    var body: String?
    var placeName: String?
    var photoFileName: String?
    var createdAt: Date
    var updatedAt: Date
    var isSoftDeleted: Bool

    init(_ memory: Memory, updatedAt: Date = Date()) {
        id = memory.id
        kindRaw = memory.kind.rawValue
        title = memory.title
        body = memory.body
        placeName = memory.placeName
        photoFileName = memory.photoFileName
        createdAt = memory.createdAt
        self.updatedAt = updatedAt
        isSoftDeleted = false
    }

    /// Nil when `kindRaw` is unknown (for example written by a newer app version).
    var memory: Memory? {
        guard let kind = MemoryKind(rawValue: kindRaw) else { return nil }
        return Memory(id: id, kind: kind, title: title, body: body, placeName: placeName,
                      photoFileName: photoFileName, createdAt: createdAt)
    }
}
