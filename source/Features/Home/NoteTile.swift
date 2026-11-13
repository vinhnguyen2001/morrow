import SwiftUI

/// One note on the Notes tab (Main.dc.html lines 169-175): coloured card, "NOTE" kicker, title, preview,
/// short date and place. A button that opens the note's Detail. Tilt is 0 in one column and under Reduce Motion.
struct NoteTile: View {
    let card: NoteCard
    let layout: TimelineLayout
    let onOpen: (UUID) -> Void

    var body: some View {
        Button { onOpen(card.id) } label: {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, HomeMetrics.noteInsetTop)
                .padding(.top, HomeMetrics.noteInsetTop)
                .padding(.bottom, HomeMetrics.noteInsetBottom)
                .background {
                    RoundedRectangle(cornerRadius: HomeMetrics.noteRadius, style: .continuous)
                        .fill(card.tone == .peach ? MorrowColor.notePeach : MorrowColor.noteLavender)
                        .morrowCardShadow()
                }
        }
        .buttonStyle(.plain)
        .tilt(degrees: layout == .twoColumn ? card.tilt : 0)
        .accessibilityLabel(card.accessibilityLabel)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: HomeMetrics.noteSpacing) {
            HStack {
                Text("NOTE")
                    .font(MorrowFont.noteKicker)
                    .tracking(0.6)
                Spacer()
                Image(systemName: MemoryKindStyle.style(for: .note).symbolName)
                    .font(MorrowFont.noteTitle)
            }
            .foregroundStyle(MorrowColor.noteInk)
            Text(card.title)
                .font(MorrowFont.noteTitle)
                .foregroundStyle(MorrowColor.ink)
                .multilineTextAlignment(.leading)
            if let preview = card.preview {
                Text(preview)
                    .font(MorrowFont.notePreview)
                    .foregroundStyle(MorrowColor.textSecondary)
                    .lineLimit(card.lineLimit)
                    .multilineTextAlignment(.leading)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(card.dateText)
                    .font(MorrowFont.noteDate)
                    .foregroundStyle(MorrowColor.action)
                if let place = card.placeName {
                    Text(place)
                        .font(MorrowFont.noteMeta)
                        .foregroundStyle(MorrowColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 2)
        }
    }
}
