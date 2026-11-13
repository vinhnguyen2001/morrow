import CoreLocation
import XCTest
@testable import Morrow

@MainActor
private final class FakeLocationProvider: LocationProviding {
    var authorization: LocationAuthorization
    var result: Coordinate?
    /// What the permission prompt answers when the status is not determined.
    var grantsOnRequest = true
    /// When set, `currentCoordinate` waits until `release()` so a test can act while locating.
    var holds = false
    private var gates: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0
    private(set) var coordinateCalls = 0

    init(authorization: LocationAuthorization, result: Coordinate? = nil) {
        self.authorization = authorization
        self.result = result
    }

    func requestWhenInUse() async {
        requestCount += 1
        if authorization == .notDetermined { authorization = grantsOnRequest ? .authorized : .denied }
    }

    func currentCoordinate() async -> Coordinate? {
        coordinateCalls += 1
        if holds { await withCheckedContinuation { gates.append($0) } }
        return result
    }

    var isWaiting: Bool { !gates.isEmpty }

    /// Lets every pending (and any future) call answer.
    func release() {
        holds = false
        let pending = gates
        gates = []
        pending.forEach { $0.resume() }
    }
}

/// Holds `placeName` until `release()`, so a test can act while the name is being looked up.
private actor NameGate {
    private var gate: CheckedContinuation<Void, Never>?
    private var released = false
    var isWaiting: Bool { gate != nil }
    func wait() async {
        guard !released else { return }
        await withCheckedContinuation { gate = $0 }
    }
    func release() {
        released = true
        gate?.resume()
        gate = nil
    }
}

private struct FakePlaceNamer: PlaceNaming {
    var name: String?
    var gate: NameGate?
    func placeName(for coordinate: Coordinate) async -> String? {
        await gate?.wait()
        return name
    }
}

/// Fails the first `add`, then behaves like the real repository.
private final class FlakyRepository: MemoryRepository {
    let inner: MemoryRepository
    private var failuresLeft = 1
    struct Failure: Error {}
    init(_ inner: MemoryRepository) { self.inner = inner }
    func all() throws -> [Memory] { try inner.all() }
    func add(_ memory: Memory) throws {
        if failuresLeft > 0 { failuresLeft -= 1; throw Failure() }
        try inner.add(memory)
    }
    func delete(id: UUID) throws { try inner.delete(id: id) }
}

@MainActor
final class CaptureLocationTests: XCTestCase {
    /// Yields until the fake is parked inside `currentCoordinate`, so the test acts while the model is locating.
    private func waitUntilWaiting(_ provider: FakeLocationProvider) async throws {
        for _ in 0..<1000 where !provider.isWaiting { await Task.yield() }
        XCTAssertTrue(provider.isWaiting)
    }

    private let here = Coordinate(latitude: 10.7, longitude: 106.7)

    private func waitUntilWaiting(_ gate: NameGate) async {
        for _ in 0..<1000 { if await gate.isWaiting { return }; await Task.yield() }
        XCTFail("place namer never started")
    }

    private func makeModel(_ provider: LocationProviding, namer: PlaceNaming = FakePlaceNamer(name: nil),
                           failFirstSave: Bool = false)
        throws -> (CaptureViewModel, SwiftDataMemoryRepository) {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let model = CaptureViewModel(repository: failFirstSave ? FlakyRepository(repo) : repo, photoStore: PhotoStore(directory: dir),
                                     locationProvider: provider, placeNamer: namer)
        model.kind = .note
        model.title = "Coffee"
        return (model, repo)
    }

    func testAuthorizedFillsCoordinateAndPlaceAndSaves() async throws {
        let (model, repo) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here),
                                          namer: FakePlaceNamer(name: "Market, Saigon"))
        await model.startLocating()
        XCTAssertEqual(model.locationState, .located)
        XCTAssertEqual(model.coordinate, here)
        XCTAssertEqual(model.placeName, "Market, Saigon")
        let saved = await model.save()
        XCTAssertTrue(saved)
        let stored = try XCTUnwrap(repo.all().first)
        XCTAssertEqual(stored.coordinate, here)
        XCTAssertEqual(stored.placeName, "Market, Saigon")
    }

    func testNotDeterminedAsksOnceThenLocates() async throws {
        let provider = FakeLocationProvider(authorization: .notDetermined, result: here)
        let (model, _) = try makeModel(provider)
        await model.startLocating()
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(model.coordinate, here)
    }

    func testDeniedStillSavesWithoutCoordinate() async throws {
        let (model, repo) = try makeModel(FakeLocationProvider(authorization: .denied))
        await model.startLocating()
        XCTAssertEqual(model.locationState, .unavailable)
        XCTAssertTrue(model.offersSettingsLink)
        let saved = await model.save()
        XCTAssertTrue(saved)
        XCTAssertNil(try repo.all().first?.coordinate)
    }

    func testRestrictedHasNoSettingsLink() async throws {
        let (model, _) = try makeModel(FakeLocationProvider(authorization: .restricted))
        await model.startLocating()
        XCTAssertEqual(model.locationState, .unavailable)
        XCTAssertFalse(model.offersSettingsLink)
    }

    func testTimeoutWithoutFixStillSaves() async throws {
        let (model, repo) = try makeModel(FakeLocationProvider(authorization: .authorized, result: nil))
        await model.startLocating()
        XCTAssertEqual(model.locationState, .unavailable)
        let saved = await model.save()
        XCTAssertTrue(saved)
        XCTAssertNil(try repo.all().first?.coordinate)
    }

    func testGeocodeFailureKeepsCoordinateWithEmptyPlace() async throws {
        let (model, repo) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here))
        await model.startLocating()
        XCTAssertEqual(model.coordinate, here)
        XCTAssertFalse(model.isFindingPlace)
        _ = await model.save()
        let stored = try XCTUnwrap(repo.all().first)
        XCTAssertEqual(stored.coordinate, here)
        XCTAssertNil(stored.placeName)
    }

    func testPlaceTypedByUserIsNotOverwritten() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, _) = try makeModel(provider, namer: FakePlaceNamer(name: "Suggested"))
        let locating = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        model.setPlaceName(byUser: "My spot")
        provider.release()
        await locating.value
        XCTAssertEqual(model.placeName, "My spot")
        XCTAssertEqual(model.coordinate, here)
    }

    func testUserClearingThePlaceFieldStillBlocksTheSuggestion() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, _) = try makeModel(provider, namer: FakePlaceNamer(name: "Suggested"))
        let locating = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        model.setPlaceName(byUser: "x")
        model.setPlaceName(byUser: "")
        provider.release()
        await locating.value
        XCTAssertEqual(model.placeName, "")
    }

    func testClearLocationSavesNilAndDropsSuggestedName() async throws {
        let (model, repo) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here),
                                          namer: FakePlaceNamer(name: "Suggested"))
        await model.startLocating()
        model.clearLocation()
        XCTAssertNil(model.coordinate)
        XCTAssertEqual(model.placeName, "")
        _ = await model.save()
        let stored = try XCTUnwrap(repo.all().first)
        XCTAssertNil(stored.coordinate)
        XCTAssertNil(stored.placeName)
    }

    func testClearLocationKeepsAPlaceTheUserEdited() async throws {
        let (model, _) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here),
                                       namer: FakePlaceNamer(name: "Suggested"))
        await model.startLocating()
        model.setPlaceName(byUser: "Suggested") // same text, but now it is the user's
        model.clearLocation()
        XCTAssertEqual(model.placeName, "Suggested")
    }

    func testSaveWhileLocatingDoesNotWaitAndLateResultIsIgnored() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, repo) = try makeModel(provider, namer: FakePlaceNamer(name: "Late"))
        let locating = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        XCTAssertEqual(model.locationState, .locating)
        let saved = await model.save() // returns although the provider never answered
        XCTAssertTrue(saved)
        provider.release() // answer arrives after Save
        await locating.value
        XCTAssertNil(model.coordinate)
        XCTAssertEqual(model.placeName, "")
        let stored = try XCTUnwrap(repo.all().first)
        XCTAssertNil(stored.coordinate)
        XCTAssertNil(stored.placeName)
    }

    func testFailedSaveWhileLocatingDoesNotStickAndSecondSaveGetsTheCoordinate() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, repo) = try makeModel(provider, failFirstSave: true)
        let locating = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        let failed = await model.save()
        XCTAssertFalse(failed)
        // The search was reopened, not left at a dead ".locating".
        for _ in 0..<1000 where provider.coordinateCalls < 2 { await Task.yield() }
        XCTAssertEqual(provider.coordinateCalls, 2)
        provider.release()
        await locating.value
        for _ in 0..<1000 where model.locationState != .located { await Task.yield() }
        XCTAssertEqual(model.locationState, .located)
        XCTAssertEqual(model.coordinate, here)
        let saved = await model.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(try repo.all().first?.coordinate, here)
    }

    func testCancelLocatingLeavesIdleNotLocating() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, _) = try makeModel(provider)
        let locating = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        model.cancelLocating()
        XCTAssertEqual(model.locationState, .idle)
        provider.release()
        await locating.value
        XCTAssertNil(model.coordinate)
    }

    func testTwoStartLocatingCallsMakeOneLookup() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        provider.holds = true
        let (model, _) = try makeModel(provider)
        let first = Task { await model.startLocating() }
        let second = Task { await model.startLocating() }
        try await waitUntilWaiting(provider)
        await second.value
        provider.release()
        await first.value
        XCTAssertEqual(provider.coordinateCalls, 1)
    }

    func testPromptDeniedGivesUnavailableWithSettingsLink() async throws {
        let provider = FakeLocationProvider(authorization: .notDetermined, result: here)
        provider.grantsOnRequest = false
        let (model, _) = try makeModel(provider)
        await model.startLocating()
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(model.locationState, .unavailable)
        XCTAssertTrue(model.offersSettingsLink)
        XCTAssertNil(model.coordinate)
    }

    func testPlaceTypedWhileGeocodingIsNotOverwritten() async throws {
        let gate = NameGate()
        let (model, _) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here),
                                       namer: FakePlaceNamer(name: "Suggested", gate: gate))
        let locating = Task { await model.startLocating() }
        await waitUntilWaiting(gate)
        XCTAssertTrue(model.isFindingPlace)
        model.setPlaceName(byUser: "My spot")
        await gate.release()
        await locating.value
        XCTAssertEqual(model.placeName, "My spot")
        XCTAssertFalse(model.isFindingPlace)
    }

    func testClearLocationWhileGeocodingDropsTheLateName() async throws {
        let gate = NameGate()
        let (model, _) = try makeModel(FakeLocationProvider(authorization: .authorized, result: here),
                                       namer: FakePlaceNamer(name: "Late", gate: gate))
        let locating = Task { await model.startLocating() }
        await waitUntilWaiting(gate)
        model.clearLocation()
        XCTAssertFalse(model.isFindingPlace)
        XCTAssertNil(model.coordinate)
        await gate.release()
        await locating.value
        XCTAssertEqual(model.placeName, "")
        XCTAssertNil(model.coordinate)
        XCTAssertFalse(model.isFindingPlace)
    }

    func testRecheckAfterSettingsChangeStartsLocating() async throws {
        let provider = FakeLocationProvider(authorization: .denied, result: here)
        let (model, _) = try makeModel(provider)
        await model.startLocating()
        XCTAssertEqual(model.locationState, .unavailable)
        provider.authorization = .authorized
        await model.recheckAuthorization()
        XCTAssertEqual(model.coordinate, here)
    }

    func testRecheckDoesNotRestartAfterUserRemovedLocation() async throws {
        let provider = FakeLocationProvider(authorization: .authorized, result: here)
        let (model, _) = try makeModel(provider)
        await model.startLocating()
        model.clearLocation()
        await model.recheckAuthorization()
        XCTAssertNil(model.coordinate)
    }
}

final class PlaceNameFormatterTests: XCTestCase {
    func testPointOfInterestComesFirst() {
        let parts = PlaceParts(areasOfInterest: ["Ben Thanh Market"], name: "Ben Thanh", thoroughfare: "Le Loi", locality: "Ho Chi Minh City")
        XCTAssertEqual(PlaceNameFormatter.format(parts), "Ben Thanh Market, Ho Chi Minh City")
    }

    func testStreetWhenNoPointOfInterest() {
        let parts = PlaceParts(name: "12 Nguyen Hue", thoroughfare: " Nguyen Hue ", locality: "Ho Chi Minh City")
        XCTAssertEqual(PlaceNameFormatter.format(parts), "Nguyen Hue, Ho Chi Minh City")
    }

    func testCityOnlyAndNoDuplicate() {
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts(locality: "Hoi An")), "Hoi An")
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts(name: "hoi an", locality: "Hoi An")), "Hoi An")
    }

    func testEmptyAndBlankGiveEmpty() {
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts()), "")
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts(areasOfInterest: ["  "], name: " ", thoroughfare: "", locality: "\n")), "")
    }

    func testTooLongIsCut() {
        let parts = PlaceParts(areasOfInterest: [String(repeating: "a", count: 300)], locality: "City")
        XCTAssertEqual(PlaceNameFormatter.format(parts).count, Memory.Limits.place)
    }
}

final class PlaceNameFormatterVietnameseTests: XCTestCase {
    func testDiacriticsArePreserved() {
        let parts = PlaceParts(areasOfInterest: ["Ch\u{1EE3} B\u{1EBF}n Th\u{00E0}nh"], locality: "H\u{1ED3} Ch\u{00ED} Minh")
        XCTAssertEqual(PlaceNameFormatter.format(parts), "Ch\u{1EE3} B\u{1EBF}n Th\u{00E0}nh, H\u{1ED3} Ch\u{00ED} Minh")
    }

    func testHeadEqualToLocalityIsDroppedIgnoringDiacritics() {
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts(name: "H\u{00E0} N\u{1ED9}i", locality: "H\u{00E0} N\u{1ED9}i")), "H\u{00E0} N\u{1ED9}i")
        XCTAssertEqual(PlaceNameFormatter.format(PlaceParts(name: "Hoi An", locality: "H\u{1ED9}i An")), "H\u{1ED9}i An")
    }
}

final class BestFixTests: XCTestCase {
    private func fix(_ accuracy: CLLocationAccuracy, lat: Double = 10) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: 106), altitude: 0,
                   horizontalAccuracy: accuracy, verticalAccuracy: 0, timestamp: Date())
    }

    @MainActor func testFirstFixWinsWhenNothingBefore() {
        XCTAssertEqual(SystemLocationProvider.better(nil, fix(50)).horizontalAccuracy, 50)
    }

    @MainActor func testSmallerAccuracyWinsAndTieKeepsTheFirst() {
        XCTAssertEqual(SystemLocationProvider.better(fix(200), fix(30)).horizontalAccuracy, 30)
        XCTAssertEqual(SystemLocationProvider.better(fix(30), fix(200)).horizontalAccuracy, 30)
        XCTAssertEqual(SystemLocationProvider.better(fix(30, lat: 1), fix(30, lat: 2)).coordinate.latitude, 1)
    }
}
