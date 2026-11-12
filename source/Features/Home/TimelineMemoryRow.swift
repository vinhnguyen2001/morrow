import SwiftUI

/// One memory on the timeline: card on one side, time and day part on the other, curved connector, dot, leaf.
/// Two columns by default; one column with no tilt at accessibility text sizes.
struct TimelineMemoryRow: View {
    let item: TimelineItem
    let layout: TimelineLayout
    let onOpen: (Memory) -> Void
    let onDelete: (Memory) -> Void

    var body: some View {
        Group {
            switch layout {
            case .twoColumn: twoColumn
            case .singleColumn: singleColumn
            }
        }
    }

    // Main.dc.html lines 112-137.
    private var twoColumn: some View {
        let stagger = item.stagger
        return HStack(alignment: .top, spacing: 0) {
            column(isCard: stagger.isLeft)
            Color.clear.frame(width: HomeMetrics.connectorWidth)
            column(isCard: !stagger.isLeft)
        }
        .padding(.top, HomeMetrics.memoryRowTop)
        .padding(.bottom, HomeMetrics.memoryRowBottom)
        .background {
            TimelineConnector(cardOnLeft: stagger.isLeft)
                .stroke(MorrowColor.leaf, style: StrokeStyle(lineWidth: HomeMetrics.spineWidth, lineCap: .round))
                .frame(width: HomeMetrics.connectorWidth)
                .accessibilityHidden(true)
        }
        .overlay { leaf(stagger).allowsHitTesting(false) }
        .overlay(alignment: .top) {
            dot.padding(.top, HomeMetrics.rowDotTop).allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func column(isCard: Bool) -> some View {
        let stagger = item.stagger
        if isCard {
            card
                .padding(.top, stagger.offset)
                .tilt(degrees: stagger.tilt)
                .frame(maxWidth: .infinity)
        } else {
            sideText(alignment: stagger.isLeft ? .leading : .trailing)
                .padding(.top, HomeMetrics.sideTextTop)
                .padding(stagger.isLeft ? .leading : .trailing, HomeMetrics.sideTextInset)
                .frame(maxWidth: .infinity, alignment: stagger.isLeft ? .leading : .trailing)
        }
    }

    private var card: some View {
        // Open and Delete are attached to the card itself: it is the one accessibility element of the row.
        MemoryCard(memory: item.memory, density: .compact, imageHeight: item.stagger.imageHeight, timeText: item.timeText,
                   action: { onOpen(item.memory) })
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) { onDelete(item.memory) }
            }
            .accessibilityAction(named: "Delete") { onDelete(item.memory) }
    }

    /// Time and day part. Hidden from VoiceOver: the card label already carries the time.
    private func sideText(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(item.timeText).font(MorrowFont.rowTitle).foregroundStyle(MorrowColor.ink)
            Text(item.dayPart.title).font(MorrowFont.rowDetail).foregroundStyle(MorrowColor.textSecondary)
        }
        .accessibilityHidden(true)
    }

    private func leaf(_ stagger: Stagger) -> some View {
        FractionalPosition(
            yFraction: stagger.leafFraction,
            centerOffsetX: stagger.isLeft ? HomeMetrics.leafSideOffset : -(HomeMetrics.leafSideOffset + HomeMetrics.leafSize)
        ) {
            LeafMark(fill: stagger.leafIsLight ? MorrowColor.leafLight : MorrowColor.leaf)
                .rotationEffect(.degrees(stagger.leafRotation))
        }
    }

    private var dot: some View {
        Circle()
            .fill(MorrowColor.ground)
            .overlay(Circle().strokeBorder(MorrowColor.leaf, lineWidth: HomeMetrics.rowDotBorder))
            .frame(width: HomeMetrics.rowDot, height: HomeMetrics.rowDot)
            .accessibilityHidden(true)
    }

    private var singleColumn: some View {
        HStack(alignment: .top, spacing: HomeMetrics.dayBadgeGap) {
            dot.padding(.top, HomeMetrics.rowDotTop)
                .frame(width: TimelineLayout.gutter)
            VStack(alignment: .leading, spacing: 6) {
                card
                HStack(spacing: 6) {
                    Text(item.timeText).font(MorrowFont.rowTitle).foregroundStyle(MorrowColor.ink)
                    Text(item.dayPart.title).font(MorrowFont.rowDetail).foregroundStyle(MorrowColor.textSecondary)
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.top, HomeMetrics.memoryRowTop)
        .padding(.bottom, HomeMetrics.memoryRowBottom)
        .background(alignment: .leading) { SpineLine(layout: .singleColumn) }
    }
}
