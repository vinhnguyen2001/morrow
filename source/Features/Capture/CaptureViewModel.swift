import Foundation
import Observation

@MainActor
@Observable
final class CaptureViewModel {
    static let maxTitle = 100
    static let maxBody = 2000
    static let maxPlace = 100

    var kind: MemoryKind = .photo
    var title = ""
    var body = ""
    var placeName = ""
    private(set) var photoData: Data?
    private(set) var photoPreview: Data?
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let repository: MemoryRepository
    private let photoStore: PhotoStore

    init(repository: MemoryRepository, photoStore: PhotoStore) {
        self.repository = repository
        self.photoStore = photoStore
    }

    var canSave: Bool {
        !Self.clean(title).isEmpty && (kind != .photo || photoData != nil) && !isSaving
    }

    func setPhoto(_ data: Data?) async {
        guard let data else { photoData = nil; photoPreview = nil; return }
        let store = photoStore
        do {
            let preview = try await Task.detached { try store.previewData(from: data) }.value
            photoData = data
            photoPreview = preview
            errorMessage = nil
        } catch {
            photoData = nil
            photoPreview = nil
            errorMessage = "That photo can't be used. Try another one."
        }
    }

    /// Saves locally and returns true on success. Photo encoding runs off the main actor.
    func save() async -> Bool {
        guard canSave else { return false }
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
                title: String(Self.clean(title).prefix(Self.maxTitle)),
                body: kind == .note ? Self.optional(body, max: Self.maxBody) : nil,
                placeName: Self.optional(placeName, max: Self.maxPlace),
                photoFileName: fileName)
            try repository.add(memory)
            return true
        } catch {
            if let fileName { photoStore.remove(fileName: fileName) }
            errorMessage = "Couldn't save. Please try again."
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
