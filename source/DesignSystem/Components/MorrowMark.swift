import SwiftUI

/// The "M swoosh" logo mark. Path from Main.dc.html line 24 (viewBox 34x26), scaled to fit the rect.
struct MorrowMark: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 34, rect.height / 26)
        let originX = rect.midX - 17 * scale
        let originY = rect.midY - 13 * scale
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: originX + x * scale, y: originY + y * scale)
        }
        var path = Path()
        path.move(to: point(3, 22))
        path.addCurve(to: point(12, 8), control1: point(6, 14), control2: point(9, 9))
        path.addCurve(to: point(16.2, 13.4), control1: point(14.4, 7.2), control2: point(14.6, 11.6))
        path.addCurve(to: point(25, 4), control1: point(18.6, 12), control2: point(21, 6))
        path.addCurve(to: point(31, 10), control1: point(27.8, 2.6), control2: point(29.6, 6))
        return path
    }
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
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Logo") {
    MorrowLogo().padding().background(MorrowColor.ground)
}
