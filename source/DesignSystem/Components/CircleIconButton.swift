import SwiftUI

/// Round icon-only button. The label is mandatory because there is no visible text.
struct CircleIconButton: View {
    let systemImage: String
    let label: String
    /// Filled with the action colour (Add button) instead of white.
    var prominent = false
    /// Requested size. Promoted to `MorrowLayout.minHitSize` (44pt) if smaller.
    var diameter: CGFloat = MorrowLayout.minHitSize
    let action: () -> Void

    var body: some View {
        let side = max(diameter, MorrowLayout.minHitSize)
        Button(action: action) {
            Image(systemName: systemImage)
                .font(MorrowFont.icon)
                .foregroundStyle(prominent ? Color.white : MorrowColor.ink)
                .frame(width: side, height: side)
                .background(Circle().fill(prominent ? MorrowColor.action : MorrowColor.card))
                .morrowCardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
