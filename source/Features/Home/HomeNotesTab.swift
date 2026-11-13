import SwiftUI

/// Notes tab (Main.dc.html lines 156-179): title, "New note", two lazy columns of note tiles.
struct HomeNotesTab: View {
    let cards: TwoColumns<NoteCard>
    let onNewNote: () -> Void
    let onOpen: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: TimelineLayout { TimelineLayout(dynamicTypeSize: dynamicTypeSize) }

    var body: some View {
        VStack(spacing: 0) {
            HomeSectionHeader(title: "Notes", layout: layout, alignment: .center) { newNoteButton }
                .padding(.top, HomeMetrics.sectionTop)
            if cards.isEmpty {
                BlankPage(title: "a blank page", text: "Thoughts and little details you write on the road will live here.")
            } else {
                StaggeredColumns(
                    columns: cards, layout: layout, rightColumnOffset: HomeMetrics.noteColumnOffset,
                    rowSpacing: HomeMetrics.columnGap
                ) { card in
                    NoteTile(card: card, layout: layout, onOpen: onOpen)
                }
                .padding(.top, HomeMetrics.tabListTop)
            }
        }
    }

    /// Drawn 40pt high with a 44pt tap area.
    private var newNoteButton: some View {
        Button(action: onNewNote) {
            Label("New note", systemImage: "plus")
                .font(MorrowFont.smallButton)
                .foregroundStyle(MorrowColor.noteInk)
                .padding(.horizontal, 14)
                .frame(minHeight: HomeMetrics.newNoteHeight)
                .background(Capsule().fill(MorrowColor.noteLavender))
                .padding(.vertical, (MorrowLayout.minHitSize - HomeMetrics.newNoteHeight) / 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
