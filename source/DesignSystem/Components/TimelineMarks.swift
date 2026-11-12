import SwiftUI

/// Leaf on the timeline. Path from Main.dc.html line 114 (viewBox 24), vein in ground colour.
struct LeafMark: View {
    var fill: Color = MorrowColor.leaf

    private static let box = CGSize(width: 24, height: 24)
    private static let leaf = SVGPathParser.path("M3 20C3 10 9 4 21 3c0 11-7 17-18 17z")
    private static let vein = SVGPathParser.path("M4 19C9 13 13 9 18 6")

    var body: some View {
        ZStack {
            SVGShape(source: Self.leaf, viewBox: Self.box).fill(fill)
            SVGShape(source: Self.vein, viewBox: Self.box)
                .stroke(MorrowColor.ground, lineWidth: 0.9)
        }
        .frame(width: HomeMetrics.leafSize, height: HomeMetrics.leafSize)
        .accessibilityHidden(true)
    }
}

/// Sprout at the top of the timeline. Paths from Main.dc.html lines 88-89 (viewBox 32).
struct SproutMark: View {
    private static let box = CGSize(width: 32, height: 32)
    private static let stem = SVGPathParser.path("M16 30V18")
    private static let small = SVGPathParser.path("M16 20c-6 0-9.5-4-9.6-9.4 5.6 0 9.6 3.6 9.6 9.4z")
    private static let large = SVGPathParser.path("M16 18c5 0 8.6-3.4 8.8-8.6-5.2 0-8.8 3.4-8.8 8.6z")

    var body: some View {
        ZStack {
            SVGShape(source: Self.stem, viewBox: Self.box)
                .stroke(MorrowColor.leaf, style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
            SVGShape(source: Self.small, viewBox: Self.box).fill(MorrowColor.leafLight)
            SVGShape(source: Self.large, viewBox: Self.box).fill(MorrowColor.leaf)
        }
        .frame(width: HomeMetrics.sproutSize, height: HomeMetrics.sproutSize)
        .accessibilityHidden(true)
    }
}

/// Sprout block: a short stem of the spine with the sprout above it.
struct TimelineSprout: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(MorrowColor.leaf)
                .frame(width: HomeMetrics.spineWidth, height: HomeMetrics.sproutSpine)
            SproutMark().padding(.bottom, HomeMetrics.sproutBottom)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HomeMetrics.sproutBlockHeight)
    }
}

/// Curved line joining the spine to a card (Main.dc.html line 113, viewBox 44x100, stretched to the row).
struct TimelineConnector: Shape {
    /// True when the card is on the left, so the curve bows to the right.
    let cardOnLeft: Bool

    private static let towardRight = SVGShape(
        source: SVGPathParser.path("M22 0 C 40 30, 40 70, 22 100"), viewBox: CGSize(width: 44, height: 100), stretch: true)
    private static let towardLeft = SVGShape(
        source: SVGPathParser.path("M22 0 C 4 30, 4 70, 22 100"), viewBox: CGSize(width: 44, height: 100), stretch: true)

    func path(in rect: CGRect) -> Path {
        (cardOnLeft ? Self.towardRight : Self.towardLeft).path(in: rect)
    }
}

/// Places its one child at a fraction of its own height, a given distance from the horizontal centre.
/// A tiny Layout instead of a GeometryReader in every row.
struct FractionalPosition: Layout {
    var yFraction: CGFloat
    var centerOffsetX: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        child.place(
            at: CGPoint(x: bounds.midX + centerOffsetX, y: bounds.minY + bounds.height * yFraction),
            anchor: .topLeading,
            proposal: .unspecified
        )
    }
}
