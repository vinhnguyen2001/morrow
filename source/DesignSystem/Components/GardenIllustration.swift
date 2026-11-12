import SwiftUI

/// Empty-state illustration: a pot with a sprout. Paths pasted from Main.dc.html line 49 (viewBox 190x170).
struct GardenIllustration: View {
    private static let box = CGSize(width: 190, height: 170)
    private static func shape(_ data: String) -> SVGShape {
        SVGShape(source: SVGPathParser.path(data), viewBox: box)
    }
    private static let pot = shape("M62 104h66l-8 44H70z")
    private static let rim = shape("M58 98h74v10H58z")
    private static let stem = shape("M95 100C95 82 94 70 95 58")
    private static let leafLight = shape("M95 72C82 72 74 63 73 50c12 0 22 8 22 22z")
    private static let leafDark = shape("M95 64c11 0 20-7 21-19-11 0-20 7-21 19z")
    private static let sparkleGold = shape("M40 40c.6 3.6 2 5 5.6 5.6-3.6.6-5 2-5.6 5.6-.6-3.6-2-5-5.6-5.6 3.6-.6 5-2 5.6-5.6z")
    private static let sparkleLilac = shape("M146 26c.5 3 1.7 4.2 4.7 4.7-3 .5-4.2 1.7-4.7 4.7-.5-3-1.7-4.2-4.7-4.7 3-.5 4.2-1.7 4.7-4.7z")
    private static let dashLeft = shape("M28 120c6-10 14-12 22-8")
    private static let dashRight = shape("M162 112c-4-10-12-14-20-10")

    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xE9E9E9))
                .frame(width: 140, height: 20)
                .position(x: 95, y: 150)
            Self.pot.fill(Color(hex: 0xFFF1E6))
            Self.pot.stroke(Color(hex: 0xD9B996), lineWidth: 1.5)
            Self.rim.fill(Color(hex: 0xF0DCC4))
            Self.stem.stroke(MorrowColor.action, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            Self.leafLight.fill(MorrowColor.leaf)
            Self.leafDark.fill(MorrowColor.action)
            Self.sparkleGold.fill(Color(hex: 0xE2B64F))
            Self.sparkleLilac.fill(Color(hex: 0xC9B8E3))
            Self.dashLeft.stroke(MorrowColor.leaf, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 5]))
            Self.dashRight.stroke(MorrowColor.leaf, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 5]))
        }
        .frame(width: HomeMetrics.gardenWidth, height: HomeMetrics.gardenHeight)
        .accessibilityHidden(true)
    }
}

#Preview("Garden") {
    GardenIllustration().padding().background(MorrowColor.ground)
}
