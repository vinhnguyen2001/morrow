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
    }
}
