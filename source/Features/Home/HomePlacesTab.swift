import SwiftUI

/// Places tab (Main.dc.html lines 181-205): "Places you've been", a count, two lazy columns of place tiles.
struct HomePlacesTab: View {
    let cards: TwoColumns<PlaceCard>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: TimelineLayout { TimelineLayout(dynamicTypeSize: dynamicTypeSize) }

    var body: some View {
        VStack(spacing: 0) {
            HomeSectionHeader(title: "Places you\u{2019}ve been", layout: layout) {
                Text(cards.all.count == 1 ? "1 place" : "\(cards.all.count) places")
                    .font(MorrowFont.sectionMeta)
                    .foregroundStyle(MorrowColor.action)
            }
            .padding(.top, HomeMetrics.sectionTop)
            if cards.isEmpty {
                BlankPage(title: "no pins yet", text: "Every place you leave a memory becomes a little landmark here.")
            } else {
                StaggeredColumns(
                    columns: cards, layout: layout, rightColumnOffset: HomeMetrics.placeColumnOffset,
                    rowSpacing: HomeMetrics.placeRowGap
                ) { card in
                    PlaceTile(card: card)
                }
                .padding(.top, HomeMetrics.tabListTop)
            }
        }
    }
}
