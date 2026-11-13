import SwiftUI

/// Search box under the header (Main.dc.html lines 31-37): white, 46pt high, radius 18, magnifier + field.
/// Takes focus when it appears. Return keeps the results and dismisses the keyboard.
struct HomeSearchField: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(MorrowFont.blankText)
                .foregroundStyle(MorrowColor.textSecondary)
                .accessibilityHidden(true)
            TextField("Search memories", text: $text)
                .font(MorrowFont.searchInput)
                .foregroundStyle(MorrowColor.ink)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { focused = false }
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MorrowColor.textSecondary)
                        .frame(width: MorrowLayout.minHitSize, height: MorrowLayout.minHitSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 14)
        .frame(minHeight: HomeMetrics.searchFieldHeight)
        .background {
            RoundedRectangle(cornerRadius: HomeMetrics.searchFieldRadius, style: .continuous)
                .fill(MorrowColor.card)
                .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 6)
        }
        // Set from `.task`, not in the transaction that inserts the field (iOS 17 can ignore it there).
        .task { focused = true }
    }
}
