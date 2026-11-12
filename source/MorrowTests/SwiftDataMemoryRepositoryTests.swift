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
                            coordinate: Coordinate(latitude: 1, longitude: 2), photoFileName: "x.jpg")
        try repo.add(memory)
        let id = memory.id
        let before = try XCTUnwrap(try repo.container.mainContext.fetch(
            FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id })).first).updatedAt
        XCTAssertNotNil(try XCTUnwrap(try repo.container.mainContext.fetch(
            FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id })).first).latitude)
        try repo.delete(id: memory.id)

        let records = try repo.container.mainContext.fetch(
            FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id }))
        let record = try XCTUnwrap(records.first)
        XCTAssertTrue(record.isSoftDeleted)
        XCTAssertEqual(record.id, memory.id)
        XCTAssertGreaterThan(record.updatedAt, before)
        XCTAssertEqual(record.title, "")
        XCTAssertNil(record.body)
        XCTAssertNil(record.placeName)
        XCTAssertNil(record.photoFileName)
        XCTAssertNil(record.latitude)
        XCTAssertNil(record.longitude)
    }

    func testCoordinateRoundTripsThroughAddAndAll() throws {
        let repo = try makeRepository()
        let coordinate = try XCTUnwrap(Coordinate(latitude: 16.05, longitude: 108.2))
        try repo.add(Memory(kind: .note, title: "Pinned", coordinate: coordinate))
        try repo.add(Memory(kind: .note, title: "Unpinned"))
        let all = try repo.all()
        XCTAssertEqual(all.first { $0.title == "Pinned" }?.coordinate, coordinate)
        XCTAssertNil(all.first { $0.title == "Unpinned" }?.coordinate)
    }

    func testRecordWithOnlyLatitudeHasNoCoordinate() throws {
        let record = MemoryRecord(Memory(kind: .note, title: "Half"))
        record.latitude = 10
        XCTAssertNil(record.memory?.coordinate)
        XCTAssertNotNil(record.memory)
    }

    func testRecordWithInvalidStoredValuesHasNoCoordinate() throws {
        let record = MemoryRecord(Memory(kind: .note, title: "Bad"))
        record.latitude = 999
        record.longitude = 10
        XCTAssertNil(record.memory?.coordinate)
    }

    func testSoftDeleteScrubsCoordinate() throws {
        let repo = try makeRepository()
        let memory = Memory(kind: .note, title: "Pinned", coordinate: Coordinate(latitude: 1, longitude: 2))
        try repo.add(memory)
        try repo.delete(id: memory.id)
        let id = memory.id
        let record = try XCTUnwrap(try repo.container.mainContext.fetch(
            FetchDescriptor<MemoryRecord>(predicate: #Predicate { $0.id == id })).first)
        XCTAssertNil(record.latitude)
        XCTAssertNil(record.longitude)
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
