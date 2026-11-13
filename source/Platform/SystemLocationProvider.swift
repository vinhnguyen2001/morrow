import CoreLocation

/// `LocationProviding` on CoreLocation, iOS 17 API only (no CLServiceSession, no `authorizationDenied`).
/// When-In-Use only. Never logs coordinates.
@MainActor
final class SystemLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    /// Wait this long for a fix of `goodAccuracy`, then use the best one seen (reduced accuracy never gets there).
    static let fixTimeout: Duration = .seconds(5)
    static let goodAccuracy: CLLocationAccuracy = 100

    // Created on first use so App.init stays light.
    private lazy var manager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    private var pendingAuthorization: CheckedContinuation<Void, Never>?

    var authorization: LocationAuthorization {
        // Reads the instance status. Location Services off reports denied, so locationServicesEnabled() is not needed.
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        @unknown default: return .denied
        }
    }

    func requestWhenInUse() async {
        guard authorization == .notDetermined else { return }
        resumePendingAuthorization() // a second caller must not leave the first one hanging
        await withTaskCancellationHandler {
            // Cancelled before we got here: nobody would ever resume the continuation.
            guard !Task.isCancelled else { return }
            await withCheckedContinuation { continuation in
                pendingAuthorization = continuation
                manager.requestWhenInUseAuthorization()
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.resumePendingAuthorization() }
        }
    }

    /// The only place that resumes the continuation, and it clears it first, so it can never resume twice.
    private func resumePendingAuthorization() {
        guard let continuation = pendingAuthorization else { return }
        pendingAuthorization = nil
        continuation.resume()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self, self.manager.authorizationStatus != .notDetermined else { return }
            self.resumePendingAuthorization()
        }
    }

    /// The fix with the smaller horizontal accuracy (the first one wins a tie). Pure, so tests need no CoreLocation stream.
    nonisolated static func better(_ best: CLLocation?, _ location: CLLocation) -> CLLocation {
        best.map { location.horizontalAccuracy < $0.horizontalAccuracy ? location : $0 } ?? location
    }

    func currentCoordinate() async -> Coordinate? {
        guard authorization == .authorized else { return nil }
        let stream = Task { @MainActor () -> CLLocation? in
            var best: CLLocation?
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let location = update.location, location.horizontalAccuracy >= 0 else { continue }
                    best = Self.better(best, location)
                    if location.horizontalAccuracy <= Self.goodAccuracy { break }
                }
            } catch {
                // Stream failed or was cancelled: fall through with whatever we have.
            }
            return best // leaving the loop ends the stream
        }
        let timer = Task {
            try? await Task.sleep(for: Self.fixTimeout)
            stream.cancel()
        }
        let best = await withTaskCancellationHandler {
            await stream.value
        } onCancel: {
            stream.cancel()
        }
        timer.cancel()
        guard !Task.isCancelled, let best else { return nil }
        return Coordinate(latitude: best.coordinate.latitude, longitude: best.coordinate.longitude)
    }
}
