import ImageIO
import UIKit
import UniformTypeIdentifiers
import XCTest
@testable import Morrow

final class PhotoStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func jpeg(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // pixels, not points: the screen scale would triple the size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.jpegData(withCompressionQuality: 1) { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func pixelSize(of data: Data) throws -> (Int, Int) {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let width = try XCTUnwrap(props[kCGImagePropertyPixelWidth] as? Int)
        let height = try XCTUnwrap(props[kCGImagePropertyPixelHeight] as? Int)
        XCTAssertGreaterThan(width, 0)
        XCTAssertGreaterThan(height, 0)
        return (width, height)
    }

    func testSaveCapsFullAndThumbnailSizes() throws {
        let store = PhotoStore(directory: dir)
        let id = UUID()
        let name = try store.save(imageData: jpeg(width: 3000, height: 1500), id: id)
        XCTAssertEqual(name, "\(id.uuidString).jpg")

        let full = try Data(contentsOf: dir.appending(path: name))
        let thumb = try XCTUnwrap(store.thumbnailData(for: name))
        XCTAssertLessThanOrEqual(try pixelSize(of: full).0, PhotoStore.maxFullPixels)
        XCTAssertLessThanOrEqual(try pixelSize(of: thumb).0, PhotoStore.maxThumbPixels)
    }

    /// A JPEG that really carries a GPS dictionary (the renderer's output has none, which would make the test vacuous).
    private func jpegWithGPS() throws -> Data {
        let image = try XCTUnwrap(UIImage(data: jpeg(width: 400, height: 300))?.cgImage)
        let out = NSMutableData()
        let dest = try XCTUnwrap(CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 10.7769, kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 106.7009, kCGImagePropertyGPSLongitudeRef: "E"
        ]
        CGImageDestinationAddImage(dest, image, [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(dest))
        return out as Data
    }

    func testSavedFileCarriesNoGPSMetadata() throws {
        let input = try jpegWithGPS()
        let inputSource = try XCTUnwrap(CGImageSourceCreateWithData(input as CFData, nil))
        let inputProps = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(inputSource, 0, nil) as? [CFString: Any])
        XCTAssertNotNil(inputProps[kCGImagePropertyGPSDictionary], "fixture must carry GPS or this test proves nothing")

        let store = PhotoStore(directory: dir)
        let name = try store.save(imageData: input, id: UUID())
        for fileName in [name, PhotoStore.thumbName(for: name)] {
            let data = try Data(contentsOf: dir.appending(path: fileName))
            let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
            let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
            XCTAssertNil(props[kCGImagePropertyGPSDictionary], fileName)
        }
    }

    func testRejectsNonImageData() {
        let store = PhotoStore(directory: dir)
        XCTAssertThrowsError(try store.save(imageData: Data("not an image".utf8), id: UUID()))
    }

    func testRemoveDeletesBothFiles() throws {
        let store = PhotoStore(directory: dir)
        let name = try store.save(imageData: jpeg(width: 200, height: 200), id: UUID())
        store.remove(fileName: name)
        XCTAssertNil(store.thumbnailData(for: name))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appending(path: name).path))
    }

    func testThumbnailWriteFailureLeavesNoFullFile() throws {
        let store = PhotoStore(directory: dir)
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        // A directory where the thumbnail file belongs makes that write fail.
        try FileManager.default.createDirectory(
            at: dir.appending(path: PhotoStore.thumbName(for: fileName)), withIntermediateDirectories: true)
        XCTAssertThrowsError(try store.save(imageData: jpeg(width: 300, height: 300), id: id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appending(path: fileName).path))
    }

    func testRejectsOversizedInput() {
        let store = PhotoStore(directory: dir)
        let big = Data(count: PhotoStore.maxInputBytes + 1)
        XCTAssertThrowsError(try store.save(imageData: big, id: UUID())) { error in
            XCTAssertEqual(error as? PhotoStore.Failure, .tooLarge)
        }
        XCTAssertThrowsError(try store.previewData(from: big))
    }

    func testDisplayImageIsDownsampledAndMissingFileIsNil() throws {
        let store = PhotoStore(directory: dir)
        let name = try store.save(imageData: jpeg(width: 2400, height: 1200), id: UUID())
        let image = try XCTUnwrap(store.displayImage(for: name))
        XCTAssertEqual(max(image.width, image.height), PhotoStore.maxDisplayPixels)
        XCTAssertNil(store.displayImage(for: "missing.jpg"))
    }

    /// A small picture must never be enlarged by the size caps (ImageIO may scale up with CreateThumbnailFromImageAlways).
    func testSmallImageIsNotUpscaled() throws {
        let store = PhotoStore(directory: dir)
        let name = try store.save(imageData: jpeg(width: 300, height: 200), id: UUID())
        let full = try Data(contentsOf: dir.appending(path: name))
        let thumb = try XCTUnwrap(store.thumbnailData(for: name))
        let fullSize = try pixelSize(of: full)
        let thumbSize = try pixelSize(of: thumb)
        XCTAssertLessThanOrEqual(max(fullSize.0, fullSize.1), 300)
        XCTAssertLessThanOrEqual(max(thumbSize.0, thumbSize.1), 300)
        let display = try XCTUnwrap(store.displayImage(for: name))
        XCTAssertLessThanOrEqual(max(display.width, display.height), 300)
    }
}
