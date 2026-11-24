import Foundation

/// Reads hole pars from a model's description of a scorecard photo.
///
/// The model is asked for one line, `PARS: 4 4 3 5 …`. This parser decides what
/// the app accepts: only pars of 3 to 6, only 9 or 18 holes, and `?` for holes
/// the model could not read. Totals such as 36 or 72 are dropped. The golfer
/// then checks the pars before the round starts.
public enum ScorecardReader {
    public static let prompt = """
    This photo shows a golf scorecard. Read the PAR row for each hole, in hole order.
    Reply with exactly one line in this form:
    PARS: 4 4 3 5 4 4 3 4 5
    List 9 or 18 values. Write ? for any hole whose par you cannot read clearly. \
    Do not include totals. Do not add anything else.
    """

    /// One entry per hole; `nil` marks a par that could not be read. Returns
    /// nil when the answer is not a usable 9- or 18-hole list.
    public static func pars(from answer: String) -> [Int?]? {
        let lines = answer.split(whereSeparator: \.isNewline).map(String.init)
        guard let line = lines.first(where: { $0.lowercased().contains("par") }) ?? lines.first else {
            return nil
        }
        let body = line.split(separator: ":", maxSplits: 1).last.map(String.init) ?? line

        var pars: [Int?] = []
        for token in body.split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "|" }) {
            let word = token.trimmingCharacters(in: CharacterSet(charactersIn: "*`[]()."))
            if word == "?" {
                pars.append(nil)
            } else if let value = Int(word) {
                if (3...6).contains(value) {
                    pars.append(value)
                } else if value <= 2 {
                    pars.append(nil) // a misread; ask the golfer
                }
                // 7 or more is a total (36, 72) and is dropped.
            }
        }
        guard pars.count == 9 || pars.count == 18 else { return nil }
        // A list with almost nothing readable is not worth using.
        guard pars.compactMap({ $0 }).count >= pars.count / 2 else { return nil }
        return pars
    }
}
