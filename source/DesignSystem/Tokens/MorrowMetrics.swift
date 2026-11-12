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

/// Type tokens use text styles so Dynamic Type works. Swap the design/face here
/// (for example Inter) without touching call sites.
enum MorrowFont {
    static let cardTitleCompact = Font.system(.subheadline, weight: .heavy)
    static let cardTitleWide = Font.system(.headline, weight: .heavy)
    static let body = Font.system(.subheadline)
    static let caption = Font.system(.caption, weight: .semibold)
    static let chip = Font.system(.caption, weight: .bold)
    // Icons use fixed sizes: they sit in fixed-size containers and must not scale with Dynamic Type.
    static let icon = Font.system(size: 17, weight: .semibold)
    static let glyph = Font.system(size: 20, weight: .semibold)
}
