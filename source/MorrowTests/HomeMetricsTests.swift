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

    func testAddColourIsActionGreen() {
        XCTAssertEqual(MorrowColor.action, Color(hex: 0x1E3B2F))
        XCTAssertEqual(MorrowColor.textSecondary, Color(hex: 0x5C5C5C))
    }

    func testFontTokensAreSystemTextStyles() {
        XCTAssertEqual(MorrowFont.logo, Font.system(.title2, weight: .heavy))
        XCTAssertEqual(MorrowFont.actionLabel, Font.system(.subheadline, weight: .bold))
        XCTAssertEqual(MorrowFont.emptyTitle, Font.system(.title2, weight: .heavy))
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
