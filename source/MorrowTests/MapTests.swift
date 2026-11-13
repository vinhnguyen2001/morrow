import XCTest
@testable import Morrow

/// Map logic with fake coordinates (T-004 step 4). The coordinates are invented, none is a real position.
final class MapTests: XCTestCase {
    private func coordinate(_ latitude: Double, _ longitude: Double) -> Coordinate {
        guard let value = Coordinate(latitude: latitude, longitude: longitude) else { fatalError("bad test coordinate") }
        return value
    }

    private func memory(_ title: String, at point: Coordinate?, kind: MemoryKind = .photo, place: String? = nil) -> Memory {
        Memory(kind: kind, title: title, placeName: place, coordinate: point)
    }

    private func pin(_ latitude: Double, _ longitude: Double) -> MapPin {
        MapPin(id: UUID(), coordinate: coordinate(latitude, longitude), kind: .photo, title: "t", place: nil)
    }

    // MARK: MapPins

    func testPinsKeepOnlyMemoriesWithCoordinatesInOrder() {
        let a = memory("A", at: coordinate(10, 20))
        let none = memory("None", at: nil)
        let b = memory("B", at: coordinate(11, 21), kind: .note, place: "  Hội An ")
        let pins = MapPins.pins(from: [a, none, b])
        XCTAssertEqual(pins.map(\.id), [a.id, b.id])
        XCTAssertEqual(pins[1].place, "Hội An")
        XCTAssertEqual(pins[1].kind, .note)
        XCTAssertTrue(MapPins.pins(from: [none]).isEmpty)
        XCTAssertTrue(MapPins.pins(from: []).isEmpty)
    }

    func testPinLabelHasKindTitleAndPlace() {
        let withPlace = MapPins.pins(from: [memory("Sunrise", at: coordinate(1, 2), place: "Hội An")])
        XCTAssertEqual(withPlace.first?.accessibilityLabel, "Photo, Sunrise, Hội An")
        let noPlace = MapPins.pins(from: [memory("Idea", at: coordinate(1, 2), kind: .note)])
        XCTAssertEqual(noPlace.first?.accessibilityLabel, "Note, Idea")
    }

    func testPinAndRegionDescriptionsDoNotLeakCoordinates() {
        let sample = MapPin(id: UUID(), coordinate: coordinate(15.8801, 108.3380), kind: .photo, title: "Harbour", place: nil)
        let text = "\(sample) \(String(describing: sample)) \(MapFraming.region(for: [sample]))"
        XCTAssertFalse(text.contains("15.88"))
        XCTAssertFalse(text.contains("108.33"))
    }

    func testSelectionIsClearedWhenItsPinIsGone() {
        let a = pin(1, 2), b = pin(3, 4)
        XCTAssertEqual(MapPins.validSelection(a.id, in: [a, b]), a.id)
        XCTAssertNil(MapPins.validSelection(a.id, in: [b]), "deleted memory closes the peek")
        XCTAssertNil(MapPins.validSelection(nil, in: [a]))
        XCTAssertNil(MapPins.validSelection(a.id, in: []))
    }

    // MARK: MapFraming

    func testEmptyUsesTheFixedDefaultRegion() {
        XCTAssertEqual(MapFraming.region(for: []), MapFraming.defaultRegion)
    }

    func testOnePinUsesMinimumSpanCentredOnIt() {
        let region = MapFraming.region(for: [pin(15, 108)])
        XCTAssertEqual(region.centerLatitude, 15)
        XCTAssertEqual(region.centerLongitude, 108)
        XCTAssertEqual(region.latitudeSpan, MapFraming.minimumSpan)
        XCTAssertEqual(region.longitudeSpan, MapFraming.minimumSpan)
    }

    func testIdenticalPinsStayAtMinimumSpan() {
        XCTAssertEqual(MapFraming.region(for: [pin(15, 108), pin(15, 108)]).latitudeSpan, MapFraming.minimumSpan)
    }

    func testManyPinsAreBoundedWithPadding() {
        let region = MapFraming.region(for: [pin(10, 100), pin(20, 110), pin(14, 104)])
        XCTAssertEqual(region.centerLatitude, 15, accuracy: 1e-9)
        XCTAssertEqual(region.centerLongitude, 105, accuracy: 1e-9)
        XCTAssertEqual(region.latitudeSpan, 10 * MapFraming.paddingFactor, accuracy: 1e-9)
        XCTAssertEqual(region.longitudeSpan, 10 * MapFraming.paddingFactor, accuracy: 1e-9)
    }

    func testSpanIsClampedToWhatMapKitAccepts() {
        let region = MapFraming.region(for: [pin(-90, -180), pin(90, 180)])
        XCTAssertEqual(region.latitudeSpan, 180)
        XCTAssertEqual(region.longitudeSpan, 360)
        let antimeridian = MapFraming.region(for: [pin(0, 179), pin(0, -179)])
        XCTAssertLessThanOrEqual(antimeridian.longitudeSpan, 360, "accepted: near-world span across the antimeridian")
    }

    func testCenteringPutsThePinAboveTheSheet() {
        let current = MapRegion(centerLatitude: 0, centerLongitude: 0, latitudeSpan: 1, longitudeSpan: 1)
        let region = MapFraming.region(centering: coordinate(15, 108), keeping: current, coveredBottomFraction: 0.2)
        XCTAssertEqual(region.centerLatitude, 15 - 0.1, accuracy: 1e-9, "map centre moves south by half the covered share")
        XCTAssertEqual(region.centerLongitude, 108)
        XCTAssertEqual(region.latitudeSpan, 1)
    }

    func testCenteringStaysInRangeNearThePoles() {
        let current = MapRegion(centerLatitude: 0, centerLongitude: 0, latitudeSpan: 170, longitudeSpan: 300)
        let south = MapFraming.region(centering: coordinate(-89, 0), keeping: current, coveredBottomFraction: 0.5)
        XCTAssertGreaterThanOrEqual(south.centerLatitude, -90)
        let wild = MapFraming.region(centering: coordinate(0, 0), keeping: MapRegion(centerLatitude: 0, centerLongitude: 0, latitudeSpan: 999, longitudeSpan: 999), coveredBottomFraction: 5)
        XCTAssertLessThanOrEqual(wild.latitudeSpan, 180)
        XCTAssertLessThanOrEqual(wild.longitudeSpan, 360)
    }

    // MARK: Route and metrics

    func testRouteMapSurvivesTrimmingAndDeadMemoryDoesNot() {
        let alive = UUID(), dead = UUID()
        let trimmed = Route.trimmed([.memory(alive), .map, .memory(dead)], alive: [alive])
        XCTAssertEqual(trimmed, [.memory(alive), .map])
        XCTAssertNotEqual(Route.map, Route.memory(alive))
    }

    func testMapMeasurementsMatchSpec() {
        XCTAssertEqual(MapMetrics.peekHeight, 168)
        XCTAssertEqual(HomeMetrics.mapButton, 56)
        XCTAssertEqual(HomeMetrics.mapBadge, 20)
        XCTAssertEqual(MapMetrics.backButton, 46)
    }
}
