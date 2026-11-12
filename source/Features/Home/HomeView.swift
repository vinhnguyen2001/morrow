import SwiftUI

/// Home (T-005): header, memories, floating Add button.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var toast: String?
    @State private var pendingDelete: Memory?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// One column at accessibility text sizes so titles are not squeezed.
    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        ZStack {
            GroundView()
            VStack(spacing: 0) {
                MorrowHeader(onNotifications: showNotificationsNotice, onSettings: { showSettings = true })
                    .padding(.horizontal, HomeMetrics.pageSide)
                    .padding(.top, HomeMetrics.pageTopBelowStatusBar)
                    .padding(.bottom, 12)
                if model.memories.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            FloatingActionBar { showCapture = true }
        }
        .overlay(alignment: .top) {
            if let toast {
                Toast(message: toast)
                    .padding(.top, HomeMetrics.pageTopBelowStatusBar + HomeMetrics.headerHeight + 12)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .environment(\.photoStore, model.photoStore)
        .task { model.load() }
        .sheet(isPresented: $showCapture) {
            CaptureSheet(model: model.makeCapture()) {
                model.load()
            }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .deleteConfirmation(for: $pendingDelete) { memory in
            Task { await model.delete(memory) }
        }
    }

    /// The bell is placeholder chrome: it says so instead of showing fake content.
    private func showNotificationsNotice() {
        let message = MorrowPlaceholders.notificationsMessage
        AccessibilityNotification.Announcement(message).post()
        withAnimation(.easeOut(duration: 0.25)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(model.memories) { memory in
                    MemoryCard(memory: memory, density: .compact)
                        .tilt(for: memory.id)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = memory }
                        }
                        .accessibilityAction(named: "Delete") { pendingDelete = memory }
                }
            }
            .padding(.horizontal, HomeMetrics.pageSide)
            .padding(.bottom, HomeMetrics.pageBottom)
            if let message = model.errorMessage {
                Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("No memories yet")
                .font(MorrowFont.emptyTitle)
                .foregroundStyle(MorrowColor.ink)
            Text("Tap + to save a photo or a note.")
                .font(MorrowFont.body)
                .foregroundStyle(MorrowColor.textSecondary)
            if let message = model.errorMessage {
                Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Home with fixtures") {
    HomeView(model: LaunchFixtures.makeModel())
}
#endif
