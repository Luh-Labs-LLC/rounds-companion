import RoundsKit
import SwiftUI

/// Round statistics, all computed in code from the logged shots, plus the
/// cloud debrief once there is signal.
struct SummaryView: View {
    let round: Round

    @State private var isWriting = false
    @State private var debriefProblem: String?

    static let debriefInstructions = """
    You are a supportive golf coach writing a short debrief right after a round.
    Use ONLY the facts given. Write three short paragraphs: what went well, what cost the most strokes, \
    and one practice focus for next time. Refer to holes and clubs only as they appear in the facts.
    Do not use any number that is not in the facts. Do not mention strokes gained, handicaps or benchmarks.
    """

    var body: some View {
        let holes = round.holeScores()
        let stats = RoundStats(holes: holes)

        List {
            Section("Score") {
                LabeledContent("Holes played", value: "\(stats.holesPlayed)")
                LabeledContent("Strokes", value: "\(stats.strokes)")
                LabeledContent("To par", value: ScoreText.toPar(stats.scoreToPar))
                if stats.penaltyStrokes > 0 {
                    LabeledContent("Penalty strokes", value: "\(stats.penaltyStrokes)")
                }
            }

            Section("Tee to green") {
                LabeledContent("Fairways", value: stats.fairwayOpportunities == 0
                    ? "—" : "\(stats.fairwaysHit) of \(stats.fairwayOpportunities)")
                LabeledContent("Greens in regulation", value: stats.holesPlayed == 0
                    ? "—" : "\(stats.greensInRegulation) of \(stats.holesPlayed)")
                LabeledContent("Putts", value: "\(stats.putts)")
            }

            Section("Misses") {
                if stats.missesByDirection.isEmpty {
                    Text("No misses by direction recorded.").foregroundStyle(.secondary)
                } else {
                    ForEach(MissDirection.allCases, id: \.self) { direction in
                        if let count = stats.missesByDirection[direction] {
                            LabeledContent(direction.rawValue.capitalized, value: "\(count)")
                        }
                    }
                }
            }

            Section {
                if let text = round.debriefText {
                    HStack {
                        Text("Debrief").font(.headline)
                        Spacer()
                        SourceBadge(source: AnswerSource(rawValue: round.debriefSourceRaw ?? "") ?? .unknown, compact: true)
                    }
                    Text(text)
                    if let ms = round.debriefLatencyMs, let model = round.debriefModelVersion {
                        Text("\(ms) ms · \(model)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let debriefProblem {
                    Text(debriefProblem).font(.footnote).foregroundStyle(.secondary)
                }
                Button {
                    Task { await writeDebrief(holes: holes) }
                } label: {
                    HStack {
                        Label(round.debriefText == nil ? "Write the debrief" : "Rewrite the debrief",
                              systemImage: "cloud")
                        if isWriting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isWriting || stats.holesPlayed == 0)
            } header: {
                Text("Post-round debrief")
            } footer: {
                Text("The debrief covers the whole round, so it runs on Gemini in the cloud and needs signal. Everything above is computed on this phone.")
            }

            Section("By hole") {
                ForEach(holes.filter { !$0.shots.isEmpty }, id: \.number) { hole in
                    LabeledContent("Hole \(hole.number) · par \(hole.par)",
                                   value: "\(hole.strokes) (\(ScoreText.toPar(hole.strokes - hole.par)))")
                }
            }
        }
        .navigationTitle("Summary")
    }

    private func writeDebrief(holes: [HoleScore]) async {
        isWriting = true
        debriefProblem = nil
        defer { isWriting = false }
        let facts = CaddieFacts.roundFacts(for: holes)
        do {
            let answer = try await HybridText.cloudOnly(prompt: facts, instructions: Self.debriefInstructions)
            guard CaddieFacts.answerUsesOnlyKnownNumbers(answer.text, facts: facts) else {
                debriefProblem = "The model's debrief used a number the app didn't compute, so it was discarded. Try again."
                return
            }
            round.debriefText = answer.text
            round.debriefModelVersion = answer.modelVersion
            round.debriefSourceRaw = answer.source.rawValue
            round.debriefLatencyMs = answer.latencyMilliseconds
        } catch {
            debriefProblem = "Couldn't reach the cloud model. The debrief will work once you have signal."
        }
    }
}
