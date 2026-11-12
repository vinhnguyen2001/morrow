import SwiftUI

/// Round icon-only button. The label is mandatory because there is no visible text.
struct CircleIconButton: View {
    let systemImage: String
    let label: String
    /// Filled with the action colour (Add button) instead of white.
    var prominent = false
    /// Requested size. Promoted to `MorrowLayout.minHitSize` (44pt) if smaller.
    var diameter: CGFloat = MorrowLayout.minHitSize
    var iconFont: Font = MorrowFont.icon
    /// Off on the Detail Back button: the design draws it flat over the photo.
    var showsShadow = true
    let action: () -> Void

    var body: some View {
        let side = max(diameter, MorrowLayout.minHitSize)
        Button(action: action) {
            Image(systemName: systemImage)
                .font(iconFont)
                .foregroundStyle(prominent ? Color.white : MorrowColor.ink)
                .frame(width: side, height: side)
                .background(Circle().fill(prominent ? MorrowColor.action : MorrowColor.card))
                .modifier(OptionalCardShadow(isOn: showsShadow))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct OptionalCardShadow: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn { content.morrowCardShadow() } else { content }
    }
}
