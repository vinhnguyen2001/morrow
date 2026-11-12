import SwiftUI

enum MemoryCardDensity {
    case compact
    case wide

    var imageHeight: CGFloat { self == .compact ? 150 : 200 }
    var bodyLineLimit: Int { self == .compact ? 3 : 5 }
    var titleFont: Font { self == .compact ? MorrowFont.cardTitleCompact : MorrowFont.cardTitleWide }
}

/// Builds the single VoiceOver description for a card. Pure, unit tested.
enum MemoryCardAccessibility {
    static func label(for memory: Memory) -> String {
        var parts = [MemoryKindStyle.style(for: memory.kind).displayName, memory.title]
        if let place = memory.placeName, !place.isEmpty {
            parts.append("at \(place)")
        }
        return parts.joined(separator: ", ")
    }
}

/// One card view, switching on kind. Exposed to accessibility as a single button.
struct MemoryCard: View {
    let memory: Memory
    var density: MemoryCardDensity = .compact
    var action: () -> Void = {}

    private var style: MemoryKindStyle { .style(for: memory.kind) }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MorrowColor.card)
                .clipShape(RoundedRectangle(cornerRadius: MorrowRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .morrowCardShadow()
        .accessibilityLabel(MemoryCardAccessibility.label(for: memory))
    }

    @ViewBuilder
    private var content: some View {
        switch memory.kind {
        case .photo:
            photoContent
        case .note:
            noteContent
        }
    }

    // M0: photos render a placeholder; real images arrive with persistence.
    private var photoContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous)
                .fill(style.background)
                .frame(height: density.imageHeight)
                .overlay {
                    Image(systemName: style.symbolName)
                        .font(MorrowFont.glyph)
                        .foregroundStyle(MorrowColor.textSecondary)
                }
                .padding(7)
            VStack(alignment: .leading, spacing: 3) {
                titleText
                placeText
            }
            .padding(.horizontal, 13)
            .padding(.top, 3)
            .padding(.bottom, 13)
        }
    }

    private var noteContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: style.symbolName)
                    .font(MorrowFont.glyph)
                    .foregroundStyle(style.ink)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(style.background))
                    .rotationEffect(.degrees(-6))
                Spacer()
                Text(memory.createdAt, format: .dateTime.hour().minute())
                    .font(MorrowFont.caption)
                    .foregroundStyle(MorrowColor.textSecondary)
            }
            VStack(alignment: .leading, spacing: 5) {
                titleText
                placeText
                if let body = memory.body, !body.isEmpty {
                    Text(body)
                        .font(MorrowFont.body)
                        .foregroundStyle(MorrowColor.textBody)
                        .lineLimit(density.bodyLineLimit)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(14)
    }

    private var titleText: some View {
        Text(memory.title)
            .font(density.titleFont)
            .foregroundStyle(MorrowColor.ink)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var placeText: some View {
        if let place = memory.placeName, !place.isEmpty {
            Label(place, systemImage: "mappin")
                .font(MorrowFont.caption)
                .foregroundStyle(MorrowColor.textSecondary)
                .lineLimit(1)
        }
    }
}
