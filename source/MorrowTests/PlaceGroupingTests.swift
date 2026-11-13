import XCTest
@testable import Morrow

final class PlaceGroupingTests: XCTestCase {
    private typealias Support = ProjectionTestSupport

    private func build(_ memories: [Memory]) -> TwoColumns<PlaceCard> {
        PlaceGrouping.build(memories: memories, calendar: Support.calendar, now: Support.now)
    }

    func testDifferentSpellingsAreOnePlace() {
        let columns = build([
            Support.memory(1, place: "Hội An", at: Support.date(1)),
            Support.memory(2, place: "hội an ", at: Support.date(2)),
            Support.memory(3, place: "Hoi An", at: Support.date(3)),
        ])
        XCTAssertEqual(columns.all.count, 1)
        XCTAssertEqual(columns.all[0].count, 3)
    }

    func testMemoriesWithoutPlaceAreSkipped() {
        let columns = build([
            Support.memory(1, place: nil, at: Support.date(1)),
            Support.memory(2, place: "   ", at: Support.date(2)),
            Support.memory(3, place: "Huế", at: Support.date(3)),
        ])
        XCTAssertEqual(columns.all.map(\.name), ["Huế"])
        XCTAssertTrue(build([Support.memory(1, at: Support.date(1))]).isEmpty)
    }

    func testDisplayNameIsTheNewestSpelling() {
        let columns = build([
            Support.memory(1, place: "Hoi An", at: Support.date(1)),
            Support.memory(2, place: " Hội An ", at: Support.date(5)),
            Support.memory(3, place: "hoi an", at: Support.date(3)),
        ])
        XCTAssertEqual(columns.all[0].name, "Hội An")
    }

    func testOrderedByMostRecentVisit() {
        let columns = build([
            Support.memory(1, place: "A", at: Support.date(2)),
            Support.memory(2, place: "B", at: Support.date(9)),
            Support.memory(3, place: "A", at: Support.date(4)),
            Support.memory(4, place: "C", at: Support.date(6)),
        ])
        XCTAssertEqual(columns.all.map(\.name), ["B", "C", "A"])
        XCTAssertEqual(columns.left.map(\.name), ["B", "A"])
        XCTAssertEqual(columns.right.map(\.name), ["C"])
    }

    func testCountTextPlural() {
        XCTAssertEqual(PlaceGrouping.countText(1), "1 memory")
        XCTAssertEqual(PlaceGrouping.countText(2), "2 memories")
        let columns = build([Support.memory(1, place: "A", at: Support.date(1)), Support.memory(2, place: "B", at: Support.date(2)),
                             Support.memory(3, place: "B", at: Support.date(3))])
        XCTAssertEqual(columns.all.map(\.countText), ["2 memories", "1 memory"])
    }

    func testCoverIsNewestPhotoElseNil() {
        let columns = build([
            Support.memory(1, kind: .photo, place: "A", photo: "old.jpg", at: Support.date(1)),
            Support.memory(2, kind: .photo, place: "A", photo: "new.jpg", at: Support.date(2)),
            Support.memory(3, kind: .note, place: "A", at: Support.date(3)),
            Support.memory(4, kind: .note, place: "B", at: Support.date(4)),
        ])
        XCTAssertNil(columns.all.first { $0.name == "B" }?.coverFileName)
        XCTAssertEqual(columns.all.first { $0.name == "A" }?.coverFileName, "new.jpg")
    }

    func testLastTextAndLabel() {
        let card = build([Support.memory(1, place: "Hội An", at: Support.date(3))]).all[0]
        XCTAssertEqual(card.lastText, "Last: 3 Nov")
        XCTAssertEqual(card.accessibilityLabel, "Hội An, 1 memory, last visit 3 Nov")
    }

    func testImageHeightsRotateByIndex() {
        let memories = (0..<4).map { Support.memory($0, place: "P\($0)", at: Support.date(10 - $0)) }
        XCTAssertEqual(build(memories).all.map(\.imageHeight), [135, 150, 165, 135])
    }

    func testIdIsStableWhenAnotherSpellingArrives() {
        let before = build([Support.memory(1, place: "Hoi An", at: Support.date(1))]).all[0].id
        let after = build([Support.memory(1, place: "Hoi An", at: Support.date(1)),
                           Support.memory(2, place: "Hội An", at: Support.date(2))]).all[0].id
        XCTAssertEqual(before, after)
    }
}
