import XCTest
@testable import Morrow

@MainActor
final class CaptureViewModelTests: XCTestCase {
    private func makeModel() throws -> (CaptureViewModel, SwiftDataMemoryRepository) {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        return (CaptureViewModel(repository: repo, photoStore: PhotoStore(directory: dir)), repo)
    }

    func testNoteNeedsOnlyATitle() throws {
        let (model, _) = try makeModel()
        model.kind = .note
        XCTAssertFalse(model.canSave)
        model.title = "  Hello  "
        XCTAssertTrue(model.canSave)
    }

    func testPhotoKindNeedsAPhoto() throws {
        let (model, _) = try makeModel()
        model.kind = .photo
        model.title = "Sunset"
        XCTAssertFalse(model.canSave)
    }

    func testSaveNoteTrimsAndStores() async throws {
        let (model, repo) = try makeModel()
        model.kind = .note
        model.title = "  Coffee  "
        model.body = "  Salted  "
        model.placeName = "   "
        let ok = await model.save()
        XCTAssertTrue(ok)
        let saved = try XCTUnwrap(repo.all().first)
        XCTAssertEqual(saved.title, "Coffee")
        XCTAssertEqual(saved.body, "Salted")
        XCTAssertNil(saved.placeName)
    }

    func testTitleIsCapped() async throws {
        let (model, repo) = try makeModel()
        model.kind = .note
        model.title = String(repeating: "a", count: 500)
        _ = await model.save()
        XCTAssertEqual(try repo.all().first?.title.count, CaptureViewModel.maxTitle)
    }
}
