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
    /// "Recent moments" (design 18/800).
    static let sectionTitle = Font.system(.headline, weight: .heavy)
    /// "since Sep 1" (design 13/600).
    static let sectionMeta = Font.system(.footnote, weight: .semibold)
    /// Day name and time beside the timeline (design 14/800).
    static let rowTitle = Font.system(.subheadline, weight: .heavy)
    /// Month and year, day part (design 12/600 and 12.5/600).
    static let rowDetail = Font.system(.caption, weight: .semibold)
    /// Day number in the 46pt badge (design 19/800). Fixed: the badge is a fixed-size circle.
    static let dayNumber = Font.system(size: 19, weight: .heavy)
    /// Empty-state tagline (design 14/600).
    static let tagline = Font.system(.subheadline, weight: .semibold)
    /// Primary button text (design 16/800).
    static let cta = Font.system(.callout, weight: .heavy)
    /// Small transient messages (design has none; sized like section meta, 13/600).
    static let notice = Font.system(.footnote, weight: .semibold)
    /// Memory title on Detail (design 28/800, `.title` is 28pt).
    static let detailTitle = Font.system(.title, weight: .heavy)
    /// "a note" above the title in the note header (design 14/600).
    static let detailKicker = Font.system(.subheadline, weight: .semibold)
    /// Note text on Detail (design 16, line height 1.65).
    static let detailBody = Font.system(.callout)
    // Icons use fixed sizes: they sit in fixed-size containers and must not scale with Dynamic Type.
    static let icon = Font.system(size: 20, weight: .semibold)
    /// Glyph inside the 64pt Add button (design svg 30pt).
    static let iconLarge = Font.system(size: 28, weight: .semibold)
    static let glyph = Font.system(size: 20, weight: .semibold)
    /// Segmented control labels (design 14.5/800 selected, 700 off).
    static let segmentSelected = Font.system(.subheadline, weight: .heavy)
    static let segmentOff = Font.system(.subheadline, weight: .bold)
    /// "New note" button (design 13.5/800).
    static let smallButton = Font.system(.footnote, weight: .heavy)
    /// Note tile: kicker (design 11/800 caps), title (15.5/800), preview (13), date (13/600), place (11.5/700).
    static let noteKicker = Font.system(.caption2, weight: .heavy)
    static let noteTitle = Font.system(.subheadline, weight: .heavy)
    static let notePreview = Font.system(.footnote)
    static let noteDate = Font.system(.footnote, weight: .semibold)
    static let noteMeta = Font.system(.caption, weight: .bold)
    /// Tab empty-state heading (design 14/600) and text (15).
    static let blankTitle = Font.system(.subheadline, weight: .semibold)
    static let blankText = Font.system(.subheadline)
    /// Text typed into the search box (design 15).
    static let searchInput = Font.system(.subheadline)
    /// Small labels: kind line in the Map peek row and the badge on the Home Map button (design 11/800).
    static let micro = Font.system(.caption2, weight: .heavy)
}
