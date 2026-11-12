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
}
