import SwiftUI

/// The small card in the peek sheet (design lines 263-275): thumbnail, kind, title, place, and a chevron.
/// The whole row is one Button that opens the full memory.
struct MapPeekRow: View {
    let memory: Memory
    let onOpen: () -> Void
    @Environment(\.photoStore) private var photoStore

    private var style: MemoryKindStyle { MemoryKindStyle.style(for: memory.kind) }

    var body: some View {
        let place = MemoryDetailPresentation.placeText(for: memory)
        return Button(action: onOpen) {
            HStack(spacing: MapMetrics.rowGap) {
                thumbnail
                VStack(alignment: .leading, spacing: MapMetrics.rowTextGap) {
                    Text(style.displayName)
                        .font(MorrowFont.micro)
                        .foregroundStyle(style.ink)
                    Text(memory.title)
                        .font(MorrowFont.rowTitle)
                        .foregroundStyle(MorrowColor.ink)
                        .lineLimit(1)
                    if let place {
                        Text(place)
                            .font(MorrowFont.rowDetail)
                            .foregroundStyle(MorrowColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up")
                    .font(MorrowFont.icon)
                    .foregroundStyle(Color.white)
                    .frame(width: MapMetrics.expandButton, height: MapMetrics.expandButton)
                    .background(Circle().fill(MorrowColor.action))
            }
            .padding(MapMetrics.rowPadding)
            .background(RoundedRectangle(cornerRadius: MapMetrics.rowRadius, style: .continuous).fill(MorrowColor.card))
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: MapMetrics.rowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MapPins.label(kind: memory.kind, title: memory.title, place: place))
        .accessibilityHint("Opens the memory")
    }

    private var thumbnail: some View {
        Group {
            if let fileName = memory.photoFileName {
                StoredPhotoView(fileName: fileName, store: photoStore, placeholder: style.background)
            } else {
                ZStack {
                    style.background
                    Image(systemName: style.symbolName).font(MorrowFont.icon).foregroundStyle(style.ink)
                }
            }
        }
        .frame(width: MapMetrics.thumbnail, height: MapMetrics.thumbnail)
        .clipShape(RoundedRectangle(cornerRadius: MapMetrics.thumbnailRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
