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
    static let pageTopBelowStatusBar: CGFloat = 7

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

    // Notification dot (line 26): 8pt, 11 from the top, 12 from the right, 2pt white ring.
    static let notificationDot: CGFloat = 8
    static let notificationDotTop: CGFloat = 11
    static let notificationDotTrailing: CGFloat = 12
    static let notificationDotRing: CGFloat = 2
}
