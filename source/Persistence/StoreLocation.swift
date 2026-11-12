import Foundation

/// Where the SwiftData store lives. Its own directory carries `.completeUnlessOpen`
/// file protection (security-checklist); files created inside inherit it.
/// The 4cde0ca build kept `default.store` directly in Application Support, so existing
/// data is moved once, with the main file last so an interrupted move is retried.
enum StoreLocation {
    static let storeFileName = "default.store"
    private static let companionSuffixes = ["-wal", "-shm"]

    /// Creates the protected directory, moves a legacy store into it if needed, and returns the store file URL.
    static func prepare(
        in directory: URL = URL.applicationSupportDirectory.appending(path: "Store", directoryHint: .isDirectory),
        legacyDirectory: URL = .applicationSupportDirectory
    ) throws -> URL {
        let fileManager = FileManager.default
        // A fresh install has no Application Support folder yet (notes/swiftdata-gotchas).
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let target = directory.appending(path: storeFileName)
        let legacy = legacyDirectory.appending(path: storeFileName)
        if !fileManager.fileExists(atPath: target.path), fileManager.fileExists(atPath: legacy.path) {
            for suffix in companionSuffixes {
                try moveIfPresent(suffix: suffix, from: legacyDirectory, to: directory)
            }
            try fileManager.moveItem(at: legacy, to: target)
        }
        applyProtection(to: directory)
        return target
    }

    private static func moveIfPresent(suffix: String, from source: URL, to destination: URL) throws {
        let name = storeFileName + suffix
        let from = source.appending(path: name)
        guard FileManager.default.fileExists(atPath: from.path) else { return }
        try FileManager.default.moveItem(at: from, to: destination.appending(path: name))
    }

    /// Sets the class on the directory (for new files) and on every file already inside (moved ones).
    /// Best effort: the simulator ignores it, and failure must not block launch.
    private static func applyProtection(to directory: URL) {
        let attributes: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.completeUnlessOpen]
        let fileManager = FileManager.default
        try? fileManager.setAttributes(attributes, ofItemAtPath: directory.path)
        let names = (try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in names {
            try? fileManager.setAttributes(attributes, ofItemAtPath: directory.appending(path: name).path)
        }
    }
}
