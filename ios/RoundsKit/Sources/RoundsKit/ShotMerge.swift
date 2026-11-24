import Foundation

/// Combines what the deterministic parser read from the golfer's own words with
/// what it read from the model's shorthand rewrite.
///
/// The golfer's words are the authority: every field the parser found there is
/// kept. The model's rewrite only fills fields the golfer's words left empty,
/// and only after it has itself passed the parser and the plausibility check.
/// So a malformed or invented model answer can never overwrite a fact, and a
/// shot is still recorded when the model fails.
public enum ShotMerge {
    public static func merge(fromWords words: ShotRecord?, fromModel model: ShotRecord?) -> ShotRecord? {
        let words = words.flatMap { $0.isPlausible ? $0 : nil }
        let model = model.flatMap { $0.isPlausible ? $0 : nil }

        guard let model else { return words }
        guard var merged = words else { return model }

        merged.distanceYards = merged.distanceYards ?? model.distanceYards
        merged.outcome = merged.outcome ?? model.outcome
        merged.missDirection = merged.missDirection ?? model.missDirection
        merged.lie = merged.lie ?? model.lie
        // Notes stay the golfer's own leftover words; the model's are not kept.
        return merged
    }

    /// Parses the model's shorthand rewrite. Only the first line is used, so a
    /// chatty answer cannot smuggle in extra shots.
    public static func parseModelShorthand(_ text: String) -> ShotRecord? {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\"'`*-")) ?? ""
        guard var record = ShotParser.parse(firstLine) else { return nil }
        // Leftover words in the model's answer are not facts the golfer said.
        record.notes = nil
        return record
    }
}
