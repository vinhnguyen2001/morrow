import CoreLocation

/// `PlaceNaming` on CLGeocoder (deprecated on iOS 26 but this app targets iOS 17; swap for MKReverseGeocodingRequest
/// here later, one file). Sends the coordinate to Apple: declare it in the privacy nutrition label (M6).
/// One request, no retry. Never logs the coordinate or the result.
struct CLGeocoderPlaceNamer: PlaceNaming {
    func placeName(for coordinate: Coordinate) async -> String? {
        guard !Task.isCancelled else { return nil }
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks: [CLPlacemark]? = await withTaskCancellationHandler {
            try? await geocoder.reverseGeocodeLocation(location)
        } onCancel: {
            geocoder.cancelGeocode()
        }
        guard let placemark = placemarks?.first else { return nil }
        let name = PlaceNameFormatter.format(PlaceParts(
            areasOfInterest: placemark.areasOfInterest ?? [],
            name: placemark.name,
            thoroughfare: placemark.thoroughfare,
            locality: placemark.locality))
        return name.isEmpty ? nil : name
    }
}
