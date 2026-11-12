import SwiftUI

/// Home (T-005): header, "Recent moments" timeline or the empty state, floating Add button.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
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

    /// PLACEHOLDER (release blocker, see MorrowPlaceholders): the bell says so instead of showing fake content.
    private func showNotificationsNotice() {
        let message = MorrowPlaceholders.notificationsMessage
        var announcement = AttributedString(message)
        // iOS 17: keep VoiceOver from cutting the announcement short. Needs a check on a real device.
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
        withAnimation(.easeOut(duration: 0.25)) { toast = message }
        toastTask?.cancel() // a second tap restarts the timer instead of hiding the toast early
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }
}

#if DEBUG
#Preview("Home with fixtures") {
    HomeView(model: LaunchFixtures.makeModel())
}
#endif
