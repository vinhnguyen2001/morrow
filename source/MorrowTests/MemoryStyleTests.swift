import SwiftUI
import XCTest
@testable import Morrow

final class MemoryStyleTests: XCTestCase {
    func testEveryKindHasStyleWithSymbolAndName() {
        for kind in MemoryKind.allCases {
            let style = MemoryKindStyle.style(for: kind)
            XCTAssertFalse(style.symbolName.isEmpty)
            XCTAssertFalse(style.displayName.isEmpty)
        }
    }

    func testNoteUsesApprovedTint() {
        let style = MemoryKindStyle.style(for: .note)
        XCTAssertEqual(style.background, Color(hex: 0xF0ECFF))
        XCTAssertEqual(style.ink, Color(hex: 0x5B3FB8))
    }

    func testPhotoUsesSharedInk() {
        XCTAssertEqual(MemoryKindStyle.style(for: .photo).ink, MorrowColor.ink)
    }

    func testAccessibilityLabelIncludesKindTitleAndPlace() {
        let memory = Memory(kind: .photo, title: "Sunrise", placeName: "Hoi An")
        XCTAssertEqual(MemoryCardAccessibility.label(for: memory), "Photo, Sunrise, at Hoi An")
    }

    func testAccessibilityLabelOmitsMissingPlace() {
        let memory = Memory(kind: .note, title: "Call Mom")
        XCTAssertEqual(MemoryCardAccessibility.label(for: memory), "Note, Call Mom")
    }

    func testAccessibilityLabelAppendsTime() {
        let memory = Memory(kind: .photo, title: "Sunrise", placeName: "Hoi An")
        XCTAssertEqual(MemoryCardAccessibility.label(for: memory, timeText: "15:30"), "Photo, Sunrise, at Hoi An, 15:30")
    }
}
