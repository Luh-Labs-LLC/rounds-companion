import Foundation
import RoundsKit

/// Turns what the golfer typed or said into a shot record.
///
/// 1. The deterministic parser reads the golfer's own words.
/// 2. The model (on-device first) rewrites the words as one line of shorthand.
/// 3. The parser reads that shorthand; `ShotMerge` keeps every field from the
///    golfer's words and lets the model fill only the gaps.
/// If the model fails, the shot is still saved from the words alone.
enum ShotLogger {
    struct Outcome: Sendable {
        let record: ShotRecord?
        let ai: AIResult?
        let aiError: String?
    }

    static let instructions = """
    You turn a golfer's description of ONE golf shot into compact shorthand on a single line.
    Format: club, then yards, then direction, then where the ball finished. Leave out anything the golfer did not say.
    Clubs: driver, 3w, 5w, 4h, 5h, 3i to 9i, pw, gw, sw, lw, 50° to 60°, putter.
    Directions: left, right, short, long.
    Where it finished: fairway, green, fringe, rough, bunker, trees, water, ob, holed.
    Add "from" and a place only if the golfer said where the shot was hit from.
    Write numbers as digits. Never guess. Reply with the shorthand line only.
    Examples:
    smoked my driver about two sixty down the middle -> driver 260 fairway
    seven iron, pushed it right into the greenside trap -> 7i right bunker
    pitching wedge 95 onto the green -> pw 95 green
    tapped in with the putter -> putter holed
    """

    nonisolated static func structure(_ text: String) async -> Outcome {
        let fromWords = ShotParser.parse(text)
        do {
            let ai = try await HybridText.preferOnDevice(prompt: text, instructions: instructions)
            let fromModel = ShotMerge.parseModelShorthand(ai.text)
            return Outcome(record: ShotMerge.merge(fromWords: fromWords, fromModel: fromModel), ai: ai, aiError: nil)
        } catch {
            return Outcome(record: fromWords, ai: nil, aiError: String(describing: error))
        }
    }
}
