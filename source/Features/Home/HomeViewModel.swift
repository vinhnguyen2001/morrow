import Foundation
import Observation
import os

@MainActor
@Observable
final class HomeViewModel {
    private(set) var memories: [Memory] = []
    /// Rows for the timeline, computed once per load (never in `body`).
    private(set) var timeline: Timeline = .empty
    /// Notes tab tiles, computed once per load.
    private(set) var noteCards: TwoColumns<NoteCard> = .empty
    /// Places tab tiles, computed once per load.
    private(set) var placeCards: TwoColumns<PlaceCard> = .empty
    /// What the user typed in the search box. Never logged.
    private(set) var searchQuery = ""
    private(set) var errorMessage: String?
    /// False until the first load finishes, so the empty state does not flash before local data arrives.
    private(set) var hasLoaded = false

    let repository: MemoryRepository
    let photoStore: PhotoStore
    /// `memories` that match `searchQuery`; every tab is built from this.
    private var visibleMemories: [Memory] = []
    private let locationProvider: LocationProviding
    private let placeNamer: PlaceNaming
    /// Also used by Detail to format dates in the same calendar and time zone as the timeline.
    let calendar: Calendar
    private let now: () -> Date
    private let signposter = OSSignposter(subsystem: "com.morrow.app", category: "home")

    /// `calendar` and `now` are injectable so day grouping and "Today" are testable.
    init(
        repository: MemoryRepository,
        photoStore: PhotoStore,
        locationProvider: LocationProviding = NoLocationProvider(),
        placeNamer: PlaceNaming = NoPlaceNamer(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.photoStore = photoStore
        self.locationProvider = locationProvider
        self.placeNamer = placeNamer
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
        rebuild()
        if !hasLoaded { hasLoaded = true }
    }

    /// The query when it has text, else nil (no filter). The tabs use it for the "no match" message.
    var activeQuery: String? { MemorySearch.normalized(searchQuery) }

    /// Filters every tab. Typing re-filters here, never in `body`; when the matches are the same as before
    /// (another letter that excludes nothing more) nothing is rebuilt.
    func setSearchQuery(_ query: String) {
        let limited = String(query.prefix(MemorySearch.maxLength))
        guard limited != searchQuery else { return }
        searchQuery = limited
        // Timing only: the query text is never part of the signpost.
        let interval = signposter.beginInterval("search rebuild")
        defer { signposter.endInterval("search rebuild", interval) }
        let matches = MemorySearch.filter(memories, query: limited)
        guard matches != visibleMemories else { return }
        rebuild(showing: matches)
    }

    /// Recomputes every tab's projection from the memories that match the search.
    /// Each assignment is guarded so a tab only re-renders when its own data changed (e.g. not on scene activation).
    private func rebuild() {
        rebuild(showing: MemorySearch.filter(memories, query: searchQuery))
    }

    private func rebuild(showing memories: [Memory]) {
        let current = now()
        if memories != visibleMemories { visibleMemories = memories }
        let timeline = TimelineBuilder.build(memories: memories, calendar: calendar, now: current)
        if timeline != self.timeline { self.timeline = timeline }
        let noteCards = NoteCards.build(memories: memories, calendar: calendar, now: current)
        if noteCards != self.noteCards { self.noteCards = noteCards }
        let placeCards = PlaceGrouping.build(memories: memories, calendar: calendar, now: current)
        if placeCards != self.placeCards { self.placeCards = placeCards }
    }

    /// Current state of one memory, or nil once it is deleted. Detail looks itself up here (ADR 0009), so it is never stale.
    func memory(id: UUID) -> Memory? {
        memories.first { $0.id == id }
    }

    /// Dismisses the current error, e.g. when the user navigates on, so it does not show on another screen.
    func clearError() {
        if errorMessage != nil { errorMessage = nil }
    }

    func makeCapture(initialKind: MemoryKind = .photo) -> CaptureViewModel {
        CaptureViewModel(repository: repository, photoStore: photoStore,
                         locationProvider: locationProvider, placeNamer: placeNamer, initialKind: initialKind)
    }

    /// Soft delete first (optimistic UI), then remove the photo files off the main actor.
    func delete(_ memory: Memory) async {
        clearError() // an older failure must not outlive this attempt
        do {
            try repository.delete(id: memory.id)
            memories.removeAll { $0.id == memory.id }
            rebuild()
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
