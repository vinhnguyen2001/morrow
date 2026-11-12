import SwiftUI

enum MorrowRadius {
    static let card: CGFloat = 26
    static let cardImage: CGFloat = 20
    static let sheet: CGFloat = 34
}

enum MorrowGround {
    static let dotDiameter: CGFloat = 1.2
    static let gridSpacing: CGFloat = 18
}

enum MorrowLayout {
    /// Apple HIG minimum hit target.
    static let minHitSize: CGFloat = 44
}

/// Type tokens. The face is the system font (SF Pro, ADR 0004; the design's Inter was declined by the user).
/// Every token is a text style so Dynamic Type works; sizes are the nearest style to the design's
/// fixed px sizes (Main.dc.html), so a mismatch of up to about 1pt is accepted. Call sites never use `.system(`.
enum MorrowFont {
    static let cardTitleCompact = Font.system(.subheadline, weight: .heavy)
    static let cardTitleWide = Font.system(.headline, weight: .heavy)
    static let body = Font.system(.subheadline)
    static let caption = Font.system(.caption, weight: .semibold)
    static let chip = Font.system(.caption, weight: .bold)
    /// Text buttons inside sheets (design 14.5/700).
    static let actionLabel = Font.system(.subheadline, weight: .bold)
    /// "Morrow" next to the logo (design 22/800).
    static let logo = Font.system(.title2, weight: .heavy)
    /// Empty-state title (design 24/800).
    static let emptyTitle = Font.system(.title2, weight: .heavy)
    /// Small transient messages (design has none; sized like section meta, 13/600).
    static let notice = Font.system(.footnote, weight: .semibold)
    // Icons use fixed sizes: they sit in fixed-size containers and must not scale with Dynamic Type.
    static let icon = Font.system(size: 20, weight: .semibold)
    /// Glyph inside the 64pt Add button (design svg 30pt).
    static let iconLarge = Font.system(size: 28, weight: .semibold)
    static let glyph = Font.system(size: 20, weight: .semibold)
}
