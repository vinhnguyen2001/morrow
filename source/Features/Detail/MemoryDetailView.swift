import SwiftUI

/// Memory Detail (T-004 step 3): large photo or coloured header, title, place and privacy chips, date, note, Delete.
/// Receives an id and looks the memory up in the shared `HomeViewModel` (ADR 0009), so it is never stale
/// and goes back by itself when the memory is gone.
struct MemoryDetailView: View {
    let id: UUID
    let model: HomeViewModel
    @State private var pendingDelete: Memory?
    /// Last non-nil memory: once a delete removes it from the model, the screen keeps drawing this while it pops.
    @State private var lastShown: Memory?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.photoStore) private var photoStore

    private var memory: Memory? { model.memory(id: id) }

    var body: some View {
        ZStack(alignment: .top) {
            GroundView()
            if let memory = memory ?? lastShown {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(for: memory)
                        details(for: memory)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .ignoresSafeArea(edges: .top) // the photo or colour runs under the status bar
            }
            CircleIconButton(systemImage: "chevron.left", label: "Back", diameter: DetailMetrics.backButton, showsShadow: true) { dismiss() }
                .accessibilitySortPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, DetailMetrics.backSide)
                .padding(.top, DetailMetrics.backTopBelowStatusBar)
        }
        .accessibilityElement(children: .contain)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: memory, initial: true) { _, new in if let new { lastShown = new } }
        .onChange(of: model.errorMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
        // Fires on arrival and whenever the memory disappears (deleted here or elsewhere).
        .task(id: memory == nil) { if memory == nil { dismiss() } }
        .deleteConfirmation(for: $pendingDelete) { item in
            Task { await model.delete(item) }
        }
    }

    private var chipLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                                            : AnyLayout(HStackLayout(spacing: 8))
    }

    private var photoShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(bottomLeadingRadius: MorrowRadius.sheet, bottomTrailingRadius: MorrowRadius.sheet, style: .continuous)
    }

    // MARK: Header (design lines 415-419)

    @ViewBuilder
    private func header(for memory: Memory) -> some View {
        if let fileName = memory.photoFileName {
            StoredPhotoView(
                fileName: fileName, store: photoStore, placeholder: MemoryKindStyle.style(for: memory.kind).background,
                variant: .display, accessibilityText: "Photo"
            )
            .frame(height: DetailMetrics.photoHeight)
            .clipShape(photoShape)
        } else {
            let style = MemoryKindStyle.style(for: memory.kind)
            VStack(alignment: .leading, spacing: DetailMetrics.headerGap) {
                Text(MemoryDetailPresentation.kicker(for: memory.kind))
                    .font(MorrowFont.detailKicker)
                    .foregroundStyle(style.ink)
                title(of: memory)
            }
            .padding(.top, DetailMetrics.headerTop)
            .padding(.horizontal, DetailMetrics.headerSide)
            .padding(.bottom, DetailMetrics.headerBottom)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topTrailing) {
                ZStack(alignment: .topTrailing) {
                    style.background
                    LeafMark(fill: MorrowColor.leaf.opacity(DetailMetrics.leafOpacity), size: DetailMetrics.leafSize, showsVein: false)
                        .offset(x: DetailMetrics.leafBleed, y: DetailMetrics.leafTop)
                }
            }
            .clipShape(photoShape)
        }
    }

    // MARK: Text block (design lines 434-447)

    private func details(for memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: DetailMetrics.contentGap) {
            chipLayout {
                if let place = MemoryDetailPresentation.placeText(for: memory) {
                    Chip(place, systemImage: "mappin", background: MorrowColor.placeChipBackground, foreground: MorrowColor.placeChipText)
                }
                // Everything is stored on this device only, so "Private" is true.
                Chip("Private", background: MorrowColor.neutralChipBackground, foreground: MorrowColor.textSecondary)
            }
            if memory.photoFileName != nil { title(of: memory) }
            Text(MemoryDetailPresentation.dateText(for: memory, calendar: model.calendar))
                .font(MorrowFont.rowDetail)
                .foregroundStyle(MorrowColor.textSecondary)
            if let body = MemoryDetailPresentation.bodyText(for: memory) {
                Text(body)
                    .font(MorrowFont.detailBody)
                    .lineSpacing(DetailMetrics.bodyLineSpacing)
                    .foregroundStyle(MorrowColor.textBody)
                    .textSelection(.enabled)
            }
            if let message = model.errorMessage {
                Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
            }
            deleteButton(for: memory)
                .padding(.top, DetailMetrics.contentGap)
        }
        .padding(.top, DetailMetrics.contentTop)
        .padding(.horizontal, DetailMetrics.contentSide)
        .padding(.bottom, DetailMetrics.contentBottom)
    }

    private func title(of memory: Memory) -> some View {
        Text(memory.title)
            .font(MorrowFont.detailTitle)
            .tracking(DetailMetrics.titleTracking)
            .foregroundStyle(MorrowColor.ink)
            .multilineTextAlignment(.leading)
            .accessibilityAddTraits(.isHeader)
    }

    private func deleteButton(for memory: Memory) -> some View {
        Button(role: .destructive) { pendingDelete = memory } label: {
            Label("Delete memory", systemImage: "trash")
                .font(MorrowFont.actionLabel)
                .foregroundStyle(MorrowColor.error)
                .frame(maxWidth: .infinity, minHeight: DetailMetrics.deleteHeight)
                .background(Capsule().fill(MorrowColor.card))
        }
        .buttonStyle(.plain)
    }
}
