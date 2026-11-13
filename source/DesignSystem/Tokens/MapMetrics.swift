import CoreGraphics

/// Map screen measurements, read from the design (Main.dc.html MAP, lines 212-270). Pinned by MapPinsTests.
enum MapMetrics {
    /// Peek sheet height. The design's MS_PEEK is 160; 168 is the spec in T-004 (room for the drag indicator).
    static let peekHeight: CGFloat = 168
    /// Sheet corner radius (line 259).
    static let sheetCorner: CGFloat = 30
    /// Back button (line 249): 46pt, 16 from the side, 54 from the top of the frame.
    static let backButton: CGFloat = HomeMetrics.headerButton

    // Peek row (lines 263-275): card at 16 from the sides, padding 8, radius 22, thumbnail 60 with radius 16, gap 12.
    static let rowSide: CGFloat = 16
    static let rowTop: CGFloat = 8
    static let rowPadding: CGFloat = 8
    static let rowRadius: CGFloat = 22
    static let rowGap: CGFloat = 12
    static let thumbnail: CGFloat = 60
    static let thumbnailRadius: CGFloat = 16
    static let expandButton: CGFloat = 42
    static let rowTextGap: CGFloat = 2
    static let hintTop: CGFloat = 14
}
