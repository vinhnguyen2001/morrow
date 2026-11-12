import Foundation

/// UI-side access to memories (ADR 0001). The UI never touches SwiftData or a backend SDK.
/// Main-actor because the SwiftData implementation uses the main `ModelContext`.
@MainActor
protocol MemoryRepository {
    /// Live (not deleted) memories, newest first.
    func all() throws -> [Memory]
    func add(_ memory: Memory) throws
    /// Soft delete (ADR 0001): the row stays so a future sync can propagate the deletion.
    func delete(id: UUID) throws
}
