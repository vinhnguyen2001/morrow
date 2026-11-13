import CoreGraphics

/// Home measurements in points, read from the design (knowledge/design/canvas/Main.dc.html, 390pt frame).
/// The comment on each value is the line it comes from. Pinned by HomeMetricsTests.
enum HomeMetrics {
    // Page padding (line 20). The 54 is measured from the top of the frame, status bar included.
    static let pageTop: CGFloat = 54
    static let pageSide: CGFloat = 16
    static let pageBottom: CGFloat = 130
    /// Gap between the bottom of the status bar and the header. The design's 54 minus the 47pt status bar
    /// of a 390pt-wide iPhone (SwiftUI's safe area already covers the status bar and Dynamic Island).
    static let pageTopBelowStatusBar: CGFloat = pageTop - statusBarHeight
    static let statusBarHeight: CGFloat = 47

    // Header (lines 22-25)
    static let headerHeight: CGFloat = 48
    static let headerButton: CGFloat = 46
    static let headerButtonGap: CGFloat = 8
    static let logoWidth: CGFloat = 34
    static let logoHeight: CGFloat = 26
    static let logoTextGap: CGFloat = 6

    // Floating Add button (line 208): 64pt, 20 from the right, 30 from the bottom, no rotation.
    static let addButton: CGFloat = 64
    static let fabSideInset: CGFloat = 20
    static let fabBottomInset: CGFloat = 30
    // Floating Map button (line 207): 56pt, white, 20 from the left, 30 from the bottom. Badge: min 20pt,
    // 3pt out of the top-right corner, 2pt white ring.
    static let mapButton: CGFloat = 56
    static let mapBadge: CGFloat = 20
    static let mapBadgeOffset: CGFloat = 3
    static let mapBadgeRing: CGFloat = 2

    // Notification dot (line 26): 8pt, 11 from the top, 12 from the right, 2pt white ring.
    static let notificationDot: CGFloat = 8
    static let notificationDotTop: CGFloat = 11
    static let notificationDotTrailing: CGFloat = 12
    static let notificationDotRing: CGFloat = 2

    // "Recent moments" section (lines 78-84): 22pt below the header block, timeline starts 4pt under the title.
    static let sectionTop: CGFloat = 22
    static let timelineTop: CGFloat = 4

    // Sprout block (lines 85-91): 46 high, 34pt sprout 12 above the bottom, 16pt stem of spine under it.
    static let sproutBlockHeight: CGFloat = 46
    static let sproutSize: CGFloat = 34
    static let sproutBottom: CGFloat = 12
    static let sproutSpine: CGFloat = 16
    static let spineWidth: CGFloat = 1.6

    // Day row (lines 92-100): padding 16/0/12, badge 46 with a 4pt ground ring, gap 10. (The design also shifts the group by margin-left -23; see DateBadge for why it is not copied.)
    static let dayRowTop: CGFloat = 16
    static let dayRowBottom: CGFloat = 12
    static let dayBadge: CGFloat = 46
    static let dayBadgeRing: CGFloat = 4
    static let dayBadgeGap: CGFloat = 10

    // Memory row (lines 112-137): padding 6/0/10, connector 44 wide, dot 12 at top 40 (2pt border), leaf 18,
    // opposite-column text padding top 38 and 16 from the spine side.
    static let memoryRowTop: CGFloat = 6
    static let memoryRowBottom: CGFloat = 10
    static let connectorWidth: CGFloat = 44
    static let rowDot: CGFloat = 12
    static let rowDotTop: CGFloat = 40
    static let rowDotBorder: CGFloat = 2
    static let leafSize: CGFloat = 18
    static let leafSideOffset: CGFloat = 10
    static let sideTextTop: CGFloat = 38
    static let sideTextInset: CGFloat = 16

    // Origin (lines 144-150): padding top 8, stem 18, dot 10, gap 4.
    static let originTop: CGFloat = 8
    static let originStem: CGFloat = 18
    static let originDot: CGFloat = 10
    static let originGap: CGFloat = 4

    // Empty state (lines 48-56): 36 below the header, 14 gap, illustration 190x170, CTA 52 high.
    static let emptyTop: CGFloat = 36
    static let emptyGap: CGFloat = 14
    static let emptyInset: CGFloat = 18
    static let gardenWidth: CGFloat = 190
    static let gardenHeight: CGFloat = 170
    static let ctaHeight: CGFloat = 52

    // Segmented control (lines 38-41): 12 below the header, 4 padding, 4 gap, 40 high pills.
    // The pill is drawn 40 high; its hit area also covers the 4pt track padding, so it is 48 high (>= 44).
    static let segmentTop: CGFloat = 12
    static let segmentPadding: CGFloat = 4
    static let segmentGap: CGFloat = 4
    static let segmentHeight: CGFloat = 40

    // Notes tab (lines 157-178): list 14 below the title row, columns 12 apart, second column 26 lower,
    // tiles radius 24 with padding 15/15/14 and 8 between lines, "New note" 40 high.
    static let tabListTop: CGFloat = 14
    static let columnGap: CGFloat = 12
    static let noteColumnOffset: CGFloat = 26
    static let noteRadius: CGFloat = 24
    static let noteInsetTop: CGFloat = 15
    static let noteInsetBottom: CGFloat = 14
    static let noteSpacing: CGFloat = 8
    static let newNoteHeight: CGFloat = 40
    /// Blank-tab message sits 40 below the title row (line 164).
    static let blankTop: CGFloat = 40

    // Places tab (lines 181-205): cards padding 6, radius 24, photo radius 19, second column 30 lower, rows 14 apart.
    static let placeCardPadding: CGFloat = 6
    static let placeCardRadius: CGFloat = 24
    static let placeImageRadius: CGFloat = 19
    static let placeColumnOffset: CGFloat = 30
    static let placeRowGap: CGFloat = 14

    // Search box (lines 31-33): 8 below the header, 46 high, radius 18, padding 0 14, gap 8.
    static let searchFieldTop: CGFloat = 8
    static let searchFieldHeight: CGFloat = 46
    static let searchFieldRadius: CGFloat = 18
}
