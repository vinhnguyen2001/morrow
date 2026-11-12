import SwiftUI

/// The "M swoosh" logo mark. Path data from Main.dc.html line 24 (viewBox 34x26).
struct MorrowMark: Shape {
    private static let shape = SVGShape(
        source: SVGPathParser.path("M3 22C6 14 9 9 12 8c2.4-.8 2.6 3.6 4.2 5.4C18.6 12 21 6 25 4c2.8-1.4 4.6 2 6 6"),
        viewBox: CGSize(width: 34, height: 26)
    )

    func path(in rect: CGRect) -> Path { Self.shape.path(in: rect) }
}

/// Logo mark plus the "Morrow" word, as one header element for VoiceOver.
struct MorrowLogo: View {
    var body: some View {
        HStack(spacing: HomeMetrics.logoTextGap) {
            MorrowMark()
                .stroke(MorrowColor.action, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: HomeMetrics.logoWidth, height: HomeMetrics.logoHeight)
                .accessibilityHidden(true)
            Text("Morrow")
                .font(MorrowFont.logo)
                .tracking(-0.5)
                .foregroundStyle(MorrowColor.action)
                // The header is a fixed 48pt row of 46pt buttons: the logo word stops growing at xxxLarge.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Logo") {
    MorrowLogo().padding().background(MorrowColor.ground)
}
