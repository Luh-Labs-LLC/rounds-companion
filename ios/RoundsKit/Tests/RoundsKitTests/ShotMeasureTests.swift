import Testing
@testable import RoundsKit

struct ShotMeasureTests {
    // 0.001 degrees of latitude is about 111.2 m, about 121.6 yards.
    let tee = GeoFix(latitude: 43.0000, longitude: -89.0000, accuracyMeters: 5)
    let landing = GeoFix(latitude: 43.0010, longitude: -89.0000, accuracyMeters: 5)

    @Test func measuresNorthSouthDistance() {
        let measured = ShotMeasure.measure(from: tee, to: landing)
        #expect(measured == ShotMeasure.Measurement(yards: 122, uncertaintyYards: 11))
    }

    @Test func symmetric() {
        #expect(ShotMeasure.measure(from: landing, to: tee)?.yards == 122)
    }

    @Test func eastWestShrinksWithLatitude() {
        // 0.001 degrees of longitude at 43° N is about 81.3 m, about 89 yards.
        let east = GeoFix(latitude: 43.0000, longitude: -88.9990, accuracyMeters: 5)
        #expect(ShotMeasure.measure(from: tee, to: east)?.yards == 89)
    }

    @Test func poorAccuracyIsRejected() {
        let fuzzy = GeoFix(latitude: 43.0010, longitude: -89.0000, accuracyMeters: 35)
        #expect(ShotMeasure.measure(from: tee, to: fuzzy) == nil)
        let invalid = GeoFix(latitude: 43.0010, longitude: -89.0000, accuracyMeters: -1)
        #expect(ShotMeasure.measure(from: tee, to: invalid) == nil)
    }

    @Test func missingOrImplausibleIsRejected() {
        #expect(ShotMeasure.measure(from: nil, to: landing) == nil)
        #expect(ShotMeasure.measure(from: tee, to: tee) == nil)
        let farAway = GeoFix(latitude: 43.0100, longitude: -89.0000, accuracyMeters: 5)
        #expect(ShotMeasure.measure(from: tee, to: farAway) == nil)
    }
}
