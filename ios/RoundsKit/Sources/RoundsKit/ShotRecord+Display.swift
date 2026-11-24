import Foundation

public extension ShotOutcome {
    var displayName: String {
        switch self {
        case .outOfBounds: "OB"
        case .holed: "holed"
        default: rawValue
        }
    }
}

public extension ShotRecord {
    /// One-line summary such as "7i · 162 y · right · bunker". Only fields that
    /// were recorded appear.
    var summary: String {
        var parts = [club.shortName]
        if let distanceYards { parts.append("\(distanceYards) y") }
        if let missDirection { parts.append(missDirection.rawValue) }
        if let outcome { parts.append(outcome.displayName) }
        if let lie { parts.append("from \(lie.rawValue)") }
        return parts.joined(separator: " · ")
    }
}
