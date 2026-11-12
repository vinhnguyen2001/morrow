import SwiftUI

/// Home (T-005): header, "Recent moments" timeline or the empty state, floating Add button.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var toast: String?
    @State private var pendingDelete: Memory?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GroundView()
            ScrollView {
                VStack(spacing: 0) {
                    MorrowHeader(onNotifications: showNotificationsNotice, onSettings: { showSettings = true })
                        .padding(.top, HomeMetrics.pageTopBelowStatusBar)
                    content
                    if let message = model.errorMessage {
                        Text(message)
                            .font(MorrowFont.caption)
                            .foregroundStyle(MorrowColor.error)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, HomeMetrics.pageSide)
                .padding(.bottom, HomeMetrics.pageBottom)
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
        // "Today" and the day groups follow the clock, so refresh when the app comes back.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.load() }
        }
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

    @ViewBuilder
    private var content: some View {
        if !model.hasLoaded {
            Color.clear.frame(height: 1)
        } else if model.timeline.rows.isEmpty {
            HomeEmptyState { showCapture = true }
        } else {
            HomeTimeline(timeline: model.timeline) { memory in pendingDelete = memory }
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
}

#if DEBUG
#Preview("Home with fixtures") {
    HomeView(model: LaunchFixtures.makeModel())
}
#endif
