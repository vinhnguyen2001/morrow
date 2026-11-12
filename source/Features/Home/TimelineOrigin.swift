import SwiftUI

/// End of the timeline: a short stem, a dot and "where it all began" (Main.dc.html lines 144-150).
struct TimelineOrigin: View {
    let layout: TimelineLayout

    var body: some View {
        Group {
            switch layout {
            case .twoColumn:
                VStack(spacing: HomeMetrics.originGap) { stem; dot; label }
                    .frame(maxWidth: .infinity)
            case .singleColumn:
                HStack(alignment: .top, spacing: HomeMetrics.dayBadgeGap) {
                    VStack(spacing: HomeMetrics.originGap) { stem; dot }
                        .frame(width: TimelineLayout.gutter)
                    label.padding(.top, HomeMetrics.originStem + HomeMetrics.originGap)
                }
            }
        }
        .padding(.top, HomeMetrics.originTop)
    }

    private var stem: some View {
        Rectangle().fill(MorrowColor.leaf)
            .frame(width: HomeMetrics.spineWidth, height: HomeMetrics.originStem)
            .accessibilityHidden(true)
    }

    private var dot: some View {
        Circle().fill(MorrowColor.leaf)
            .frame(width: HomeMetrics.originDot, height: HomeMetrics.originDot)
            .accessibilityHidden(true)
    }

    private var label: some View {
        Text("where it all began ·")
            .font(MorrowFont.sectionMeta)
            .foregroundStyle(MorrowColor.textSecondary)
    }
}
