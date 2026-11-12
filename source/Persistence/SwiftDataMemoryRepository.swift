import Foundation
import SwiftData

@MainActor
final class SwiftDataMemoryRepository: MemoryRepository {
    /// Held on purpose: a `ModelContext` traps if its container has been released.
    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = inMemory
            ? ModelConfiguration(isStoredInMemoryOnly: true)
            : ModelConfiguration(url: try StoreLocation.prepare())
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
        record.scrub()
        try context.save()
    }
}
