import SwiftUI

/// Home (T-005): header, "Recent moments" timeline or the empty state, floating Add button.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var pendingDelete: Memory?
    @State private var path: [Route]
    @Environment(\.scenePhase) private var scenePhase

    /// `initialPath` lets DEBUG fixtures open straight on a screen (screenshots); it is empty in normal use.
    init(model: HomeViewModel, initialPath: [Route] = []) {
        _model = State(initialValue: model)
        _path = State(initialValue: initialPath)
    }

    var body: some View {
        NavigationStack(path: $path) {
            home
                .toolbar(.hidden, for: .navigationBar) // Home and Detail draw their own header and Back button
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .memory(let id): MemoryDetailView(id: id, model: model)
                    }
                }
        }
        .environment(\.photoStore, model.photoStore)
        // The owner of the path trims it: a deleted memory must not leave a Detail on the stack (ADR 0009).
        .onChange(of: model.memories) { _, memories in
            let alive = Set(memories.map(\.id))
            let kept = path.filter { route in
                if case .memory(let id) = route { return alive.contains(id) }
                return true
            }
            if kept != path { path = kept }
        }
    }

    /// A quick double tap on a card must not push the same Detail twice.
    private func open(_ id: UUID) {
        guard path.last != .memory(id) else { return }
        path.append(.memory(id))
    }

    private var home: some View {
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
        .task { model.load() }
        // Cancelling skips the cleanup after the sleep, so reset the toast here (no animation: the screen is leaving).
        .onDisappear { toastTask?.cancel(); toast = nil }
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
            HomeTimeline(
                timeline: model.timeline,
                onOpen: { memory in open(memory.id) },
                onDelete: { memory in pendingDelete = memory }
            )
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
