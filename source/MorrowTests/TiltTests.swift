import XCTest
@testable import Morrow

final class TiltTests: XCTestCase {
    // Fixed inputs only: the sample IDs plus two arbitrary literals.
    private let fixedIDs: [UUID] = Memory.samples.map(\.id) + [
        UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")!,
        UUID(uuidString: "F47AC10B-58CC-4372-A567-0E02B2C3D479")!,
    ]

    func testFNV1aMatchesPublishedVectors() {
        XCTAssertEqual(Tilt.fnv1a([UInt8]()), 0xcbf2_9ce4_8422_2325)
        XCTAssertEqual(Tilt.fnv1a([UInt8(0x61)]), 0xaf63_dc4c_8601_ec8c)
    }

    func testSameIDGivesSameAngle() {
        for id in fixedIDs {
            XCTAssertEqual(Tilt.degrees(for: id), Tilt.degrees(for: id))
        }
    }

    func testAngleStaysWithinBounds() {
        for id in fixedIDs {
            XCTAssertLessThanOrEqual(abs(Tilt.degrees(for: id, maxDegrees: 2)), 2)
        }
    }

    func testFixedIDsProduceMoreThanOneAngle() {
        let angles = Set(fixedIDs.map { Tilt.degrees(for: $0) })
        XCTAssertGreaterThan(angles.count, 1)
    }
}
