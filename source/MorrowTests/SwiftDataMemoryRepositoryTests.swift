import SwiftData
import XCTest
@testable import Morrow

@MainActor
final class SwiftDataMemoryRepositoryTests: XCTestCase {
    private func makeRepository() throws -> SwiftDataMemoryRepository {
        SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
    }

    func testAddThenAllRoundTripsFields() throws {
        let repo = try makeRepository()
        let memory = Memory(kind: .note, title: "Coffee", body: "Salted", placeName: "Da Nang",
                            photoFileName: nil, createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        try repo.add(memory)
        XCTAssertEqual(try repo.all(), [memory])
    }

    func testAllIsNewestFirst() throws {
        let repo = try makeRepository()
        let old = Memory(kind: .note, title: "Old", createdAt: Date(timeIntervalSince1970: 100))
        let new = Memory(kind: .note, title: "New", createdAt: Date(timeIntervalSince1970: 200))
        try repo.add(old)
        try repo.add(new)
        XCTAssertEqual(try repo.all().map(\.title), ["New", "Old"])
    }

    func testDeleteIsSoftAndHidesFromAll() throws {
        let repo = try makeRepository()
        let memory = Memory(kind: .photo, title: "Gone")
        try repo.add(memory)
        try repo.delete(id: memory.id)
        XCTAssertTrue(try repo.all().isEmpty)
    }

    func testDeleteUnknownIDIsNoOp() throws {
        let repo = try makeRepository()
        XCTAssertNoThrow(try repo.delete(id: UUID()))
    }

    func testSoftDeleteScrubsContentAndKeepsTombstone() throws {
        let repo = try makeRepository()
        let memory = Memory(kind: .photo, title: "Secret", body: "Private text", placeName: "Home",
                            photoFileName: "x.jpg")
        try repo.add(memory)
        try repo.delete(id: memory.id)

        let id = memory.id
        let records = try repo.container.mainContext.fetch(
            FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id }))
        let record = try XCTUnwrap(records.first)
        XCTAssertTrue(record.isSoftDeleted)
        XCTAssertEqual(record.title, "")
        XCTAssertNil(record.body)
        XCTAssertNil(record.placeName)
        XCTAssertNil(record.photoFileName)
    }

    func testUnknownKindIsFilteredFromAll() throws {
        let repo = try makeRepository()
        try repo.add(Memory(kind: .note, title: "Known"))
        let future = MemoryRecord(Memory(kind: .note, title: "From the future"))
        future.kindRaw = "hologram"
        repo.container.mainContext.insert(future)
        try repo.container.mainContext.save()
        XCTAssertEqual(try repo.all().map(\.title), ["Known"])
    }
}
