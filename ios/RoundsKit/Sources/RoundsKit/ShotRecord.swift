import Foundation

/// A club in the bag.
public enum Club: Hashable, Codable, Sendable {
    case driver
    case wood(Int)
    case hybrid(Int)
    case iron(Int)
    case pitchingWedge
    case gapWedge
    case sandWedge
    case lobWedge
    case wedge(degrees: Int)
    case putter

    public var shortName: String {
        switch self {
        case .driver: "Driver"
        case let .wood(number): "\(number)W"
        case let .hybrid(number): "\(number)H"
        case let .iron(number): "\(number)i"
        case .pitchingWedge: "PW"
        case .gapWedge: "GW"
        case .sandWedge: "SW"
        case .lobWedge: "LW"
        case let .wedge(degrees): "\(degrees)°"
        case .putter: "Putter"
        }
    }
}

/// Where the shot finished.
public enum ShotOutcome: String, Codable, Sendable, CaseIterable {
    case fairway
    case green
    case fringe
    case rough
    case bunker
    case trees
    case water
    case outOfBounds
    case holed
}

/// Which way the shot missed its target. Only set when the golfer says so.
public enum MissDirection: String, Codable, Sendable, CaseIterable {
    case left
    case right
    case short
    case long
}

/// The lie the shot was played from.
public enum Lie: String, Codable, Sendable, CaseIterable {
    case tee
    case fairway
    case rough
    case bunker
    case fringe
    case green
    case trees
}

/// One logged shot. Every field except the club is optional: a field is only
/// filled when the golfer's words (or a validated model answer) state it.
public struct ShotRecord: Hashable, Codable, Sendable {
    public var club: Club
    public var distanceYards: Int?
    public var outcome: ShotOutcome?
    public var missDirection: MissDirection?
    public var lie: Lie?
    public var notes: String?

    public init(
        club: Club,
        distanceYards: Int? = nil,
        outcome: ShotOutcome? = nil,
        missDirection: MissDirection? = nil,
        lie: Lie? = nil,
        notes: String? = nil
    ) {
        self.club = club
        self.distanceYards = distanceYards
        self.outcome = outcome
        self.missDirection = missDirection
        self.lie = lie
        self.notes = notes
    }
}

public extension ShotRecord {
    /// Yardages a logged full or partial shot can plausibly have.
    static let plausibleYards = 1...450

    /// False when a record (for example one returned by a model) holds values no
    /// real shot could have. Such a record must not be saved as-is.
    var isPlausible: Bool {
        if let yards = distanceYards {
            guard Self.plausibleYards.contains(yards) else { return false }
            if club == .putter, yards > 100 { return false }
        }
        switch club {
        case let .wood(number):
            return (2...9).contains(number)
        case let .hybrid(number), let .iron(number):
            return (1...9).contains(number)
        case let .wedge(degrees):
            return (44...64).contains(degrees)
        case .driver, .pitchingWedge, .gapWedge, .sandWedge, .lobWedge, .putter:
            return true
        }
    }
}
