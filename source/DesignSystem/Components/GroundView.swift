import SwiftUI

/// Chronicle ground: off-white with a dotted grid. Drawn in one Canvas path.
struct GroundView: View {
    var body: some View {
        Canvas { context, size in
            let radius = MorrowGround.dotDiameter / 2
            let step = MorrowGround.gridSpacing
            var path = Path()
            var y = step / 2
            while y < size.height {
                var x = step / 2
                while x < size.width {
                    path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    x += step
                }
                y += step
            }
            context.fill(path, with: .color(MorrowColor.groundDot))
        }
        .background(MorrowColor.ground)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
