import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Stores photos on disk (security-checklist: compress on device, strip EXIF, file protection).
/// Re-encoding through ImageIO without copying properties drops EXIF/GPS.
struct PhotoStore: Sendable {
    static let maxFullPixels = 2048
    static let maxThumbPixels = 600
    static let maxInputBytes = 40 * 1024 * 1024

    enum Failure: Error { case tooLarge, unreadable, writeFailed }

    let directory: URL

    init(directory: URL = PhotoStore.defaultDirectory) {
        self.directory = directory
    }

    static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Photos", directoryHint: .isDirectory)
    }

    static func thumbName(for fileName: String) -> String {
        (fileName as NSString).deletingPathExtension + "_thumb.jpg"
    }

    /// Writes full + thumbnail JPEGs for `id`. Returns the full-size file name. Call off the main actor.
    func save(imageData: Data, id: UUID) throws -> String {
        guard imageData.count <= Self.maxInputBytes else { throw Failure.tooLarge }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { throw Failure.unreadable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = "\(id.uuidString).jpg"
        let full = try jpeg(from: source, maxPixels: Self.maxFullPixels, quality: 0.8)
        let thumb = try jpeg(from: source, maxPixels: Self.maxThumbPixels, quality: 0.7)
        try write(full, to: directory.appending(path: fileName))
        try write(thumb, to: directory.appending(path: Self.thumbName(for: fileName)))
        return fileName
    }

    /// Small EXIF-free JPEG for showing a just-picked photo before saving. Call off the main actor.
    func previewData(from imageData: Data) throws -> Data {
        guard imageData.count <= Self.maxInputBytes else { throw Failure.tooLarge }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { throw Failure.unreadable }
        return try jpeg(from: source, maxPixels: Self.maxThumbPixels, quality: 0.7)
    }

    func thumbnailData(for fileName: String) -> Data? {
        try? Data(contentsOf: directory.appending(path: Self.thumbName(for: fileName)))
    }

    func remove(fileName: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: fileName))
        try? FileManager.default.removeItem(at: directory.appending(path: Self.thumbName(for: fileName)))
    }

    private func write(_ data: Data, to url: URL) throws {
        do { try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen]) }
        catch { throw Failure.writeFailed }
    }

    private func jpeg(from source: CGImageSource, maxPixels: Int, quality: Double) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw Failure.unreadable
        }
        let output = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw Failure.unreadable
        }
        // No source properties are copied, so EXIF and GPS are dropped.
        CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw Failure.unreadable }
        return output as Data
    }
}
