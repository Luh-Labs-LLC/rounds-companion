import Foundation

/// A GPS position with its reported horizontal accuracy (meters).
public struct GeoFix: Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let accuracyMeters: Double

    public init(latitude: Double, longitude: Double, accuracyMeters: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracyMeters = accuracyMeters
    }
}

/// Measures a shot from where it was hit to where the next shot was hit.
/// The result is shown beside the golfer's own distance, never in place of it,
/// together with its uncertainty, because phone GPS is only good to a few yards.
public enum ShotMeasure {
    /// Fixes less accurate than this are not used.
    public static let maxAccuracyMeters = 20.0
    static let earthRadiusMeters = 6_371_000.0
    static let metersPerYard = 0.9144

    public struct Measurement: Equatable, Sendable {
        public let yards: Int
        /// Plus or minus, from the two fixes' reported accuracy.
        public let uncertaintyYards: Int
    }

    public static func measure(from start: GeoFix?, to end: GeoFix?) -> Measurement? {
        guard let start, let end,
              start.accuracyMeters >= 0, end.accuracyMeters >= 0,
              start.accuracyMeters <= maxAccuracyMeters, end.accuracyMeters <= maxAccuracyMeters
        else { return nil }
        let yards = Int((distanceMeters(start, end) / metersPerYard).rounded())
        guard ShotRecord.plausibleYards.contains(yards) else { return nil }
        let uncertainty = Int(((start.accuracyMeters + end.accuracyMeters) / metersPerYard).rounded())
        return Measurement(yards: yards, uncertaintyYards: uncertainty)
    }

    /// Great-circle (haversine) distance in meters.
    static func distanceMeters(_ a: GeoFix, _ b: GeoFix) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusMeters * asin(min(1, sqrt(h)))
    }
}
