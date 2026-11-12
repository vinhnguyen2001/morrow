import Foundation
import Observation
import os

@MainActor
@Observable
final class HomeViewModel {
    private(set) var memories: [Memory] = []
    /// Rows for the timeline, computed once per load (never in `body`).
    private(set) var timeline: Timeline = .empty
    private(set) var errorMessage: String?
    /// False until the first load finishes, so the empty state does not flash before local data arrives.
    private(set) var hasLoaded = false

    let repository: MemoryRepository
    let photoStore: PhotoStore
    private let calendar: Calendar
    private let now: () -> Date
    private let signposter = OSSignposter(subsystem: "com.morrow.app", category: "home")

    /// `calendar` and `now` are injectable so day grouping and "Today" are testable.
    init(
        repository: MemoryRepository,
        photoStore: PhotoStore,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.photoStore = photoStore
        self.calendar = calendar
        self.now = now
    }

    func load() {
        let interval = signposter.beginInterval("load memories")
        defer { signposter.endInterval("load memories", interval) }
        do {
            memories = try repository.all()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your memories."
        }
        rebuildTimeline()
        hasLoaded = true
    }

    private func rebuildTimeline() {
        timeline = TimelineBuilder.build(memories: memories, calendar: calendar, now: now())
    }

    func makeCapture() -> CaptureViewModel {
        CaptureViewModel(repository: repository, photoStore: photoStore)
    }

    /// Soft delete first (optimistic UI), then remove the photo files off the main actor.
    func delete(_ memory: Memory) async {
        do {
            try repository.delete(id: memory.id)
            memories.removeAll { $0.id == memory.id }
            rebuildTimeline()
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
