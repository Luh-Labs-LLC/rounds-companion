import CoreLocation
import Foundation
import Observation
import RoundsKit

/// Keeps a recent GPS fix while a round is on screen, so each logged shot can
/// record where it was hit from. GPS works without cell signal; nothing leaves
/// the phone.
@MainActor
@Observable
final class LocationTracker: NSObject, CLLocationManagerDelegate {
    private(set) var latestFix: GeoFix?
    private(set) var latestFixDate: Date?
    private(set) var authorization: CLAuthorizationStatus = .notDetermined

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        authorization = manager.authorizationStatus
    }

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    /// A fix accurate enough to measure from, no older than 20 seconds.
    var usableFix: GeoFix? {
        guard let fix = latestFix, let date = latestFixDate,
              Date().timeIntervalSince(date) < 20,
              fix.accuracyMeters >= 0, fix.accuracyMeters <= ShotMeasure.maxAccuracyMeters
        else { return nil }
        return fix
    }

    var statusText: String {
        switch authorization {
        case .denied, .restricted:
            return "Off (allow location in Settings to measure shots)"
        case .notDetermined:
            return "Waiting for permission"
        default:
            if let fix = usableFix { return "On, ±\(Int(fix.accuracyMeters.rounded())) m" }
            if let fix = latestFix { return "Weak signal, ±\(Int(fix.accuracyMeters.rounded())) m" }
            return "Searching…"
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        let fix = GeoFix(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracyMeters: location.horizontalAccuracy
        )
        let date = location.timestamp
        Task { @MainActor in
            self.latestFix = fix
            self.latestFixDate = date
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorization = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Keep the last fix; the status line shows when it goes stale.
    }
}
