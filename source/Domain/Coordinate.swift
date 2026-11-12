import Foundation

/// A validated WGS84 coordinate. No CoreLocation import (ADR 0007).
/// `description` is redacted so accidental logging or string interpolation leaks nothing.
struct Coordinate: Hashable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    let latitude: Double
    let longitude: Double

    /// Nil for NaN, infinite or out-of-range values.
    init?(latitude: Double, longitude: Double) {
        guard latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        self.latitude = latitude
        self.longitude = longitude
    }

    var description: String { "Coordinate(redacted)" }
    var debugDescription: String { "Coordinate(redacted)" }
}
