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
    /// `timeText` is the already formatted time of day, added at the end when known.
    static func label(for memory: Memory, timeText: String? = nil) -> String {
        var parts = [MemoryKindStyle.style(for: memory.kind).displayName, memory.title]
        if let place = memory.placeName, !place.isEmpty {
            parts.append("at \(place)")
        }
        if let timeText, !timeText.isEmpty {
            parts.append(timeText)
        }
        return parts.joined(separator: ", ")
    }
}

/// One card view, switching on kind. Exposed to accessibility as a single element (a button only when it has an action).
struct MemoryCard: View {
    let memory: Memory
    var density: MemoryCardDensity = .compact
    /// Photo height override (the timeline varies it); nil uses the density's height.
    var imageHeight: CGFloat?
    /// Formatted time of day, for the note's corner and the VoiceOver label.
    var timeText: String?
    /// Nil when the card does nothing yet (no dead buttons, ADR 0010): it is then plain content with a label,
    /// not a Button. With an action it is a button.
    var action: (() -> Void)?

    @Environment(\.photoStore) private var photoStore

    private var style: MemoryKindStyle { .style(for: memory.kind) }

    private var label: String { MemoryCardAccessibility.label(for: memory, timeText: timeText) }

    private var card: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MorrowColor.card)
            .clipShape(RoundedRectangle(cornerRadius: MorrowRadius.card, style: .continuous))
    }

    @ViewBuilder
    var body: some View {
        if let action {
            Button(action: action) { card }
                .buttonStyle(.plain)
                .morrowCardShadow()
                .accessibilityLabel(label)
        } else {
            card
                .morrowCardShadow()
                .accessibilityElement(children: .combine)
                .accessibilityLabel(label)
        }
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

    // Stored photo when there is one, otherwise the kind placeholder (samples, failed loads).
    private var photoContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            photoArea
                .frame(height: imageHeight ?? density.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous))
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

    @ViewBuilder
    private var photoArea: some View {
        if let fileName = memory.photoFileName {
            StoredPhotoView(fileName: fileName, store: photoStore, placeholder: style.background)
        } else {
            style.background.overlay {
                Image(systemName: style.symbolName)
                    .font(MorrowFont.glyph)
                    .foregroundStyle(MorrowColor.textSecondary)
            }
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
                timeLabel
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

    @ViewBuilder
    private var timeLabel: some View {
        if let timeText {
            Text(timeText)
        } else {
            Text(memory.createdAt, format: .dateTime.hour().minute())
        }
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
