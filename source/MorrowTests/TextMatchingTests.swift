import XCTest
@testable import Morrow

final class TextMatchingTests: XCTestCase {
    func testVietnameseDIsFolded() {
        XCTAssertEqual(TextMatching.key("Đà Nẵng"), "da nang")
        XCTAssertEqual(TextMatching.key("da nang"), "da nang")
        XCTAssertEqual(TextMatching.key("ĐÀ NẴNG"), "da nang")
        XCTAssertEqual(TextMatching.key("Đ"), "d")
        XCTAssertEqual(TextMatching.key("đ"), "d")
    }

    func testOtherVietnameseLettersFold() {
        XCTAssertEqual(TextMatching.key("Hương"), "huong")
        XCTAssertEqual(TextMatching.key("Thu Bồn"), "thu bon")
        XCTAssertEqual(TextMatching.key("Lăng Cô"), "lang co")
    }

    func testNFCAndNFDGiveTheSameKey() {
        XCTAssertEqual(TextMatching.key("Hội An"), TextMatching.key("Ho\u{0323}\u{302}i An"))
        XCTAssertEqual(TextMatching.key("Ho\u{0323}\u{302}i An"), "hoi an")
    }

    func testTrimsAndHandlesBlank() {
        XCTAssertEqual(TextMatching.key("  Huế \n"), "hue")
        XCTAssertEqual(TextMatching.key(""), "")
        XCTAssertEqual(TextMatching.key("  \n "), "")
    }
}
