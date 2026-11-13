import XCTest
@testable import Morrow

@MainActor
private final class FakeLocationProvider: LocationProviding {
    var authorization: LocationAuthorization
    var result: Coordinate?
    /// When set, `currentCoordinate` waits until `release()` so a test can act while locating.
    var holds = false
    private var gate: CheckedContinuation<Void, Never>?
    private(set) var requestCount = 0

    init(authorization: LocationAuthorization, result: Coordinate? = nil) {
        self.authorization = authorization
        self.result = result
    }

    func requestWhenInUse() async {
        requestCount += 1
        if authorization == .notDetermined { authorization = .authorized }
    }

    func currentCoordinate() async -> Coordinate? {
        if holds { await withCheckedContinuation { gate = $0 } }
        return result
    }

    var isWaiting: Bool { gate != nil }

    /// Lets the pending (or a future) call answer.
    func release() {
        holds = false
        gate?.resume()
        gate = nil
    }
}

private struct FakePlaceNamer: PlaceNaming {
    var name: String?
    func placeName(for coordinate: Coordinate) async -> String? { name }
}

@MainActor
final class CaptureLocationTests: XCTestCase {
    /// Yields until the fake is parked inside `currentCoordinate`, so the test acts while the model is locating.
    private func waitUntilWaiting(_ provider: FakeLocationProvider) async throws {
        for _ in 0..<1000 where !provider.isWaiting { await Task.yield() }
        XCTAssertTrue(provider.isWaiting)
        try XCTSkipUnless(provider.isWaiting)
    }

    private let here = Coordinate(latitude: 10.7, longitude: 106.7)

    private func makeModel(_ provider: LocationProviding, namer: PlaceNaming = FakePlaceNamer(name: nil))
        throws -> (CaptureViewModel, SwiftDataMemoryRepository) {
        let repo = SwiftDataMemoryRepository(container: try SwiftDataMemoryRepository.makeContainer(inMemory: true))
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let model = CaptureViewModel(repository: repo, photoStore: PhotoStore(directory: dir),
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
