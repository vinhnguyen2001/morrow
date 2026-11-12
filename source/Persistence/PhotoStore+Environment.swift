import SwiftUI

private struct PhotoStoreKey: EnvironmentKey {
    static let defaultValue = PhotoStore()
}

extension EnvironmentValues {
    var photoStore: PhotoStore {
        get { self[PhotoStoreKey.self] }
        set { self[PhotoStoreKey.self] = newValue }
    }
}
