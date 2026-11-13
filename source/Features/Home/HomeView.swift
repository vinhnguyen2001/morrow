import SwiftUI

/// Home (T-005): header, "Recent moments" timeline or the empty state, floating Add button.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture: Bool
    /// What the Capture sheet opens on: photo from Add, note from "New note".
    @State private var captureKind: MemoryKind = .photo
    @State private var tab: HomeTab
    @State private var showSettings = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var pendingDelete: Memory?
    @State private var path: [Route]
    @Environment(\.scenePhase) private var scenePhase

    /// `initialPath` lets DEBUG fixtures open straight on a screen (screenshots); it is empty in normal use.
    init(model: HomeViewModel, initialPath: [Route] = [], initialTab: HomeTab = .moments, showsCaptureOnLaunch: Bool = false) {
        _tab = State(initialValue: initialTab)
        _showCapture = State(initialValue: showsCaptureOnLaunch)
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
                    case .map: MapView(model: model)
                    }
                }
        }
        .environment(\.photoStore, model.photoStore)
        // The owner of the path trims it: a deleted memory must not leave a Detail on the stack (ADR 0009).
        .onChange(of: model.memories) { _, memories in
            let kept = Route.trimmed(path, alive: Set(memories.map(\.id)))
            if kept != path { path = kept }
        }
    }

    /// A quick double tap on a card must not push the same Detail twice.
    private func open(_ id: UUID) {
        guard path.last != .memory(id) else { return }
        model.clearError()
        path.append(.memory(id))
    }

    private func startCapture(_ kind: MemoryKind) {
        captureKind = kind
        showCapture = true
    }

    private func openMap() {
        guard path.last != .map else { return }
        model.clearError()
        path.append(.map)
    }

    private var home: some View {
        ZStack {
            GroundView()
            ScrollView {
                VStack(spacing: 0) {
                    MorrowHeader(onNotifications: showNotificationsNotice, onSettings: { showSettings = true })
                        .padding(.top, HomeMetrics.pageTopBelowStatusBar)
                    CategorySegmentedControl(selection: $tab)
                        .padding(.top, HomeMetrics.segmentTop)
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
            FloatingActionBar(onMap: openMap) { startCapture(.photo) }
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
            CaptureSheet(model: model.makeCapture(initialKind: captureKind)) {
                model.load()
            }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .deleteConfirmation(for: $pendingDelete) { memory in
            Task { await model.delete(memory) }
        }
    }

    /// Each tab reads only its own projection from the model, so a change in one does not re-render the others.
    @ViewBuilder
    private var content: some View {
        if !model.hasLoaded {
            Color.clear.frame(height: 1)
        } else {
            switch tab {
            case .moments: momentsTab
            case .notes:
                HomeNotesTab(cards: model.noteCards, onNewNote: { startCapture(.note) }, onOpen: open)
            case .places:
                HomePlacesTab(cards: model.placeCards)
            }
        }
    }

    @ViewBuilder
    private var momentsTab: some View {
        if model.timeline.rows.isEmpty {
            HomeEmptyState { startCapture(.photo) }
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
