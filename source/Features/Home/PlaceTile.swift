import SwiftUI

/// One place on the Places tab (Main.dc.html lines 192-201): white card, photo with a "N memories" pill,
/// name and "Last: <date>". Not a button: there is no Place screen yet (T-005 step 7), so no dead tap
/// and no chevron. It is one VoiceOver element.
struct PlaceTile: View {
    let card: PlaceCard

    @Environment(\.photoStore) private var photoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
                .frame(height: card.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: HomeMetrics.placeImageRadius, style: .continuous))
                .overlay(alignment: .bottomLeading) { pill.padding(8) }
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(MorrowFont.rowTitle)
                    .foregroundStyle(MorrowColor.ink)
                    .multilineTextAlignment(.leading)
                Text(card.lastText)
                    .font(MorrowFont.rowDetail)
                    .foregroundStyle(MorrowColor.textSecondary)
            }
            .padding(.top, 9)
            .padding(.horizontal, HomeMetrics.placeCardPadding)
            .padding(.bottom, HomeMetrics.placeCardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(HomeMetrics.placeCardPadding)
        .background {
            RoundedRectangle(cornerRadius: HomeMetrics.placeCardRadius, style: .continuous)
                .fill(MorrowColor.card)
                .morrowCardShadow()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.accessibilityLabel)
    }

    @ViewBuilder
    private var cover: some View {
        let style = MemoryKindStyle.style(for: .photo)
        if let fileName = card.coverFileName {
            StoredPhotoView(fileName: fileName, store: photoStore, placeholder: style.background)
        } else {
            style.background.overlay {
                Image(systemName: "mappin")
                    .font(MorrowFont.glyph)
                    .foregroundStyle(MorrowColor.textSecondary)
            }
        }
    }

    private var pill: some View {
        HStack(spacing: 4) {
            LeafMark(size: 11, showsVein: false)
            Text(card.countText)
                .font(MorrowFont.micro)
                .foregroundStyle(MorrowColor.action)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.94)))
    }
}
