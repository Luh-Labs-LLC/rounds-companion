import RoundsKit
import SwiftData
import SwiftUI

/// A round in progress: one hole at a time, its shots, the caddie, and the
/// entry bar for the next shot.
struct RoundView: View {
    @Environment(\.modelContext) private var context
    @Bindable var round: Round

    @State private var hole = 1
    @State private var entry = ""
    @State private var isLogging = false
    @State private var message: String?
    @State private var speech = SpeechInput()
    @FocusState private var entryFocused: Bool

    var body: some View {
        let holeShots = round.shotsOnHole(hole)
        let stats = RoundStats(holes: round.holeScores())

        List {
            Section {
                HStack {
                    Button {
                        hole = max(1, hole - 1)
                    } label: {
                        Image(systemName: "chevron.left.circle.fill").font(.title2)
                    }
                    .buttonStyle(.borderless)
                    .disabled(hole == 1)

                    Spacer()
                    VStack(spacing: 2) {
                        Text("Hole \(hole)").font(.title2.bold())
                        Text("Par \(round.par(ofHole: hole)) · \(holeShots.count) logged")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button {
                        hole = min(round.holeCount, hole + 1)
                    } label: {
                        Image(systemName: "chevron.right.circle.fill").font(.title2)
                    }
                    .buttonStyle(.borderless)
                    .disabled(hole == round.holeCount)
                }
                LabeledContent("Round", value: stats.holesPlayed == 0
                    ? "No shots yet"
                    : "\(stats.strokes) strokes thru \(stats.holesPlayed), \(ScoreText.toPar(stats.scoreToPar))")
            }

            Section("Shots") {
                if holeShots.isEmpty {
                    Text("No shots on this hole yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(holeShots.enumerated()), id: \.element.id) { index, shot in
                        ShotRow(number: index + 1, shot: shot)
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(holeShots[index]) }
                    }
                }
            }

            Section {
                CaddieCard(holes: round.holeScores())
            }

            Section {
                NavigationLink {
                    SummaryView(round: round)
                } label: {
                    Label("Round summary", systemImage: "chart.bar.fill")
                }
            }
        }
        .navigationTitle(round.courseName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            entryBar
        }
    }

    private var entryBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if speech.isListening {
                Label("Listening on this iPhone… tap the mic again when you're done.", systemImage: "waveform")
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if case let .unavailable(problem) = speech.state {
                Text(problem)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                Button {
                    toggleListening()
                } label: {
                    Image(systemName: speech.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                        .foregroundStyle(speech.isListening ? Color.red : Color.accentColor)
                }
                .disabled(isLogging)
                .accessibilityLabel(speech.isListening ? "Stop listening" : "Speak a shot")

                TextField(speech.isListening ? "Say the shot…" : "7i 162 right bunker", text: $entry)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .focused($entryFocused)
                    .onSubmit(logShot)
                    .disabled(isLogging)

                Button(action: logShot) {
                    if isLogging {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill").font(.title)
                    }
                }
                .disabled(isLogging || entry.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .onChange(of: speech.transcript) { _, words in
            if speech.isListening { entry = words }
        }
    }

    private func toggleListening() {
        if speech.isListening {
            speech.stop()
            return
        }
        speech.clearProblem()
        message = nil
        entry = ""
        Task {
            await speech.start { words in
                entry = words
                submit(words)
            }
        }
    }

    private func logShot() {
        submit(entry)
    }

    private func submit(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLogging else { return }
        isLogging = true
        message = nil
        let holeNumber = hole

        Task {
            let outcome = await ShotLogger.structure(text)
            isLogging = false
            guard let record = outcome.record else {
                message = "Couldn't find a club in “\(text)”. Try something like “7i 150 right”."
                return
            }
            let shot = LoggedShot(holeNumber: holeNumber, rawText: text, record: record, ai: outcome.ai)
            context.insert(shot)
            shot.round = round
            entry = ""
            if outcome.ai == nil {
                message = "Saved from your words only; the model didn't answer."
            }
        }
    }
}

struct ShotRow: View {
    let number: Int
    let shot: LoggedShot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(number).").foregroundStyle(.secondary)
                Text(shot.record?.summary ?? "Unreadable shot").font(.body.weight(.semibold))
                Spacer()
                SourceBadge(source: shot.source, compact: true)
            }
            HStack(spacing: 6) {
                Text("“\(shot.rawText)”")
                if let ms = shot.latencyMs {
                    Text("· \(ms) ms")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
