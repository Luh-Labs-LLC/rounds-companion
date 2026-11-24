import RoundsKit
import SwiftUI

/// Round statistics, all computed in code from the logged shots.
struct SummaryView: View {
    let round: Round

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

            Section("By hole") {
                ForEach(holes.filter { !$0.shots.isEmpty }, id: \.number) { hole in
                    LabeledContent("Hole \(hole.number) · par \(hole.par)",
                                   value: "\(hole.strokes) (\(ScoreText.toPar(hole.strokes - hole.par)))")
                }
            }
        }
        .navigationTitle("Summary")
    }
}
