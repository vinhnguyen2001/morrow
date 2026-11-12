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

    func makeCapture() -> CaptureViewModel {
        CaptureViewModel(repository: repository, photoStore: photoStore)
    }

    /// Soft delete first (optimistic UI), then remove the photo files off the main actor.
    func delete(_ memory: Memory) async {
        do {
            try repository.delete(id: memory.id)
            memories.removeAll { $0.id == memory.id }
        } catch {
            errorMessage = "Couldn't delete that memory."
            return
        }
        if let fileName = memory.photoFileName {
            let store = photoStore
            await Task.detached { store.remove(fileName: fileName) }.value
        }
    }
}
