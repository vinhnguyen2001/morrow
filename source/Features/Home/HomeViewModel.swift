import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var memories: [Memory] = []
    private(set) var errorMessage: String?

    let repository: MemoryRepository
    let photoStore: PhotoStore

    init(repository: MemoryRepository, photoStore: PhotoStore) {
        self.repository = repository
        self.photoStore = photoStore
    }

    func load() {
        do {
            memories = try repository.all()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your memories."
        }
    }

    func delete(_ memory: Memory) {
        do {
            try repository.delete(id: memory.id)
            if let fileName = memory.photoFileName { photoStore.remove(fileName: fileName) }
            memories.removeAll { $0.id == memory.id }
        } catch {
            errorMessage = "Couldn't delete that memory."
        }
    }
}
