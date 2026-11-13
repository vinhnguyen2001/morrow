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
    /// Also used by Detail to format dates in the same calendar and time zone as the timeline.
    let calendar: Calendar
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
            // iOS 17 @Observable notifies on every assignment, even of an equal value, so guard each one.
            let loaded = try repository.all()
            if loaded != memories { memories = loaded }
            if errorMessage != nil { errorMessage = nil }
        } catch {
            errorMessage = "Couldn't load your memories."
        }
        rebuildTimeline()
        if !hasLoaded { hasLoaded = true }
    }

    private func rebuildTimeline() {
        let rebuilt = TimelineBuilder.build(memories: memories, calendar: calendar, now: now())
        if rebuilt != timeline { timeline = rebuilt } // no needless re-render on scene activation
    }

    /// Current state of one memory, or nil once it is deleted. Detail looks itself up here (ADR 0009), so it is never stale.
    func memory(id: UUID) -> Memory? {
        memories.first { $0.id == id }
    }

    /// Dismisses the current error, e.g. when the user navigates on, so it does not show on another screen.
    func clearError() {
        if errorMessage != nil { errorMessage = nil }
    }

    func makeCapture() -> CaptureViewModel {
        CaptureViewModel(repository: repository, photoStore: photoStore)
    }

    /// Soft delete first (optimistic UI), then remove the photo files off the main actor.
    func delete(_ memory: Memory) async {
        clearError() // an older failure must not outlive this attempt
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
            ThumbnailCache.shared.remove(fileName: fileName)
            await Task.detached { store.remove(fileName: fileName) }.value
        }
    }
}
