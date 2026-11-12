import SwiftUI

@main
struct MorrowApp: App {
    var body: some Scene {
        WindowGroup {
            // M0: the design-system gallery is the only screen.
            MemoryCardGallery()
        }
    }
}
