import SwiftUI
import XCTest
@testable import Morrow

final class HomeMetricsTests: XCTestCase {
    func testKeyMeasurementsMatchDesign() {
        XCTAssertEqual(HomeMetrics.pageTop, 54)
        XCTAssertEqual(HomeMetrics.pageSide, 16)
        XCTAssertEqual(HomeMetrics.pageBottom, 130)
        XCTAssertEqual(HomeMetrics.headerHeight, 48)
        XCTAssertEqual(HomeMetrics.headerButton, 46)
        XCTAssertEqual(HomeMetrics.addButton, 64)
        XCTAssertEqual(HomeMetrics.fabSideInset, 20)
        XCTAssertEqual(HomeMetrics.fabBottomInset, 30)
    }

    func testSegmentedAndNotesMeasurementsMatchDesign() {
        XCTAssertEqual(HomeMetrics.segmentHeight, 40)
        XCTAssertEqual(HomeMetrics.segmentPadding, 4)
        XCTAssertEqual(HomeMetrics.segmentGap, 4)
        XCTAssertEqual(HomeMetrics.noteColumnOffset, 26)
        XCTAssertEqual(HomeMetrics.noteRadius, 24)
        XCTAssertEqual(HomeMetrics.newNoteHeight, 40)
        XCTAssertEqual(HomeMetrics.noteInsetSide, 15)
        XCTAssertEqual(HomeMetrics.noteInsetTop, 15)
        XCTAssertEqual(HomeMetrics.noteInsetBottom, 14)
        XCTAssertGreaterThanOrEqual(HomeMetrics.segmentHeight + 2 * HomeMetrics.segmentPadding, MorrowLayout.minHitSize)
        XCTAssertEqual(MorrowColor.segmentTrack, Color(hex: 0xE9E9E9))
        XCTAssertEqual(MorrowColor.notePeach, Color(hex: 0xFFF1E6))
    }

    func testPlacesMeasurementsMatchDesign() {
        XCTAssertEqual(HomeMetrics.placeCardPadding, 6)
        XCTAssertEqual(HomeMetrics.placeCardRadius, 24)
        XCTAssertEqual(HomeMetrics.placeImageRadius, 19)
        XCTAssertEqual(HomeMetrics.placeColumnOffset, 30)
        XCTAssertEqual(HomeMetrics.placeRowGap, 14)
    }

    func testSearchFieldMeasurementsMatchDesign() {
        XCTAssertEqual(HomeMetrics.searchFieldHeight, 46)
        XCTAssertEqual(HomeMetrics.searchFieldRadius, 18)
        XCTAssertEqual(HomeMetrics.searchFieldTop, 8)
    }

    func testTabsAreMomentsNotesPlaces() {
        XCTAssertEqual(HomeTab.allCases.map(\.title), ["Moments", "Notes", "Places"])
    }

    func testAddColourIsActionGreen() {
        XCTAssertEqual(MorrowColor.action, Color(hex: 0x1E3B2F))
        XCTAssertEqual(MorrowColor.textSecondary, Color(hex: 0x5C5C5C))
    }

    func testLogoMarkFitsItsViewBoxAndScales() {
        let box = MorrowMark().path(in: CGRect(x: 0, y: 0, width: 34, height: 26)).boundingRect
        XCTAssertGreaterThanOrEqual(box.minX, 0)
        XCTAssertLessThanOrEqual(box.maxX, 34)
        XCTAssertGreaterThanOrEqual(box.minY, 0)
        XCTAssertLessThanOrEqual(box.maxY, 26)
        let doubled = MorrowMark().path(in: CGRect(x: 0, y: 0, width: 68, height: 52)).boundingRect
        XCTAssertEqual(doubled.width, box.width * 2, accuracy: 0.01)
    }
}
