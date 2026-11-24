import Foundation
import RoundsKit
import SwiftData

/// A round in progress or finished. Stored on the device only.
@Model
final class Round {
    var id: UUID = UUID()
    var courseName: String = ""
    var startedAt: Date = Date()
    var finishedAt: Date?
    var pars: [Int] = []
    /// The cloud debrief, kept once written.
    var debriefText: String?
    var debriefModelVersion: String?
    var debriefSourceRaw: String?
    var debriefLatencyMs: Int?

    @Relationship(deleteRule: .cascade, inverse: \LoggedShot.round)
    var shots: [LoggedShot] = []

    init(courseName: String, pars: [Int]) {
        self.courseName = courseName
        self.pars = pars
        self.startedAt = Date()
    }

    var holeCount: Int { pars.count }

    func par(ofHole number: Int) -> Int {
        pars.indices.contains(number - 1) ? pars[number - 1] : 4
    }

    func shotsOnHole(_ number: Int) -> [LoggedShot] {
        shots.filter { $0.holeNumber == number }.sorted { $0.createdAt < $1.createdAt }
    }

    /// The round as RoundsKit sees it, for stats computed in code.
    func holeScores() -> [HoleScore] {
        pars.indices.map { index in
            let number = index + 1
            return HoleScore(number: number, par: pars[index], shots: shotsOnHole(number).compactMap(\.record))
        }
    }
}

/// One logged shot: the golfer's words, the resulting record, and which model
/// (if any) helped structure it.
@Model
final class LoggedShot {
    var id: UUID = UUID()
    var holeNumber: Int = 1
    var createdAt: Date = Date()
    var rawText: String = ""
    /// `ShotRecord` encoded as JSON, so SwiftData never has to store an enum
    /// with associated values.
    var recordData: Data = Data()
    var sourceRaw: String = AnswerSource.notUsed.rawValue
    var modelVersion: String?
    var latencyMs: Int?
    /// Where the shot was hit from (the phone's position when it was logged).
    var latitude: Double?
    var longitude: Double?
    var accuracyMeters: Double?
    var round: Round?

    init(holeNumber: Int, rawText: String, record: ShotRecord, ai: AIResult?, fix: GeoFix? = nil) {
        self.holeNumber = holeNumber
        self.rawText = rawText
        self.createdAt = Date()
        self.recordData = (try? JSONEncoder().encode(record)) ?? Data()
        self.sourceRaw = (ai?.source ?? .notUsed).rawValue
        self.modelVersion = ai?.modelVersion
        self.latencyMs = ai?.latencyMilliseconds
        self.latitude = fix?.latitude
        self.longitude = fix?.longitude
        self.accuracyMeters = fix?.accuracyMeters
    }

    var fix: GeoFix? {
        guard let latitude, let longitude, let accuracyMeters else { return nil }
        return GeoFix(latitude: latitude, longitude: longitude, accuracyMeters: accuracyMeters)
    }

    var record: ShotRecord? { try? JSONDecoder().decode(ShotRecord.self, from: recordData) }

    var source: AnswerSource { AnswerSource(rawValue: sourceRaw) ?? .unknown }
}
