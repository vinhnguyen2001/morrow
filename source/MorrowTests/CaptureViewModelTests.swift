import UIKit
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
        XCTAssertEqual(try repo.all().first?.title.count, Memory.Limits.title)
    }

    func testConcurrentSavesStoreOneMemory() async throws {
        let (model, repo) = try makeModel()
        model.kind = .photo
        model.title = "Once"
        let image = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50)).jpegData(withCompressionQuality: 1) { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }
        await model.setPhoto(image)
        async let first = model.save()
        async let second = model.save()
        let results = await [first, second]
        XCTAssertEqual(results.filter { $0 }.count, 1)
        XCTAssertEqual(try repo.all().count, 1)
    }

    func testCorruptPhotoIsRejectedWithMessage() async throws {
        let (model, _) = try makeModel()
        await model.setPhoto(Data("junk".utf8))
        XCTAssertNil(model.photoData)
        XCTAssertNotNil(model.errorMessage)
    }

    func testCancelledEarlierPickDoesNotOverwriteLaterPick() async throws {
        let (model, _) = try makeModel()
        func jpeg(side: CGFloat, color: UIColor) -> Data {
            UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).jpegData(withCompressionQuality: 1) { ctx in
                color.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }
        let first = jpeg(side: 40, color: .red)
        let second = jpeg(side: 60, color: .blue)
        let firstTask = Task { await model.setPhoto(first) }
        firstTask.cancel()
        await firstTask.value
        XCTAssertNil(model.photoData)
        await model.setPhoto(second)
        XCTAssertEqual(model.photoData, second)
    }

    func testCancelledCorruptPickSetsNoErrorMessage() async throws {
        let (model, _) = try makeModel()
        let task = Task { await model.setPhoto(Data("junk".utf8)) }
        task.cancel()
        await task.value
        XCTAssertNil(model.photoData)
        XCTAssertNil(model.errorMessage)
    }
}
