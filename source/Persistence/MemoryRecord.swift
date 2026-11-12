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
    /// Both set or both nil. Optional columns migrate automatically (ADR 0008).
    var latitude: Double?
    var longitude: Double?
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
        latitude = memory.coordinate?.latitude
        longitude = memory.coordinate?.longitude
        photoFileName = memory.photoFileName
        createdAt = memory.createdAt
        self.updatedAt = updatedAt
        isSoftDeleted = false
    }

    /// Soft delete: drop all personal content, keep only the tombstone (id, updatedAt, isSoftDeleted).
    func scrub() {
        title = ""
        body = nil
        placeName = nil
        latitude = nil
        longitude = nil
        photoFileName = nil
        isSoftDeleted = true
        updatedAt = Date()
    }

    /// Nil when `kindRaw` is unknown (for example written by a newer app version).
    var memory: Memory? {
        guard let kind = MemoryKind(rawValue: kindRaw) else { return nil }
        // A half-written pair or an invalid value means no coordinate, never a crash.
        let coordinate = latitude.flatMap { lat in
            longitude.flatMap { Coordinate(latitude: lat, longitude: $0) }
        }
        return Memory(id: id, kind: kind, title: title, body: body, placeName: placeName,
                      coordinate: coordinate, photoFileName: photoFileName, createdAt: createdAt)
    }
}
