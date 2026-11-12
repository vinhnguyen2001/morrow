import SwiftData
import SwiftUI

@main
struct MorrowApp: App {
    private let model: HomeViewModel

    /// Composition root (ADR 0001): the only place that picks concrete implementations.
    init() {
        #if DEBUG
        // Screenshot fixtures: return before the real store is touched in any way.
        if LaunchFixtures.requested {
            model = LaunchFixtures.makeModel()
            return
        }
        #endif
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
        model = HomeViewModel(repository: SwiftDataMemoryRepository(container: container), photoStore: PhotoStore())
    }

    var body: some Scene {
        WindowGroup {
            HomeView(model: model)
        }
    }
}
