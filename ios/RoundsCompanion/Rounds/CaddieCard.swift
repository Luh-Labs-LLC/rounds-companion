import RoundsKit
import SwiftUI

/// The in-round caddie. Stats are computed in code (`CaddieFacts`); the model,
/// on-device first, only puts them into two sentences. An answer that contains
/// a number not in the facts is discarded and the facts are shown instead.
struct CaddieCard: View {
    let holes: [HoleScore]

    @State private var result: AIResult?
    @State private var shownFacts: String?
    @State private var note: String?
    @State private var isRunning = false

    static let instructions = """
    You are a calm, encouraging golf caddie talking to the golfer during the round.
    Using ONLY the facts given, write exactly two short sentences: the clearest pattern so far, \
    then one simple adjustment for the next holes.
    Do not use any number that is not in the facts. Do not mention strokes gained or handicaps.
    """

    private var hasShots: Bool { holes.contains { !$0.shots.isEmpty } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Caddie", systemImage: "figure.golf").font(.headline)
                Spacer()
                if let result {
                    SourceBadge(source: result.source, compact: true)
                }
            }

            if let result {
                Text(result.text)
                Text("\(result.latencyMilliseconds) ms · \(result.modelVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let shownFacts {
                Text(shownFacts).font(.footnote.monospaced())
            } else {
                Text(hasShots
                    ? "Ask for a read on today's pattern. It works offline."
                    : "Log a few shots, then ask for a read on today's pattern.")
                    .foregroundStyle(.secondary)
            }

            if let note {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }

            Button {
                Task { await run() }
            } label: {
                if isRunning {
                    ProgressView()
                } else {
                    Text(result == nil ? "Get a read" : "Refresh")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isRunning || !hasShots)
        }
        .padding(.vertical, 4)
    }

    private func run() async {
        isRunning = true
        defer { isRunning = false }
        note = nil
        let facts = CaddieFacts.facts(for: holes)
        do {
            let answer = try await HybridText.preferOnDevice(prompt: facts, instructions: Self.instructions)
            if CaddieFacts.answerUsesOnlyKnownNumbers(answer.text, facts: facts) {
                result = answer
                shownFacts = nil
            } else {
                result = nil
                shownFacts = facts
                note = "The model used a number the app didn't compute, so here are the stats instead."
            }
        } catch {
            result = nil
            shownFacts = facts
            note = "The model didn't answer, so here are the computed stats."
        }
    }
}
