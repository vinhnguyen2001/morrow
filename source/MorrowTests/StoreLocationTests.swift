import SwiftData
import XCTest
@testable import Morrow

final class StoreLocationTests: XCTestCase {
    private var root: URL!
    private var storeDir: URL { root.appending(path: "Store", directoryHint: .isDirectory) }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: storeDir.path)
        try? FileManager.default.removeItem(at: root)
    }

    func testFreshInstallCreatesDirectoryAndReturnsStoreURL() throws {
        let url = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
        XCTAssertEqual(url, storeDir.appending(path: "default.store"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeDir.path))
    }

    func testLegacyStoreFilesAreMovedOnce() throws {
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            try Data(name.utf8).write(to: root.appending(path: name))
        }
        let url = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "default.store")
        XCTAssertEqual(try String(contentsOf: storeDir.appending(path: "default.store-wal"), encoding: .utf8), "default.store-wal")
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appending(path: "default.store").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appending(path: "default.store-shm").path))

        // Second launch: nothing to move, existing data untouched.
        _ = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "default.store")
    }

    func testExistingNewStoreIsNotOverwrittenByLegacy() throws {
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try Data("new".utf8).write(to: storeDir.appending(path: "default.store"))
        try Data("old".utf8).write(to: root.appending(path: "default.store"))
        let url = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "new")
        XCTAssertEqual(try String(contentsOf: root.appending(path: "default.store"), encoding: .utf8), "old")
    }

    func testInterruptedMoveReturnsLeftoverWalToLegacyThenMovesAllTogether() throws {
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try Data("main".utf8).write(to: root.appending(path: "default.store"))
        try Data("shm".utf8).write(to: root.appending(path: "default.store-shm"))
        try Data("wal-old".utf8).write(to: storeDir.appending(path: "default.store-wal"))
        let url = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "main")
        XCTAssertEqual(try String(contentsOf: storeDir.appending(path: "default.store-shm"), encoding: .utf8), "shm")
        XCTAssertEqual(try String(contentsOf: storeDir.appending(path: "default.store-wal"), encoding: .utf8), "wal-old")
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.appending(path: name).path))
        }
    }

    func testCompanionInBothPlacesStopsWithRollbackFailedAndTouchesNothing() throws {
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try Data("main".utf8).write(to: root.appending(path: "default.store"))
        try Data("wal-legacy".utf8).write(to: root.appending(path: "default.store-wal"))
        try Data("wal-target".utf8).write(to: storeDir.appending(path: "default.store-wal"))
        do {
            _ = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
            XCTFail("expected failure")
        } catch StoreLocation.MoveError.rollbackFailed {
        }
        XCTAssertEqual(try String(contentsOf: root.appending(path: "default.store"), encoding: .utf8), "main")
        XCTAssertEqual(try String(contentsOf: root.appending(path: "default.store-wal"), encoding: .utf8), "wal-legacy")
        XCTAssertEqual(try String(contentsOf: storeDir.appending(path: "default.store-wal"), encoding: .utf8), "wal-target")
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeDir.appending(path: "default.store").path))
    }

    func testResumeThenMainFailureRestoresEverythingToLegacy() throws {
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try Data("main".utf8).write(to: root.appending(path: "default.store"))
        try Data("shm".utf8).write(to: root.appending(path: "default.store-shm"))
        try Data("wal".utf8).write(to: storeDir.appending(path: "default.store-wal"))
        // A dangling symlink squats on the main destination: fileExists is false, moveItem fails.
        try FileManager.default.createSymbolicLink(
            atPath: storeDir.appending(path: "default.store").path, withDestinationPath: "/nonexistent-morrow")
        do {
            _ = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
            XCTFail("expected failure")
        } catch StoreLocation.MoveError.rolledBack {
        }
        let expected = ["default.store": "main", "default.store-wal": "wal", "default.store-shm": "shm"]
        for (name, content) in expected {
            XCTAssertEqual(try String(contentsOf: root.appending(path: name), encoding: .utf8), content)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeDir.appending(path: "default.store-wal").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeDir.appending(path: "default.store-shm").path))
    }

    func testFailedMoveRollsBackToLegacyLocation() throws {
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            try Data(name.utf8).write(to: root.appending(path: name))
        }
        // A dangling symlink squats on the shm destination, so that step fails after wal was moved.
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            atPath: storeDir.appending(path: "default.store-shm").path, withDestinationPath: "/nonexistent-morrow")
        do {
            _ = try StoreLocation.prepare(in: storeDir, legacyDirectory: root)
            XCTFail("expected failure")
        } catch StoreLocation.MoveError.rolledBack(let legacyStore, _) {
            XCTAssertEqual(legacyStore, root.appending(path: "default.store"))
        }
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            XCTAssertEqual(try String(contentsOf: root.appending(path: name), encoding: .utf8), name)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeDir.appending(path: "default.store-wal").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeDir.appending(path: "default.store").path))
    }

    @MainActor
    func testMakeContainerFallsBackToLegacyStoreAfterRollback() throws {
        let legacyURL = root.appending(path: "default.store")
        do {
            let container = try ModelContainer(for: MemoryRecord.self, configurations: ModelConfiguration(url: legacyURL))
            try SwiftDataMemoryRepository(container: container).add(Memory(kind: .note, title: "Kept"))
        }
        // Read-only target directory makes the move of the main file fail; nothing else had moved.
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: storeDir.path)

        let container = try SwiftDataMemoryRepository.makeContainer(storeDirectory: storeDir, legacyDirectory: root)
        XCTAssertEqual(try SwiftDataMemoryRepository(container: container).all().map(\.title), ["Kept"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path))
    }
}
