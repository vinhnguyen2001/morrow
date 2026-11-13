import Foundation

/// A visible map area in degrees. No MapKit import, so framing is testable; `MapView` converts it.
/// The description is redacted like `Coordinate`.
struct MapRegion: Equatable, Sendable, CustomStringConvertible {
    var centerLatitude: Double
    var centerLongitude: Double
    var latitudeSpan: Double
    var longitudeSpan: Double

    var description: String { "MapRegion(redacted)" }
}

/// Decides where the camera looks (T-004 step 4). Pure and unit tested.
enum MapFraming {
    /// Shown when no memory has a location: the whole world, centred on nothing in particular.
    static let defaultRegion = MapRegion(centerLatitude: 20, centerLongitude: 0, latitudeSpan: 100, longitudeSpan: 200)
    /// About 2 km: one pin, or pins on top of each other, never zoom further in than this.
    static let minimumSpan = 0.02
    /// Spread pins get 60% extra room, so edge pins clear the Back button and the status bar.
    static let paddingFactor = 1.6

    /// Empty: the default region. One pin: the minimum span. Many: bounds plus padding.
    /// Spans are clamped to what MapKit accepts (180 and 360 degrees). Pins on both sides of the antimeridian
    /// give a near-world span (accepted, see the ticket).
    static func region(for pins: [MapPin]) -> MapRegion {
        guard let first = pins.first else { return defaultRegion }
        var minLat = first.coordinate.latitude, maxLat = minLat
        var minLon = first.coordinate.longitude, maxLon = minLon
        for pin in pins.dropFirst() {
            minLat = min(minLat, pin.coordinate.latitude)
            maxLat = max(maxLat, pin.coordinate.latitude)
            minLon = min(minLon, pin.coordinate.longitude)
            maxLon = max(maxLon, pin.coordinate.longitude)
        }
        return MapRegion(
            centerLatitude: (minLat + maxLat) / 2,
            centerLongitude: (minLon + maxLon) / 2,
            latitudeSpan: clampedSpan((maxLat - minLat) * paddingFactor, limit: 180),
            longitudeSpan: clampedSpan((maxLon - minLon) * paddingFactor, limit: 360)
        )
    }

    /// Keeps `coordinate` in the middle of the part of the map the sheet does not cover.
    /// `coveredBottomFraction` is the share of the map height under the sheet (0 to 1). The map centre moves
    /// south by half of it, so the pin sits above the sheet. The span is kept as it is.
    static func region(centering coordinate: Coordinate, keeping current: MapRegion, coveredBottomFraction: Double) -> MapRegion {
        let covered = min(max(coveredBottomFraction, 0), 0.9)
        let latitudeSpan = clampedSpan(current.latitudeSpan, limit: 180)
        let latitude = min(max(coordinate.latitude - covered / 2 * latitudeSpan, -90), 90)
        return MapRegion(centerLatitude: latitude, centerLongitude: coordinate.longitude, latitudeSpan: latitudeSpan,
                         longitudeSpan: clampedSpan(current.longitudeSpan, limit: 360))
    }

    private static func clampedSpan(_ span: Double, limit: Double) -> Double {
        min(max(span, minimumSpan), limit)
    }
}
