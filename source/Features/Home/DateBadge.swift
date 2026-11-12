import SwiftUI

/// Day header on the spine: green 46pt badge with the day number, weekday and month beside it.
/// One VoiceOver header element ("Today, Thursday, November 12").
struct DateBadge: View {
    let day: DayHeader
    let layout: TimelineLayout

    var body: some View {
        Group {
            switch layout {
            case .twoColumn: twoColumn
            case .singleColumn: singleColumn
            }
        }
        .padding(.top, HomeMetrics.dayRowTop)
        .padding(.bottom, HomeMetrics.dayRowBottom)
        .background(alignment: layout == .twoColumn ? .center : .leading) { SpineLine(layout: layout) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.accessibilityLabel)
        .accessibilityAddTraits(.isHeader)
    }

    // Main.dc.html lines 92-100 puts the badge group at margin-left -23 between two flexible spacers.
    // Taken literally the spine runs through the labels. The 4pt ground ring only makes sense when the
    // spine passes behind the badge, so the badge is centred on the spine and the labels sit to its right.
    private var twoColumn: some View {
        HStack(spacing: 0) {
            Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            badge
            labels
                .padding(.leading, HomeMetrics.dayBadgeGap)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var singleColumn: some View {
        HStack(spacing: HomeMetrics.dayBadgeGap) {
            badge
            labels.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badge: some View {
        Text(day.number)
            .font(MorrowFont.dayNumber)
            .tracking(-0.5)
            .foregroundStyle(.white)
            .frame(width: HomeMetrics.dayBadge, height: HomeMetrics.dayBadge)
            .background(Circle().fill(MorrowColor.action))
            .background(Circle().fill(MorrowColor.ground).padding(-HomeMetrics.dayBadgeRing))
            .shadow(color: MorrowColor.action.opacity(0.35), radius: 8, x: 0, y: 6)
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(day.weekday).font(MorrowFont.rowTitle).foregroundStyle(MorrowColor.ink)
            Text(day.monthYear).font(MorrowFont.rowDetail).foregroundStyle(MorrowColor.textSecondary)
        }
    }
}

/// How the timeline is laid out: two columns around a centre spine, or one column with the spine at the left
/// (accessibility text sizes).
enum TimelineLayout: Equatable {
    case twoColumn
    case singleColumn

    init(dynamicTypeSize: DynamicTypeSize) {
        self = dynamicTypeSize.isAccessibilitySize ? .singleColumn : .twoColumn
    }

    /// Width of the spine gutter in the single-column layout; the spine is centred in it.
    static let gutter: CGFloat = HomeMetrics.dayBadge
}

/// Vertical spine segment filling its parent's height, centred (two columns) or in the left gutter.
struct SpineLine: View {
    let layout: TimelineLayout

    var body: some View {
        Rectangle()
            .fill(MorrowColor.leaf)
            .frame(width: HomeMetrics.spineWidth)
            .padding(.leading, layout == .singleColumn ? TimelineLayout.gutter / 2 - HomeMetrics.spineWidth / 2 : 0)
            .accessibilityHidden(true)
    }
}
