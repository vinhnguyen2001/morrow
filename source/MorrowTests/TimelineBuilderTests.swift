import XCTest
@testable import Morrow

final class TimelineBuilderTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt // UTC+7, no daylight saving
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 11, year: Int = 2026) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: parts) ?? .distantPast
    }

    private func memory(_ n: Int, at when: Date, kind: MemoryKind = .note) -> Memory {
        Memory(id: UUID(uuidString: String(format: "A0000000-0000-0000-0000-%012d", n))!,
               kind: kind, title: "Memory \(n)", createdAt: when)
    }

    private func build(_ memories: [Memory], now: Date? = nil) -> Timeline {
        TimelineBuilder.build(memories: memories, calendar: calendar, now: now ?? date(12, 20))
    }

    private func items(_ timeline: Timeline) -> [TimelineItem] {
        timeline.rows.compactMap { if case .memory(let item) = $0 { return item } else { return nil } }
    }

    private func days(_ timeline: Timeline) -> [DayHeader] {
        timeline.rows.compactMap { if case .day(let day) = $0 { return day } else { return nil } }
    }

    func testEmptyGivesNoRows() {
        XCTAssertEqual(build([]), .empty)
        XCTAssertNil(build([]).sinceText)
    }

    func testRowsAreSproutDaysMemoriesOrigin() {
        let timeline = build([memory(1, at: date(12, 9)), memory(2, at: date(12, 15)), memory(3, at: date(10, 8))])
        XCTAssertEqual(timeline.rows.first, .sprout)
        XCTAssertEqual(timeline.rows.last, .origin)
        XCTAssertEqual(timeline.rows.map(\.id), [
            "sprout", "day-2026-11-12", "m-A0000000-0000-0000-0000-000000000002",
            "m-A0000000-0000-0000-0000-000000000001", "day-2026-11-10", "m-A0000000-0000-0000-0000-000000000003", "origin",
        ])
    }

    func testTodayLabelAndOtherDayNames() {
        let timeline = build([memory(1, at: date(12, 9)), memory(2, at: date(11, 9))])
        let headers = days(timeline)
        XCTAssertEqual(headers[0].weekday, "Today")
        XCTAssertEqual(headers[0].number, "12")
        XCTAssertEqual(headers[0].monthYear, "November 2026")
        XCTAssertTrue(headers[0].accessibilityLabel.hasPrefix("Today, Thursday"))
        XCTAssertEqual(headers[1].weekday, "Wednesday")
        XCTAssertFalse(headers[1].isToday)
    }

    func testMidnightBoundaryUsesCalendarDay() {
        let timeline = build([memory(1, at: date(12, 0, 0)), memory(2, at: date(11, 23, 59))])
        XCTAssertEqual(days(timeline).map(\.id), ["day-2026-11-12", "day-2026-11-11"])
        XCTAssertEqual(items(timeline).map(\.memory.title), ["Memory 1", "Memory 2"])
    }

    func testFixedTimeZoneDecidesTheDayNotUTC() {
        // 2026-11-11 18:00 UTC is 01:00 on the 12th in UTC+7.
        let utc = Date(timeIntervalSince1970: 1_794_420_000)
        let timeline = build([memory(1, at: utc)])
        XCTAssertEqual(days(timeline).first?.id, "day-2026-11-12")
        XCTAssertEqual(items(timeline).first?.timeText, "01:00")
    }

    func testOrderIsNewestFirstWithTiesBrokenByID() {
        let same = date(12, 9)
        let timeline = build([memory(1, at: same), memory(3, at: same), memory(2, at: same), memory(4, at: date(12, 10))])
        // Newest first; ties in descending id order (the reverse of the ascending order used for staggering).
        XCTAssertEqual(items(timeline).map(\.memory.title), ["Memory 4", "Memory 3", "Memory 2", "Memory 1"])
        let shuffled = build([memory(4, at: date(12, 10)), memory(2, at: same), memory(1, at: same), memory(3, at: same)])
        XCTAssertEqual(timeline, shuffled)
    }

    func testAddingANewerMemoryDoesNotChangeOlderRows() {
        let old = [memory(1, at: date(8, 9)), memory(2, at: date(9, 9)), memory(3, at: date(10, 9))]
        let before = items(build(old))
        let after = items(build(old + [memory(4, at: date(12, 9))]))
        for item in before {
            let matching = after.first { $0.id == item.id }
            XCTAssertEqual(matching?.stagger, item.stagger, "row \(item.id) moved")
        }
    }

    func testStaggerIndexCountsFromOldest() {
        let list = items(build([memory(1, at: date(8, 9)), memory(2, at: date(9, 9)), memory(3, at: date(10, 9))]))
        XCTAssertEqual(list.map(\.stagger), [Stagger(index: 2), Stagger(index: 1), Stagger(index: 0)])
    }

    func testIDsAreStableAcrossRebuilds() {
        let list = [memory(1, at: date(8, 9)), memory(2, at: date(12, 9))]
        XCTAssertEqual(build(list).rows.map(\.id), build(list).rows.map(\.id))
        XCTAssertEqual(Set(build(list).rows.map(\.id)).count, build(list).rows.count)
    }

    func testDayPartIsComputedFromTheLocalHour() {
        let list = items(build([memory(1, at: date(12, 7)), memory(2, at: date(12, 15)), memory(3, at: date(12, 19))]))
        XCTAssertEqual(list.map(\.dayPart), [.evening, .afternoon, .morning])
        XCTAssertEqual(list.map(\.timeText), ["19:00", "15:00", "07:00"])
    }

    func testSinceTextUsesOldestAndAddsYearOnlyWhenDifferent() {
        let sameYear = build([memory(1, at: date(2, 9)), memory(2, at: date(12, 9))]).sinceText ?? ""
        XCTAssertTrue(sameYear.contains("Nov"), sameYear)
        XCTAssertFalse(sameYear.contains("2026"), sameYear)
        let old = memory(1, at: date(1, 9, month: 9, year: 2025))
        let otherYear = build([old, memory(2, at: date(12, 9))]).sinceText ?? ""
        XCTAssertTrue(otherYear.contains("2025"), otherYear)
    }

    func testDayPartBoundaries() {
        XCTAssertEqual(DayPart(hour: 4), .night)
        XCTAssertEqual(DayPart(hour: 5), .morning)
        XCTAssertEqual(DayPart(hour: 11), .morning)
        XCTAssertEqual(DayPart(hour: 12), .afternoon)
        XCTAssertEqual(DayPart(hour: 16), .afternoon)
        XCTAssertEqual(DayPart(hour: 17), .evening)
        XCTAssertEqual(DayPart(hour: 20), .evening)
        XCTAssertEqual(DayPart(hour: 21), .night)
        XCTAssertEqual(DayPart(hour: 0), .night)
        XCTAssertEqual(DayPart(hour: 23), .night)
    }

    func testStaggerFollowsDesignTables() {
        XCTAssertTrue(Stagger(index: 0).isLeft)
        XCTAssertFalse(Stagger(index: 1).isLeft)
        XCTAssertEqual(Stagger(index: 0).tilt, -3)
        XCTAssertEqual(Stagger(index: 1).tilt, 2.4)
        XCTAssertEqual(Stagger(index: 4).tilt, -3)
        XCTAssertEqual(Stagger(index: 1).offset, 18)
        XCTAssertEqual(Stagger(index: 3).offset, 0)
        XCTAssertEqual(Stagger(index: 0).imageHeight, 150)
        XCTAssertEqual(Stagger(index: 1).imageHeight, 116)
        XCTAssertEqual(Stagger(index: 3).imageHeight, 150)
        XCTAssertEqual(Stagger(index: 1).leafFraction, 0.69, accuracy: 0.0001)
    }

    func testSVGParserReadsRelativeAndImplicitCommands() {
        let box = SVGPathParser.path("M3 22C6 14 9 9 12 8c2.4-.8 2.6 3.6 4.2 5.4").boundingRect
        XCTAssertEqual(box.maxX, 16.2, accuracy: 0.5)
        let rect = SVGPathParser.path("M0 0h10v10H0z").boundingRect
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 10, height: 10))
    }
}
