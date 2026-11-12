import UIKit

/// Decoded thumbnails kept in memory, keyed by the photo file name (a UUID, never a path).
/// NSCache is thread safe and drops entries under memory pressure.
final class ThumbnailCache: @unchecked Sendable {
    static let shared = ThumbnailCache()

    private let storage = NSCache<NSString, UIImage>()

    init(countLimit: Int = 60) {
        storage.countLimit = countLimit
    }

    func image(for fileName: String) -> UIImage? {
        storage.object(forKey: fileName as NSString)
    }

    func insert(_ image: UIImage, for fileName: String) {
        storage.setObject(image, forKey: fileName as NSString)
    }

    func remove(fileName: String) {
        storage.removeObject(forKey: fileName as NSString)
    }
}
