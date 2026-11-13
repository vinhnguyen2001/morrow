import SwiftUI

/// Moments / Notes / Places switch (Main.dc.html lines 38-41, 1265-1270): grey pill track, white selected pill.
/// Each pill is drawn 40pt high; its tap area includes the 4pt track padding, so it is 48pt high.
/// Unselected text uses `textSecondary` (the design's #6E6E6E is about 4.2:1 on the track).
struct CategorySegmentedControl: View {
    @Binding var selection: HomeTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: TimelineLayout { TimelineLayout(dynamicTypeSize: dynamicTypeSize) }

    /// One row of three pills; at accessibility text sizes the pills stack, full width, so text keeps scaling.
    var body: some View {
        Group {
            if layout == .singleColumn {
                // Each pill already carries 4pt above and below, so no extra spacing: 48pt rows.
                VStack(spacing: 0) { pills }
                    .padding(.horizontal, HomeMetrics.segmentPadding)
                    .background(RoundedRectangle(cornerRadius: HomeMetrics.segmentHeight / 2 + HomeMetrics.segmentPadding, style: .continuous).fill(MorrowColor.segmentTrack))
            } else {
                HStack(spacing: HomeMetrics.segmentGap) { pills }
                    .padding(.horizontal, HomeMetrics.segmentPadding)
                    .background(Capsule().fill(MorrowColor.segmentTrack))
            }
        }
    }

    @ViewBuilder private var pills: some View {
        ForEach(HomeTab.allCases) { tab in segment(tab) }
    }

    private func segment(_ tab: HomeTab) -> some View {
        let isSelected = selection == tab
        return Button { select(tab) } label: {
            Text(tab.title)
                .font(isSelected ? MorrowFont.segmentSelected : MorrowFont.segmentOff)
                .foregroundStyle(isSelected ? MorrowColor.action : MorrowColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: HomeMetrics.segmentHeight)
                .background(
                    Capsule()
                        .fill(isSelected ? MorrowColor.card : Color.clear)
                        .shadow(color: .black.opacity(isSelected ? 0.08 : 0), radius: 1, x: 0, y: 1)
                        .shadow(color: .black.opacity(isSelected ? 0.14 : 0), radius: 5, x: 0, y: 3)
                )
                .padding(.vertical, HomeMetrics.segmentPadding)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ tab: HomeTab) {
        guard tab != selection else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { selection = tab }
    }
}

#Preview("Segmented") {
    struct Host: View {
        @State var tab = HomeTab.notes
        var body: some View { CategorySegmentedControl(selection: $tab).padding().background(MorrowColor.ground) }
    }
    return Host()
}
