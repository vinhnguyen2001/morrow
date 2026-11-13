import SwiftUI

/// Message of a tab with nothing in it yet (Main.dc.html lines 164 and 190): a green line and a sentence.
struct BlankPage: View {
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(MorrowFont.blankTitle)
                .foregroundStyle(MorrowColor.action)
            Text(text)
                .font(MorrowFont.blankText)
                .foregroundStyle(MorrowColor.textSecondary)
                .lineSpacing(3)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
        .padding(.top, HomeMetrics.blankTop)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
