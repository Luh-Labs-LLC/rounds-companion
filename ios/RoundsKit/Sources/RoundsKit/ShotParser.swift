import Foundation

/// Deterministic parser for golf shorthand such as `7i 162y`, `PW 95` or
/// `driver 240 left`. No AI: it is the guardrail that validates (and can stand
/// in for) the on-device model, so a bad model answer never corrupts a record.
///
/// Rules:
/// - A club is required; text without a recognisable club returns `nil`.
/// - A bare number, or one followed by y/yd/yds/yards, is the distance in yards,
///   if it is plausible. Numbers after a putter are not yards (they are usually
///   feet) and are kept in the notes.
/// - left/right/short/long set the miss direction; words such as "pushed" are
///   not turned into a direction, because that would assume a handedness.
/// - "from"/"off"/"out of" + a place sets the lie; a bare place word sets the outcome.
/// - Anything not understood is kept, in order, in `notes`.
public enum ShotParser {
    public static func parse(_ text: String) -> ShotRecord? {
        let original = tokenize(text, lowercase: false)
        let words = tokenize(text, lowercase: true)
        guard original.count == words.count else { return nil }

        var club: Club?
        var distance: Int?
        var outcome: ShotOutcome?
        var direction: MissDirection?
        var lie: Lie?
        var notes: [String] = []

        var index = 0
        while index < words.count {
            if club == nil, let match = matchClub(words, at: index) {
                club = match.value
                index += match.length
                continue
            }
            if outcome == nil, let length = matchOutOfBounds(words, at: index) {
                outcome = .outOfBounds
                index += length
                continue
            }
            if lie == nil, let match = matchLie(words, at: index) {
                lie = match.value
                index += match.length
                continue
            }
            if distance == nil, club != .putter, let match = matchDistance(words, at: index) {
                distance = match.value
                index += match.length
                continue
            }
            if outcome == nil, let value = outcomeWords[words[index]] {
                outcome = value
                index += 1
                continue
            }
            if direction == nil, let value = MissDirection(rawValue: words[index]) {
                direction = value
                index += 1
                continue
            }
            if !fillerWords.contains(words[index]) {
                notes.append(original[index])
            }
            index += 1
        }

        guard let club else { return nil }
        return ShotRecord(
            club: club,
            distanceYards: distance,
            outcome: outcome,
            missDirection: direction,
            lie: lie,
            notes: notes.isEmpty ? nil : notes.joined(separator: " ")
        )
    }

    // MARK: - Tokens

    private static let separators: Set<Character> = [",", ";", ":", "/", "-", ".", "!", "?", "(", ")"]

    private static func tokenize(_ text: String, lowercase: Bool) -> [String] {
        let source = lowercase ? text.lowercased() : text
        let spaced = String(source.map { separators.contains($0) ? " " : $0 })
        return spaced.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    struct Match<Value> {
        let value: Value
        let length: Int
    }

    private struct NumberPrefix {
        let value: Int
        let suffix: String
    }

    /// Splits "162y" into 162 and "y"; returns nil when the word doesn't start with a digit.
    private static func numberPrefix(_ word: String) -> NumberPrefix? {
        let digits = word.prefix(while: { $0.isASCII && $0.isNumber })
        guard !digits.isEmpty, digits.count <= 4, let value = Int(digits) else { return nil }
        return NumberPrefix(value: value, suffix: String(word.dropFirst(digits.count)))
    }

    // MARK: - Clubs

    static func matchClub(_ words: [String], at index: Int) -> Match<Club>? {
        let word = words[index]
        let next = index + 1 < words.count ? words[index + 1] : nil

        switch word {
        case "driver", "dr", "d":
            return Match(value: .driver, length: 1)
        case "pw":
            return Match(value: .pitchingWedge, length: 1)
        case "gw", "aw":
            return Match(value: .gapWedge, length: 1)
        case "sw":
            return Match(value: .sandWedge, length: 1)
        case "lw":
            return Match(value: .lobWedge, length: 1)
        case "putter", "putt", "putted":
            return Match(value: .putter, length: 1)
        case "pitching" where next == "wedge":
            return Match(value: .pitchingWedge, length: 2)
        case "gap" where next == "wedge", "approach" where next == "wedge":
            return Match(value: .gapWedge, length: 2)
        case "sand" where next == "wedge":
            return Match(value: .sandWedge, length: 2)
        case "lob" where next == "wedge":
            return Match(value: .lobWedge, length: 2)
        default:
            break
        }

        guard let number = numberPrefix(word) else { return nil }
        if number.suffix.isEmpty {
            // "7 iron", "3 wood", "56 degree"
            guard let next, let found = clubFor(number: number.value, kind: next) else { return nil }
            return Match(value: found, length: 2)
        }
        // "7i", "3w", "4h", "56°"
        guard let found = clubFor(number: number.value, kind: number.suffix) else { return nil }
        return Match(value: found, length: 1)
    }

    private static func clubFor(number: Int, kind: String) -> Club? {
        switch kind {
        case "w", "wood":
            if number == 1 { return .driver }
            return (2...9).contains(number) ? .wood(number) : nil
        case "h", "hy", "hybrid":
            return (1...9).contains(number) ? .hybrid(number) : nil
        case "i", "iron":
            return (1...9).contains(number) ? .iron(number) : nil
        case "°", "deg", "degree", "degrees":
            return (44...64).contains(number) ? .wedge(degrees: number) : nil
        default:
            return nil
        }
    }

    // MARK: - Distance

    private static let yardUnits: Set<String> = ["y", "yd", "yds", "yard", "yards"]
    private static let feetUnits: Set<String> = ["ft", "feet", "foot", "'"]

    static func matchDistance(_ words: [String], at index: Int) -> Match<Int>? {
        guard let number = numberPrefix(words[index]) else { return nil }
        var length = 1
        if number.suffix.isEmpty {
            if index + 1 < words.count {
                let next = words[index + 1]
                if yardUnits.contains(next) {
                    length = 2
                } else if feetUnits.contains(next) {
                    return nil
                }
            }
        } else if !yardUnits.contains(number.suffix) {
            return nil
        }
        guard ShotRecord.plausibleYards.contains(number.value) else { return nil }
        return Match(value: number.value, length: length)
    }

    // MARK: - Lie and outcome

    private static let lieWords: [String: Lie] = [
        "tee": .tee,
        "fairway": .fairway, "fw": .fairway, "fwy": .fairway,
        "rough": .rough,
        "bunker": .bunker, "sand": .bunker, "trap": .bunker,
        "fringe": .fringe, "collar": .fringe, "apron": .fringe,
        "green": .green,
        "trees": .trees, "tree": .trees,
    ]

    static func matchLie(_ words: [String], at index: Int) -> Match<Lie>? {
        var cursor = index
        switch words[index] {
        case "tee":
            return Match(value: .tee, length: 1)
        case "from", "off":
            cursor += 1
        case "out" where index + 1 < words.count && words[index + 1] == "of":
            cursor += 2
        default:
            return nil
        }
        if cursor < words.count, words[cursor] == "the" { cursor += 1 }
        guard cursor < words.count, let lie = lieWords[words[cursor]] else { return nil }
        return Match(value: lie, length: cursor - index + 1)
    }

    static func matchOutOfBounds(_ words: [String], at index: Int) -> Int? {
        switch words[index] {
        case "ob", "oob":
            return 1
        case "out" where index + 2 < words.count
            && words[index + 1] == "of" && words[index + 2] == "bounds":
            return 3
        default:
            return nil
        }
    }

    private static let outcomeWords: [String: ShotOutcome] = [
        "fairway": .fairway, "fw": .fairway, "fwy": .fairway, "fir": .fairway,
        "green": .green, "gir": .green,
        "fringe": .fringe, "collar": .fringe, "apron": .fringe,
        "rough": .rough,
        "bunker": .bunker, "sand": .bunker, "trap": .bunker,
        "trees": .trees, "tree": .trees,
        "water": .water, "wet": .water, "hazard": .water, "lake": .water, "pond": .water,
        "holed": .holed, "made": .holed, "sunk": .holed, "drained": .holed,
    ]

    /// Small words dropped from notes so they read cleanly.
    private static let fillerWords: Set<String> = [
        "the", "a", "an", "to", "into", "in", "on", "at", "of", "and", "with",
    ]
}
