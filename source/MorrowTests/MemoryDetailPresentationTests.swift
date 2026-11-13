import XCTest
@testable import Morrow

final class MemoryDetailPresentationTests: XCTestCase {
    private func calendar(zone: String, locale: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        calendar.locale = Locale(identifier: locale)
        return calendar
    }

    // 2026-11-12 13:30 UTC = 20:30 in Ho Chi Minh City.
    private let moment = Date(timeIntervalSince1970: 1_794_490_200)

    func testDateFollowsInjectedTimeZoneAndLocale() {
        let memory = Memory(kind: .note, title: "t", createdAt: moment)
        let hcm = MemoryDetailPresentation.dateText(for: memory, calendar: calendar(zone: "Asia/Ho_Chi_Minh", locale: "en_US"))
        XCTAssertTrue(hcm.contains("November 12, 2026"), hcm)
        XCTAssertTrue(hcm.contains("8:30"), hcm)
        let utc = MemoryDetailPresentation.dateText(for: memory, calendar: calendar(zone: "UTC", locale: "en_US"))
        XCTAssertTrue(utc.contains("1:30"), utc)
        let french = MemoryDetailPresentation.dateText(for: memory, calendar: calendar(zone: "UTC", locale: "fr_FR"))
        XCTAssertTrue(french.contains("novembre"), french)
    }

    func testPlaceAndBodyAreNilWhenBlank() {
        let blank = Memory(kind: .note, title: "t", body: " \n", placeName: "  ")
        XCTAssertNil(MemoryDetailPresentation.placeText(for: blank))
        XCTAssertNil(MemoryDetailPresentation.bodyText(for: blank))
        let filled = Memory(kind: .note, title: "t", body: " text ", placeName: " Hội An ")
        XCTAssertEqual(MemoryDetailPresentation.placeText(for: filled), "Hội An")
        XCTAssertEqual(MemoryDetailPresentation.bodyText(for: filled), "text")
    }

    func testKickerPerKind() {
        XCTAssertEqual(MemoryDetailPresentation.kicker(for: .note), "a note")
        XCTAssertEqual(MemoryDetailPresentation.kicker(for: .photo), "a photo")
    }
}
