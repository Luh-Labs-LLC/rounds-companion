import Foundation

/// The shots logged on one hole.
public struct HoleScore: Hashable, Codable, Sendable {
    public var number: Int
    public var par: Int
    public var shots: [ShotRecord]

    public init(number: Int, par: Int, shots: [ShotRecord]) {
        self.number = number
        self.par = par
        self.shots = shots
    }

    /// One penalty stroke for each shot that finished in water or out of bounds.
    /// Other penalties (unplayable lies, rules breaches) are not modelled yet.
    public var penaltyStrokes: Int {
        shots.filter { $0.outcome.map(Self.carriesPenalty) ?? false }.count
    }

    public var strokes: Int { shots.count + penaltyStrokes }

    public var putts: Int { shots.filter { $0.club == .putter }.count }

    /// A par 4 or 5 whose first shot has a known outcome.
    public var isFairwayOpportunity: Bool { par >= 4 && shots.first?.outcome != nil }

    public var hitFairway: Bool { par >= 4 && shots.first?.outcome == .fairway }

    /// On the green (or holed) in par minus two strokes or fewer, penalties included.
    /// A shot with no recorded outcome counts as not reaching the green.
    public var greenInRegulation: Bool {
        var strokesSoFar = 0
        for shot in shots {
            strokesSoFar += 1
            if let outcome = shot.outcome, Self.carriesPenalty(outcome) { strokesSoFar += 1 }
            if shot.outcome == .green || shot.outcome == .holed {
                return strokesSoFar <= par - 2
            }
        }
        return false
    }

    private static func carriesPenalty(_ outcome: ShotOutcome) -> Bool {
        outcome == .water || outcome == .outOfBounds
    }
}

/// Round statistics computed in code. A model may describe these numbers but
/// never produces them. No strokes-gained or benchmark figures.
public struct RoundStats: Equatable, Sendable {
    public let holesPlayed: Int
    public let par: Int
    public let strokes: Int
    public let penaltyStrokes: Int
    public let fairwaysHit: Int
    public let fairwayOpportunities: Int
    public let greensInRegulation: Int
    public let putts: Int
    /// Misses by direction across all non-putter shots.
    public let missesByDirection: [MissDirection: Int]

    public var scoreToPar: Int { strokes - par }

    /// Holes with no shots logged are skipped.
    public init(holes: [HoleScore]) {
        let played = holes.filter { !$0.shots.isEmpty }
        holesPlayed = played.count
        par = played.reduce(0) { $0 + $1.par }
        strokes = played.reduce(0) { $0 + $1.strokes }
        penaltyStrokes = played.reduce(0) { $0 + $1.penaltyStrokes }
        fairwaysHit = played.filter(\.hitFairway).count
        fairwayOpportunities = played.filter(\.isFairwayOpportunity).count
        greensInRegulation = played.filter(\.greenInRegulation).count
        putts = played.reduce(0) { $0 + $1.putts }

        var misses: [MissDirection: Int] = [:]
        for shot in played.flatMap(\.shots) where shot.club != .putter {
            if let direction = shot.missDirection {
                misses[direction, default: 0] += 1
            }
        }
        missesByDirection = misses
    }
}
