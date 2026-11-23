import SwiftUI

struct ProbeView: View {
    @State private var probe = HybridProbe()

    var body: some View {
        NavigationStack {
            List {
                Section("On-device model") {
                    LabeledContent("Status", value: probe.onDeviceStatus)
                }

                Section {
                    Button {
                        Task { await probe.run() }
                    } label: {
                        HStack {
                            Text("Run hybrid call")
                            if probe.isRunning {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(probe.isRunning)
                } footer: {
                    Text("Prompt: \(AIConfig.probePrompt)")
                }

                if let result = probe.result {
                    Section("Answer") {
                        Text(result.text)
                    }
                    Section("Routing (reported by the SDK)") {
                        LabeledContent("Answered by") {
                            SourceBadge(source: result.source)
                        }
                        LabeledContent("modelVersion", value: result.modelVersion)
                            .textSelection(.enabled)
                        LabeledContent("Latency", value: Self.format(result.latency))
                    }
                }

                if let message = probe.errorMessage {
                    Section("Error") {
                        Text(message)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Rounds Companion")
        }
    }

    private static func format(_ duration: Duration) -> String {
        let ms = Double(duration.components.seconds) * 1000
            + Double(duration.components.attoseconds) / 1e15
        return String(format: "%.0f ms", ms)
    }
}

struct SourceBadge: View {
    let source: AnswerSource

    var body: some View {
        Label(source.label, systemImage: symbol)
            .font(.subheadline.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }

    private var symbol: String {
        switch source {
        case .onDevice: "iphone"
        case .cloud: "cloud"
        case .unknown: "questionmark.circle"
        }
    }

    private var tint: Color {
        switch source {
        case .onDevice: .green
        case .cloud: .blue
        case .unknown: .gray
        }
    }
}
