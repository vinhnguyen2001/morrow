import Foundation

/// Location permission as the UI needs it. Mapped from the system status by the adapter (ADR 0007).
enum LocationAuthorization: Sendable, Equatable {
    case notDetermined
    /// Denied by the user, or Location Services are off system-wide.
    case denied
    /// Blocked by parental controls or a profile: the user cannot change it, so there is no Settings link.
    case restricted
    case authorized
}

/// Where the user is right now. Behind a protocol so Capture never imports CoreLocation and tests use a fake.
@MainActor
protocol LocationProviding: AnyObject {
    var authorization: LocationAuthorization { get }
    /// Shows the system prompt when the status is not determined and returns once the user has answered.
    func requestWhenInUse() async
    /// A fix good enough to pin a memory, or nil (not authorized, no fix in time, cancelled).
    func currentCoordinate() async -> Coordinate?
}

/// Turns a coordinate into a short place name. One request, no retry.
protocol PlaceNaming: Sendable {
    func placeName(for coordinate: Coordinate) async -> String?
}

/// Default when no location source is wired in (tests, previews): reports "restricted" and never finds anything.
@MainActor
final class NoLocationProvider: LocationProviding {
    nonisolated init() {}
    let authorization = LocationAuthorization.restricted
    func requestWhenInUse() async {}
    func currentCoordinate() async -> Coordinate? { nil }
}

struct NoPlaceNamer: PlaceNaming {
    func placeName(for coordinate: Coordinate) async -> String? { nil }
}
