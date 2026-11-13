import XCTest
@testable import Morrow

final class MemorySearchTests: XCTestCase {
    private typealias Support = ProjectionTestSupport

    private let memories = [
        Support.memory(1, title: "Sunrise", body: "Coffee on the pier", place: "Hội An", at: Support.date(1)),
        Support.memory(2, title: "Lanterns", place: "Đà Nẵng", at: Support.date(2)),
        Support.memory(3, title: "Train to HUẾ", at: Support.date(3)),
        Support.memory(4, title: "Đức's birthday", place: "Da Lat", at: Support.date(4)),
    ]

    private func titles(_ query: String) -> [String] {
        MemorySearch.filter(memories, query: query).map(\.title)
    }

    func testEmptyAndWhitespaceQueryDoNotFilter() {
        XCTAssertEqual(titles("").count, 4)
        XCTAssertEqual(titles("   \n ").count, 4)
        XCTAssertNil(MemorySearch.normalized("  "))
    }

    func testMatchesIgnoringDiacriticsAndCase() {
        XCTAssertEqual(titles("hoi an"), ["Sunrise"])
        XCTAssertEqual(titles("HỘI AN"), ["Sunrise"])
        XCTAssertEqual(titles("hue"), ["Train to HUẾ"])
    }

    func testMatchesTitlePlaceAndBody() {
        XCTAssertEqual(titles("lantern"), ["Lanterns"])
        XCTAssertEqual(titles("pier"), ["Sunrise"])
        XCTAssertEqual(titles("nẵng"), ["Lanterns"])
    }

    func testVietnameseDMatchesBothWays() {
        XCTAssertEqual(titles("da nang"), ["Lanterns"])
        XCTAssertEqual(titles("đà"), ["Lanterns", "Đức's birthday"])
        XCTAssertEqual(titles("Đà Nẵng"), ["Lanterns"])
        XCTAssertEqual(titles("duc"), ["Đức's birthday"])
        XCTAssertEqual(titles("Đà Lạt"), ["Đức's birthday"])
    }

    func testQueryIsTrimmed() {
        XCTAssertEqual(titles("  pier  "), ["Sunrise"])
    }

    func testNoMatchGivesEmpty() {
        XCTAssertTrue(titles("zzz").isEmpty)
    }

    func testQueryIsLimited() {
        let long = String(repeating: "a", count: 500)
        XCTAssertEqual(MemorySearch.normalized(long)?.count, MemorySearch.maxLength)
    }
}
