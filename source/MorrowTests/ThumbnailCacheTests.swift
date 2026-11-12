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

    // Not tested: NSCache.countLimit is not a strict bound, so an eviction test would check Apple's behaviour and
    // could flicker. StoredPhotoView keeps its own reference to a hit because any entry may vanish at any time.
}
