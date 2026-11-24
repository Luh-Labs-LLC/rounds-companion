import Foundation

/// Builds the facts the in-round caddie is allowed to talk about, all computed
/// in code from the logged shots, and checks the model's answer against them.
public enum CaddieFacts {
    /// Plain-text facts for the prompt. Every number in here was computed by
    /// `RoundStats`; the model is told to use only these.
    public static func facts(for holes: [HoleScore]) -> String {
        let stats = RoundStats(holes: holes)
        var lines: [String] = []
        lines.append("Holes played: \(stats.holesPlayed)")
        lines.append("Strokes: \(stats.strokes) against par \(stats.par) (\(signed(stats.scoreToPar)))")
        if stats.fairwayOpportunities > 0 {
            lines.append("Fairways hit: \(stats.fairwaysHit) of \(stats.fairwayOpportunities)")
        }
        if stats.holesPlayed > 0 {
            lines.append("Greens in regulation: \(stats.greensInRegulation) of \(stats.holesPlayed)")
        }
        lines.append("Putts: \(stats.putts)")
        if stats.penaltyStrokes > 0 {
            lines.append("Penalty strokes: \(stats.penaltyStrokes)")
        }

        let teeMisses = missCounts(holes.compactMap { $0.par >= 4 ? $0.shots.first : nil })
        let approachMisses = missCounts(holes.flatMap { hole in
            hole.shots.dropFirst(hole.par >= 4 ? 1 : 0).filter { $0.club != .putter }
        })
        if let text = describe(teeMisses) { lines.append("Tee shot misses: \(text)") }
        if let text = describe(approachMisses) { lines.append("Other full-shot misses: \(text)") }
        let missedShots = holes.flatMap(\.shots).filter { $0.club != .putter && $0.missDirection != nil }
        if !missedShots.isEmpty {
            let list = missedShots.map { "\($0.club.shortName) \($0.missDirection!.rawValue)" }
            lines.append("Missed shots by club: \(list.joined(separator: ", "))")
        }
        if teeMisses.isEmpty, approachMisses.isEmpty {
            lines.append("No misses by direction recorded")
        }
        return lines.joined(separator: "\n")
    }

    /// True when every number written as digits in `answer` also appears in
    /// `facts`. An answer that invents a figure fails, and the app shows the
    /// computed stats instead of it.
    public static func answerUsesOnlyKnownNumbers(_ answer: String, facts: String) -> Bool {
        let known = Set(numbers(in: facts))
        return numbers(in: answer).allSatisfy { known.contains($0) }
    }

    static func numbers(in text: String) -> [Int] {
        var result: [Int] = []
        var current = ""
        for character in text {
            if character.isASCII, character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                if let value = Int(current) { result.append(value) }
                current = ""
            }
        }
        if let value = Int(current) { result.append(value) }
        return result
    }

    private static func missCounts(_ shots: [ShotRecord]) -> [MissDirection: Int] {
        var counts: [MissDirection: Int] = [:]
        for shot in shots {
            if let direction = shot.missDirection { counts[direction, default: 0] += 1 }
        }
        return counts
    }

    private static func describe(_ counts: [MissDirection: Int]) -> String? {
        guard !counts.isEmpty else { return nil }
        return MissDirection.allCases
            .compactMap { direction in counts[direction].map { "\(direction.rawValue) \($0)" } }
            .joined(separator: ", ")
    }

    private static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : value == 0 ? "even" : "\(value)"
    }
}
