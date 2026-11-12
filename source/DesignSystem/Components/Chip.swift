import SwiftUI

/// Pill label. Non-interactive; wrap in a Button (with a 44pt hit area) if it must be tappable.
struct Chip: View {
    let text: String
    let systemImage: String?
    let background: Color
    let foreground: Color

    init(
        _ text: String,
        systemImage: String? = nil,
        background: Color = MorrowColor.card,
        foreground: Color = MorrowColor.ink
    ) {
        self.text = text
        self.systemImage = systemImage
        self.background = background
        self.foreground = foreground
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            Text(text)
        }
        .font(MorrowFont.chip)
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(background))
        .accessibilityElement(children: .combine)
    }
}
