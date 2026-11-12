import XCTest
@testable import Morrow

final class CoordinateTests: XCTestCase {
    func testAcceptsValidAndBoundaryValues() {
        XCTAssertNotNil(Coordinate(latitude: 0, longitude: 0))
        XCTAssertNotNil(Coordinate(latitude: 90, longitude: 180))
        XCTAssertNotNil(Coordinate(latitude: -90, longitude: -180))
    }

    func testRejectsOutOfRangeAndNonFinite() {
        XCTAssertNil(Coordinate(latitude: 90.0001, longitude: 0))
        XCTAssertNil(Coordinate(latitude: 0, longitude: -180.5))
        XCTAssertNil(Coordinate(latitude: .nan, longitude: 0))
        XCTAssertNil(Coordinate(latitude: 0, longitude: .infinity))
    }

    func testDescriptionsAreRedacted() throws {
        let coordinate = try XCTUnwrap(Coordinate(latitude: 16.0544, longitude: 108.2022))
        for text in [coordinate.description, coordinate.debugDescription, "\(coordinate)", String(describing: coordinate)] {
            XCTAssertFalse(text.contains("16.05"))
            XCTAssertFalse(text.contains("108.20"))
        }
    }

    func testEqualityAndHashing() throws {
        let a = try XCTUnwrap(Coordinate(latitude: 1, longitude: 2))
        let b = try XCTUnwrap(Coordinate(latitude: 1, longitude: 2))
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set([a, b]).count, 1)
    }
}
