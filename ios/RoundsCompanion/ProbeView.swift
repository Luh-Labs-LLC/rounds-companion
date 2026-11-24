import SwiftUI

/// Diagnostics screen: on-device availability and one hybrid call.
struct ProbeView: View {
    @State private var probe = HybridProbe()

    var body: some View {
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
                Text("Prompt: \(HybridProbe.prompt)")
            }

            if let result = probe.result {
                Section("Answer") {
                    Text(result.text)
                }
                Section("Routing (reported by the SDK)") {
                    HStack {
                        Text("Answered by")
                        Spacer()
                        SourceBadge(source: result.source)
                    }
                    LabeledContent("modelVersion", value: result.modelVersion)
                        .textSelection(.enabled)
                    LabeledContent("Latency", value: "\(result.latencyMilliseconds) ms")
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
        .navigationTitle("Diagnostics")
    }
}

/// The On-device / Cloud badge shown next to every AI result.
struct SourceBadge: View {
    let source: AnswerSource
    var compact = false

    var body: some View {
        Label(source.label, systemImage: symbol)
            .font(compact ? .caption.bold() : .subheadline.bold())
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 2 : 4)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
            .fixedSize()
    }

    private var symbol: String {
        switch source {
        case .onDevice: "iphone"
        case .cloud: "cloud"
        case .unknown: "questionmark.circle"
        case .notUsed: "text.cursor"
        }
    }

    private var tint: Color {
        switch source {
        case .onDevice: .green
        case .cloud: .blue
        case .unknown: .gray
        case .notUsed: .orange
        }
    }
}
