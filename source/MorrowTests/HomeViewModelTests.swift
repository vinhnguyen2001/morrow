import UIKit
import XCTest
@testable import Morrow

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testDeleteRemovesEntryAndPhotoFiles() async throws {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = PhotoStore(directory: dir)

        let id = UUID()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80)).jpegData(withCompressionQuality: 1) { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        }
        let fileName = try store.save(imageData: image, id: id)
        let memory = Memory(id: id, kind: .photo, title: "Bye", photoFileName: fileName)
        try repo.add(memory)

        let model = HomeViewModel(repository: repo, photoStore: store)
        model.load()
        XCTAssertEqual(model.memories.count, 1)

        await model.delete(memory)
        XCTAssertTrue(model.memories.isEmpty)
        XCTAssertTrue(try repo.all().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appending(path: fileName).path))
        XCTAssertNil(store.thumbnailData(for: fileName))
    }

    func testLoadBuildsTimelineWithInjectedCalendarAndNow() throws {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let now = Date(timeIntervalSince1970: 1_794_490_200)
        try repo.add(Memory(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000001")!, kind: .note, title: "Hi", createdAt: now))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt
        calendar.locale = Locale(identifier: "en_GB")
        let model = HomeViewModel(
            repository: repo, photoStore: PhotoStore(directory: FileManager.default.temporaryDirectory),
            calendar: calendar, now: { now }
        )
        XCTAssertFalse(model.hasLoaded)
        model.load()
        XCTAssertTrue(model.hasLoaded)
        XCTAssertEqual(model.timeline.rows.map(\.id), [
            "sprout", "day-2026-11-12", "m-B0000000-0000-0000-0000-000000000001", "origin",
        ])
    }

    func testLoadBuildsNoteCardsAndDeleteUpdatesThem() async throws {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let note = Memory(kind: .note, title: "A note")
        try repo.add(note)
        try repo.add(Memory(kind: .photo, title: "A photo"))
        let model = HomeViewModel(repository: repo, photoStore: PhotoStore(directory: FileManager.default.temporaryDirectory))
        model.load()
        XCTAssertEqual(model.noteCards.all.map(\.title), ["A note"])
        XCTAssertTrue(model.placeCards.isEmpty) // no place names
        await model.delete(note)
        XCTAssertTrue(model.noteCards.isEmpty)
    }

    func testLookupByIdReturnsMemoryThenNilAfterDelete() async throws {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let memory = Memory(kind: .note, title: "Gone soon")
        try repo.add(memory)
        let model = HomeViewModel(repository: repo, photoStore: PhotoStore(directory: FileManager.default.temporaryDirectory))
        model.load()
        XCTAssertEqual(model.memory(id: memory.id)?.title, "Gone soon")
        XCTAssertNil(model.memory(id: UUID()))

        await model.delete(memory)
        XCTAssertNil(model.memory(id: memory.id))
    }
}
