import UIKit
import XCTest
@testable import Morrow

final class ThumbnailCacheTests: XCTestCase {
    func testInsertLookupAndRemove() {
        let cache = ThumbnailCache(countLimit: 5)
        XCTAssertNil(cache.image(for: "a.jpg"))
        let image = UIImage()
        cache.insert(image, for: "a.jpg")
        XCTAssertTrue(cache.image(for: "a.jpg") === image)
        cache.remove(fileName: "a.jpg")
        XCTAssertNil(cache.image(for: "a.jpg"))
    }

    /// NSCache may evict at any time, so a view must keep its own reference (StoredPhotoView assigns a hit to
    /// its state). This locks the behaviour the view relies on: a lookup can return nil after other inserts.
    func testCountLimitCanEvictOlderEntries() {
        let cache = ThumbnailCache(countLimit: 1)
        for index in 0..<20 { cache.insert(UIImage(), for: "\(index).jpg") }
        let survivors = (0..<20).filter { cache.image(for: "\($0).jpg") != nil }
        XCTAssertLessThan(survivors.count, 20)
    }
}
