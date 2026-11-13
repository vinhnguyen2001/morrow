import XCTest
@testable import Morrow

final class NoteCardsTests: XCTestCase {
    private typealias Support = ProjectionTestSupport

    private func build(_ memories: [Memory]) -> TwoColumns<NoteCard> {
        NoteCards.build(memories: memories, calendar: Support.calendar, now: Support.now)
    }

    func testKeepsOnlyNotesNewestFirst() {
        let columns = build([
            Support.memory(1, at: Support.date(1)),
            Support.memory(2, kind: .photo, at: Support.date(2)),
            Support.memory(3, at: Support.date(3)),
        ])
        XCTAssertEqual(columns.all.map(\.title), ["Memory 3", "Memory 1"])
    }

    func testEmptyWhenNoNotes() {
        XCTAssertTrue(build([Support.memory(1, kind: .photo, at: Support.date(1))]).isEmpty)
        XCTAssertTrue(build([]).isEmpty)
    }

    func testToneEveryThirdIsPeachCountedFromOldest() {
        let notes = (1...6).map { Support.memory($0, at: Support.date($0)) }
        let all = build(notes).all
        // Oldest first: index 0 1 2 3 4 5 -> lavender lavender peach lavender lavender peach.
        XCTAssertEqual(all.reversed().map(\.tone), [.lavender, .lavender, .peach, .lavender, .lavender, .peach])
    }

    func testStyleDoesNotChangeWhenANewerNoteIsAdded() {
        let notes = (1...3).map { Support.memory($0, at: Support.date($0)) }
        let before = build(notes).all
        let after = build(notes + [Support.memory(4, at: Support.date(4))]).all
        for card in before { XCTAssertEqual(after.first { $0.id == card.id }, card) }
    }

    func testTiltAndLineLimitFollowTheTables() {
        let all = build((1...5).map { Support.memory($0, at: Support.date($0)) }).all.reversed() as [NoteCard]
        XCTAssertEqual(all.map(\.tilt), [0.6, -0.8, 0.3, -0.4, 0.6])
        XCTAssertEqual(all.map(\.lineLimit), [6, 4, 6, 4, 6])
    }

    func testColumnsAlternateByDisplayPosition() {
        let columns = build((1...5).map { Support.memory($0, at: Support.date($0)) })
        XCTAssertEqual(columns.left.map(\.title), ["Memory 5", "Memory 3", "Memory 1"])
        XCTAssertEqual(columns.right.map(\.title), ["Memory 4", "Memory 2"])
    }

    func testShortDateAndPlace() {
        let card = build([Support.memory(1, title: "Coffee", body: "  Salted  ", place: " Hội An ", at: Support.date(3))]).all[0]
        XCTAssertEqual(card.dateText, "3 Nov")
        XCTAssertEqual(card.placeName, "Hội An")
        XCTAssertEqual(card.preview, "Salted")
        XCTAssertEqual(card.accessibilityLabel, "Note, Coffee, at Hội An, 3 Nov")
    }

    func testDateShowsYearWhenNotThisYear() {
        let card = build([Support.memory(1, at: Support.date(3, year: 2025))]).all[0]
        XCTAssertEqual(card.dateText, "3 Nov 2025")
    }

    func testBlankBodyAndPlaceBecomeNil() {
        let card = build([Support.memory(1, body: "  \n", place: "   ", at: Support.date(3))]).all[0]
        XCTAssertNil(card.preview)
        XCTAssertNil(card.placeName)
    }
}
