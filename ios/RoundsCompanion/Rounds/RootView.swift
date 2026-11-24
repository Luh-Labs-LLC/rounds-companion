import RoundsKit
import SwiftData
import SwiftUI

/// Home: start a round, reopen past rounds, and the diagnostics screen.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Round.startedAt, order: .reverse) private var rounds: [Round]
    @State private var path: [Round] = []
    @State private var showingNewRound = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Button {
                        showingNewRound = true
                    } label: {
                        Label("Start a round", systemImage: "flag.fill")
                            .font(.headline)
                    }
                } footer: {
                    Text("Log shots by typing shorthand like “7i 162 right bunker” or plain words. Everything stays on this phone and works without signal.")
                }

                if !rounds.isEmpty {
                    Section("Rounds") {
                        ForEach(rounds) { round in
                            NavigationLink(value: round) {
                                RoundRow(round: round)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets { context.delete(rounds[index]) }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        ProbeView()
                    } label: {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }
                } footer: {
                    Text("On-device model: \(HybridText.onDeviceStatus)")
                }
            }
            .navigationTitle("Rounds")
            .navigationDestination(for: Round.self) { round in
                RoundView(round: round)
            }
            .sheet(isPresented: $showingNewRound) {
                NewRoundView { round in
                    context.insert(round)
                    path.append(round)
                }
            }
        }
    }
}

struct RoundRow: View {
    let round: Round

    var body: some View {
        let stats = RoundStats(holes: round.holeScores())
        VStack(alignment: .leading, spacing: 2) {
            Text(round.courseName).font(.headline)
            HStack(spacing: 6) {
                Text(round.startedAt, style: .date)
                Text("·")
                Text(stats.holesPlayed == 0 ? "No shots yet" : "Thru \(stats.holesPlayed), \(ScoreText.toPar(stats.scoreToPar))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

enum ScoreText {
    static func toPar(_ value: Int) -> String {
        value == 0 ? "E" : value > 0 ? "+\(value)" : "\(value)"
    }
}
