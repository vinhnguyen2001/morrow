import Foundation
import os

/// Where the SwiftData store lives. Its own directory carries `.completeUnlessOpen`
/// file protection (security-checklist); files created inside inherit it.
/// The 4cde0ca build kept `default.store` directly in Application Support, so existing
/// data is moved once. wal/shm always travel with the main file: while main is still in the
/// legacy folder, legacy is the source of truth, and the move is all-or-nothing (see `prepare`).
enum StoreLocation {
    /// `Application Support/Store`, the protected directory holding the store.
    static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Store", directoryHint: .isDirectory)
    }

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
    /// Before moving, wal/shm left in the target by an interrupted run are returned to legacy; wal/shm
    /// present in both places is abnormal and stops with `rollbackFailed` (nothing is merged or deleted).
    /// Then order: wal, shm, main file last. Every step is recorded; on a failed step all of them are
    /// moved back in reverse order, then `MoveError` is thrown.
    static func prepare(
        in directory: URL = defaultDirectory,
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
                try reconcileCompanions(in: directory, legacyDirectory: legacyDirectory, fileManager: fileManager)
            } catch {
                throw MoveError.rollbackFailed(cause: error)
            }
            do {
                for name in names {
                    let from = legacyDirectory.appending(path: name)
                    let to = directory.appending(path: name)
                    guard fileManager.fileExists(atPath: from.path) else { continue }
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

    /// Main is still in legacy, so legacy is the truth. A wal/shm only in the target is a leftover of an
    /// interrupted run: move it back. One in both places cannot be trusted: throw, touching nothing.
    private static func reconcileCompanions(in directory: URL, legacyDirectory: URL, fileManager: FileManager) throws {
        for suffix in companionSuffixes {
            let name = storeFileName + suffix
            let inLegacy = legacyDirectory.appending(path: name)
            let inTarget = directory.appending(path: name)
            let legacyHas = fileManager.fileExists(atPath: inLegacy.path)
            let targetHas = fileManager.fileExists(atPath: inTarget.path)
            if targetHas && legacyHas { throw CocoaError(.fileWriteFileExists) }
            if targetHas { try fileManager.moveItem(at: inTarget, to: inLegacy) }
        }
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
        in directory: URL = defaultDirectory
    ) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Morrow", category: "store")
        for (label, url) in [("directory", directory), ("file", directory.appending(path: storeFileName))] {
            let key = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.protectionKey] as? FileProtectionType
            logger.debug("store \(label, privacy: .public) protection: \(key?.rawValue ?? "unreadable", privacy: .public)")
        }
    }
    #endif
}
