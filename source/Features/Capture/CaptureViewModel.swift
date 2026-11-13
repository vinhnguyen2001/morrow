import Foundation
import Observation

/// Where location lookup stands. Save never waits for it.
enum LocationState: Equatable, Sendable {
    case idle
    case locating
    case located
    case unavailable
}

@MainActor
@Observable
final class CaptureViewModel {
    var kind: MemoryKind = .photo
    var title = ""
    var body = ""
    var placeName = ""
    private(set) var photoData: Data?
    private(set) var photoPreview: Data?
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    /// Where the memory is pinned. Nil until a fix arrives, and again after `clearLocation()`.
    private(set) var coordinate: Coordinate?
    private(set) var locationState: LocationState = .idle
    private(set) var authorization: LocationAuthorization
    /// True while the place name is being looked up (the sheet shows a placeholder, not a spinner).
    private(set) var isFindingPlace = false
    /// Once the user types in Place, a late suggestion must never replace it.
    private(set) var placeEditedByUser = false

    private let repository: MemoryRepository
    private let photoStore: PhotoStore
    private let locationProvider: LocationProviding
    private let placeNamer: PlaceNaming
    private var locatingTask: Task<Void, Never>?
    /// Set by Save and by removing the location: later results are ignored and nothing restarts.
    private var locationClosed = false
    private var suggestedPlaceName: String?

    init(
        repository: MemoryRepository,
        photoStore: PhotoStore,
        locationProvider: LocationProviding = NoLocationProvider(),
        placeNamer: PlaceNaming = NoPlaceNamer()
    ) {
        self.repository = repository
        self.photoStore = photoStore
        self.locationProvider = locationProvider
        self.placeNamer = placeNamer
        authorization = locationProvider.authorization
    }

    /// Settings can fix "denied"; "restricted" cannot be changed by the user, so no link then.
    var offersSettingsLink: Bool { locationState == .unavailable && authorization == .denied }

    /// Called from the sheet's `.task`. Cancelled with the sheet; Save and `clearLocation()` cancel it too.
    func startLocating() async {
        guard let task = beginLocating() else { return }
        await withTaskCancellationHandler { await task.value } onCancel: { task.cancel() }
    }

    /// Sets `.locating` synchronously, before the Task exists, so a second call sees it and starts nothing.
    private func beginLocating() -> Task<Void, Never>? {
        guard locationState == .idle, !locationClosed else { return nil }
        locationState = .locating
        let task = Task { await locate() }
        locatingTask = task
        return task
    }

    /// The sheet went away: stop looking. Does not change what Save means.
    func cancelLocating() { stopLocating() }

    /// The user may have changed the permission in Settings while the sheet was open.
    func recheckAuthorization() async {
        authorization = locationProvider.authorization
        guard locationState == .unavailable, authorization == .authorized, !locationClosed else { return }
        locationState = .idle
        await startLocating()
    }

    /// The user removed the location: drop the pin and any name we suggested, and stop looking.
    func clearLocation() {
        stopLocating()
        coordinate = nil
        locationState = .idle
        if !placeEditedByUser, let suggested = suggestedPlaceName, placeName == suggested { placeName = "" }
        suggestedPlaceName = nil
    }

    /// For the Place field: marks the text as the user's own.
    func setPlaceName(byUser text: String) {
        placeName = text
        placeEditedByUser = true
    }

    /// A cancelled search must not leave the state at `.locating`, so it goes back to `.idle`.
    private func stopLocating() {
        locationClosed = true
        isFindingPlace = false
        if locationState == .locating { locationState = .idle }
        locatingTask?.cancel()
        locatingTask = nil
    }

    private func locate() async {
        guard isCurrent else { return }
        authorization = locationProvider.authorization
        if authorization == .notDetermined {
            await locationProvider.requestWhenInUse()
            guard isCurrent else { return }
            authorization = locationProvider.authorization
        }
        guard authorization == .authorized else { locationState = .unavailable; return }
        let fix = await locationProvider.currentCoordinate()
        guard isCurrent else { return }
        guard let fix else { locationState = .unavailable; return }
        coordinate = fix
        locationState = .located

        isFindingPlace = true
        let name = await placeNamer.placeName(for: fix)
        guard isCurrent else { return }
        isFindingPlace = false
        if let name = Self.optional(name ?? "", max: Memory.Limits.place), !placeEditedByUser, Self.clean(placeName).isEmpty {
            suggestedPlaceName = name
            placeName = name
        }
    }

    /// False once cancelled, saved or cleared: a result that arrives then is dropped.
    private var isCurrent: Bool { !Task.isCancelled && !locationClosed }

    var canSave: Bool {
        !Self.clean(title).isEmpty && (kind != .photo || photoData != nil) && !isSaving
    }

    func setPhoto(_ data: Data?) async {
        guard let data else { photoData = nil; photoPreview = nil; return }
        let store = photoStore
        do {
            let preview = try await Task.detached { try store.previewData(from: data) }.value
            // Task.detached does not inherit cancellation: a newer pick must not be overwritten.
            guard !Task.isCancelled else { return }
            photoData = data
            photoPreview = preview
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            photoData = nil
            photoPreview = nil
            errorMessage = "That photo can't be used. Try another one."
        }
    }

    /// Saves locally and returns true on success. Photo encoding runs off the main actor.
    func save() async -> Bool {
        guard canSave else { return false }
        // Save never waits for the location; whatever arrived is kept, the rest is dropped.
        let wasLocating = locationState == .locating
        stopLocating()
        isSaving = true
        defer { isSaving = false }

        let id = UUID()
        var fileName: String?
        do {
            if kind == .photo, let data = photoData {
                let store = photoStore
                fileName = try await Task.detached { try store.save(imageData: data, id: id) }.value
            }
            let memory = Memory(
                id: id, kind: kind,
                title: String(Self.clean(title).prefix(Memory.Limits.title)),
                body: kind == .note ? Self.optional(body, max: Memory.Limits.body) : nil,
                placeName: Self.optional(placeName, max: Memory.Limits.place),
                coordinate: coordinate,
                photoFileName: fileName)
            try repository.add(memory)
            return true
        } catch {
            if let fileName { photoStore.remove(fileName: fileName) }
            errorMessage = "Couldn't save. Please try again."
            // The sheet stays open, so reopen the search (smallest fix: only a search that Save cut short).
            locationClosed = false
            if wasLocating { _ = beginLocating() }
            return false
        }
    }

    static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func optional(_ text: String, max: Int) -> String? {
        let cleaned = clean(text)
        return cleaned.isEmpty ? nil : String(cleaned.prefix(max))
    }
}
