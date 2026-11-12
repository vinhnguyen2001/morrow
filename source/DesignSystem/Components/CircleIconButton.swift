import SwiftUI

/// Round icon-only button. The label is mandatory because there is no visible text.
struct CircleIconButton: View {
    let systemImage: String
    let label: String
    /// Requested size. Promoted to `MorrowLayout.minHitSize` (44pt) if smaller.
    var diameter: CGFloat = MorrowLayout.minHitSize
    let action: () -> Void

    var body: some View {
        let side = max(diameter, MorrowLayout.minHitSize)
        Button(action: action) {
            Image(systemName: systemImage)
                .font(MorrowFont.icon)
                .foregroundStyle(MorrowColor.ink)
                .frame(width: side, height: side)
                .background(Circle().fill(MorrowColor.card))
                .morrowCardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
