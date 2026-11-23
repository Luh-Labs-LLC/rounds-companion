import FirebaseAILogic
import Foundation
import Observation

/// Where an answer came from, read from the SDK's own report
/// (`GenerateContentResponse.modelVersion`), never inferred.
enum AnswerSource: Equatable, Sendable {
    case onDevice
    case cloud
    case unknown

    var label: String {
        switch self {
        case .onDevice: "On-device"
        case .cloud: "Cloud"
        case .unknown: "Unknown"
        }
    }
}

enum AIConfig {
    /// Cloud fallback model (Gemini Developer API, no billing required).
    /// Checked against https://firebase.google.com/docs/ai-logic/models on 2026-11-23.
    static let cloudModelName = "gemini-3.5-flash-lite"

    /// The SDK's placeholder when a response carries no model version. Source:
    /// firebase-ios-sdk 12.19.3, FirebaseAI/Sources/GenerateContentResponse.swift
    static let unknownModelVersion = "unknown-model-version"

    static let probePrompt =
        "In one sentence, give a golfer a tip for staying calm after a bad hole."
}

struct ProbeResult: Sendable {
    let text: String
    let modelVersion: String
    let source: AnswerSource
    let latency: Duration
}

/// Makes one Firebase AI Logic hybrid call that prefers the on-device model and
/// falls back to Gemini in the cloud.
@MainActor
@Observable
final class HybridProbe {
    private(set) var isRunning = false
    private(set) var result: ProbeResult?
    private(set) var errorMessage: String?

    var onDeviceStatus: String {
        switch FirebaseAI.SystemLanguageModel.default.availability {
        case .available:
            return "Available"
        case let .unavailable(reason):
            switch reason {
            case .deviceNotEligible:
                return "Unavailable: device not eligible"
            case .appleIntelligenceNotEnabled:
                return "Unavailable: Apple Intelligence is off"
            case .modelNotReady:
                return "Unavailable: model not ready (still downloading?)"
            case .unknown:
                return "Unavailable: unknown reason"
            @unknown default:
                return "Unavailable: \(String(describing: reason))"
            }
        }
    }

    func run() async {
        guard !isRunning else { return }
        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        do {
            result = try await Self.callHybrid(prompt: AIConfig.probePrompt)
        } catch {
            result = nil
            errorMessage = String(describing: error)
        }
    }

    /// Runs off the main actor and hands back only Sendable values.
    nonisolated private static func callHybrid(prompt: String) async throws -> ProbeResult {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let systemModel = FirebaseAI.SystemLanguageModel.default
        let cloudModel = ai.geminiModel(name: AIConfig.cloudModelName)

        // Prefer on-device: the system model is primary, Gemini is the fallback.
        // A new session per run, because a session handles one request at a time.
        let session = ai.generativeModelSession(
            model: HybridModel(primary: systemModel, secondary: cloudModel)
        )

        let clock = ContinuousClock()
        let start = clock.now
        let response = try await session.respond(to: prompt)
        let latency = clock.now - start

        // The SDK sets modelVersion to the answering model's name. Comparing to each
        // model's `_modelName` mirrors the SDK's own hybrid integration test
        // (FirebaseAI/Tests/TestApp/Tests/Integration/GenerativeModelSessionHybridTests.swift).
        // `_modelName` is marked internal-use, which is acceptable because the SDK is pinned.
        let modelVersion = response.rawResponse.modelVersion
        let source: AnswerSource
        if modelVersion == systemModel._modelName {
            source = .onDevice
        } else if modelVersion.isEmpty || modelVersion == AIConfig.unknownModelVersion {
            source = .unknown
        } else {
            // Any other value is the version string Gemini returned from the cloud.
            source = .cloud
        }

        return ProbeResult(
            text: response.content,
            modelVersion: modelVersion,
            source: source,
            latency: latency
        )
    }
}
