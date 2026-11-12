import Foundation
import SwiftData

@MainActor
final class SwiftDataMemoryRepository: MemoryRepository {
    /// Held on purpose: a `ModelContext` traps if its container has been released.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if !inMemory {
            // A fresh install has no Application Support folder yet; without it CoreData
            // logs "Failed to stat path default.store" errors on first launch.
            try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        }
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: MemoryRecord.self, configurations: config)
    }

    func all() throws -> [Memory] {
        let descriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.isSoftDeleted == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap(\.memory)
    }

    func add(_ memory: Memory) throws {
        context.insert(MemoryRecord(memory))
        try context.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        record.isSoftDeleted = true
        record.updatedAt = Date()
        try context.save()
    }
}
