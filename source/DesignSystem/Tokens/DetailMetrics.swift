import CoreGraphics

/// Memory Detail measurements in points, from knowledge/design/canvas/Main.dc.html (lines 413-440, 390pt frame).
enum DetailMetrics {
    /// Photo area, measured from the top of the screen (status bar included). Line 415.
    static let photoHeight: CGFloat = 400
    /// Back button: 44pt circle, 16 from the left, 54 from the top of the frame (line 428). The 54 is
    /// converted like `HomeMetrics.pageTopBelowStatusBar`.
    static let backButton: CGFloat = 44
    static let backSide: CGFloat = 16
    static let backTopBelowStatusBar: CGFloat = HomeMetrics.pageTopBelowStatusBar
    /// Text block under the photo: padding 20/20/40, gap 14 (line 434).
    static let contentSide: CGFloat = 20
    static let contentTop: CGFloat = 20
    static let contentBottom: CGFloat = 40
    static let contentGap: CGFloat = 14
    /// Coloured header used instead of a photo (line 418): padding 118/24/30, kicker to title gap 4.
    static let headerTop: CGFloat = 118
    static let headerSide: CGFloat = 24
    static let headerBottom: CGFloat = 30
    static let headerGap: CGFloat = 4
    /// Big decorative leaf in that header: 120pt, 18 past the right edge, 60 from the top, 35% opacity.
    static let leafSize: CGFloat = 120
    static let leafBleed: CGFloat = 18
    static let leafTop: CGFloat = 60
    static let leafOpacity: Double = 0.35
    /// Note text line height is 1.65 x 16pt = 26.4. Measured on the simulator: `lineSpacing` 5 gave a 24.2pt
    /// line pitch, so 7 gives about 26.2.
    static let bodyLineSpacing: CGFloat = 7
    /// Title letter spacing (line 427, -0.3px).
    static let titleTracking: CGFloat = -0.3
    /// Delete button height (the design's secondary buttons are 48).
    static let deleteHeight: CGFloat = 48
}
