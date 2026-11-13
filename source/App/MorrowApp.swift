import SwiftData
import SwiftUI

@main
struct MorrowApp: App {
    private let model: HomeViewModel
    private let initialPath: [Route]
    private let initialTab: HomeTab
    private let showsCaptureOnLaunch: Bool

    /// Composition root (ADR 0001): the only place that picks concrete implementations.
    init() {
        #if DEBUG
        // Screenshot fixtures: return before the real store is touched in any way.
        if LaunchFixtures.requested {
            model = LaunchFixtures.makeModel()
            initialPath = LaunchFixtures.initialPath
            initialTab = LaunchFixtures.initialTab
            showsCaptureOnLaunch = LaunchFixtures.captureMode != nil
            return
        }
        #endif
        initialPath = []
        initialTab = .moments
        showsCaptureOnLaunch = false
        let container: ModelContainer
        do {
            container = try SwiftDataMemoryRepository.makeContainer()
        } catch {
            // Unrecoverable at launch: no store means nothing to show. Surfaces in crash logs.
            fatalError("Could not open the local store: \(error)")
        }
        #if DEBUG
        StoreLocation.logProtectionForDebug()
        #endif
        model = HomeViewModel(repository: SwiftDataMemoryRepository(container: container), photoStore: PhotoStore(),
                              locationProvider: SystemLocationProvider(), placeNamer: CLGeocoderPlaceNamer())
    }

    var body: some Scene {
        WindowGroup {
            HomeView(model: model, initialPath: initialPath, initialTab: initialTab, showsCaptureOnLaunch: showsCaptureOnLaunch)
        }
    }
}
