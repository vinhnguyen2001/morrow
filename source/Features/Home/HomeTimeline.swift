import SwiftUI

/// "Recent moments" header and the lazy list of timeline rows.
struct HomeTimeline: View {
    let timeline: Timeline
    let onOpen: (Memory) -> Void
    let onDelete: (Memory) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: TimelineLayout { TimelineLayout(dynamicTypeSize: dynamicTypeSize) }

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader
                .padding(.top, HomeMetrics.sectionTop)
            LazyVStack(spacing: 0) {
                ForEach(timeline.rows) { row in
                    switch row {
                    case .sprout:
                        // Decorative; in one column the spine starts at the first day instead.
                        if layout == .twoColumn { TimelineSprout() }
                    case .day(let day):
                        DateBadge(day: day, layout: layout)
                    case .memory(let item):
                        TimelineMemoryRow(item: item, layout: layout, onOpen: onOpen, onDelete: onDelete)
                    case .origin:
                        TimelineOrigin(layout: layout)
                    }
                }
            }
            .padding(.top, HomeMetrics.timelineTop)
        }
    }

    private var sectionHeader: some View {
        // Side by side normally; stacked at accessibility sizes so the title is not squeezed.
        let content = Group {
            Text("Recent moments")
                .font(MorrowFont.sectionTitle)
                .foregroundStyle(MorrowColor.ink)
                .accessibilityAddTraits(.isHeader)
            if layout == .twoColumn { Spacer() }
            if let since = timeline.sinceText {
                Text("since \(since)")
                    .font(MorrowFont.sectionMeta)
                    .foregroundStyle(MorrowColor.action)
            }
        }
        return Group {
            if layout == .twoColumn {
                HStack(alignment: .firstTextBaseline) { content }
            } else {
                VStack(alignment: .leading, spacing: 2) { content }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
