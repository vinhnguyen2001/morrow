import Foundation
import os

/// Where the SwiftData store lives. Its own directory carries `.completeUnlessOpen`
/// file protection (security-checklist); files created inside inherit it.
/// The 4cde0ca build kept `default.store` directly in Application Support, so existing
/// data is moved once, with the main file last so an interrupted move is retried.
enum StoreLocation {
    static let storeFileName = "default.store"
    private static let companionSuffixes = ["-wal", "-shm"]

    /// Failure of the one-time move. Callers may open the legacy store only for `.rolledBack`.
    enum MoveError: Error {
        /// Every moved file is back where it was; the store at `legacyStore` is intact.
        case rolledBack(legacyStore: URL, cause: Error)
        /// Some files could not be put back. Do not open or copy anything.
        case rollbackFailed(cause: Error)
    }

    /// Creates the protected directory, moves a legacy store into it if needed, and returns the store file URL.
    /// Order: wal/shm first, main file last, so an interrupted move is retried on the next launch.
    /// On a failed step the files moved so far are moved back in reverse order, then `MoveError` is thrown.
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
            var moved: [(from: URL, to: URL)] = []
            let names = companionSuffixes.map { storeFileName + $0 } + [storeFileName]
            do {
                for name in names {
                    let from = legacyDirectory.appending(path: name)
                    let to = directory.appending(path: name)
                    guard fileManager.fileExists(atPath: from.path) else { continue }
                    // Already moved by an interrupted earlier run: keep it, it is the newer copy.
                    var isDirectory: ObjCBool = false
                    if name != storeFileName, fileManager.fileExists(atPath: to.path, isDirectory: &isDirectory),
                       !isDirectory.boolValue { continue }
                    try fileManager.moveItem(at: from, to: to)
                    moved.append((from, to))
                }
            } catch {
                var restored = true
                for step in moved.reversed() {
                    do { try fileManager.moveItem(at: step.to, to: step.from) } catch { restored = false }
                }
                throw restored ? MoveError.rolledBack(legacyStore: legacy, cause: error)
                               : MoveError.rollbackFailed(cause: error)
            }
        }
        applyProtection(to: directory)
        return target
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

    #if DEBUG
    /// Debug-only: logs the file protection class of the store directory and file so it can be read on a device.
    /// Logs the class name only, never paths or content.
    static func logProtectionForDebug(
        in directory: URL = URL.applicationSupportDirectory.appending(path: "Store", directoryHint: .isDirectory)
    ) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Morrow", category: "store")
        for (label, url) in [("directory", directory), ("file", directory.appending(path: storeFileName))] {
            let key = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.protectionKey] as? FileProtectionType
            logger.debug("store \(label, privacy: .public) protection: \(key?.rawValue ?? "unreadable", privacy: .public)")
        }
    }
    #endif
}
