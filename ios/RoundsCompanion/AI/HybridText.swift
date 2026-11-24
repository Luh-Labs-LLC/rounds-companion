import FirebaseAILogic
import Foundation
import UIKit

/// Where an answer came from, read from the SDK's own report
/// (`GenerateContentResponse.modelVersion`), never inferred. `.notUsed` marks a
/// result that came from deterministic code because no model answered.
enum AnswerSource: String, Equatable, Sendable {
    case onDevice
    case cloud
    case unknown
    case notUsed

    var label: String {
        switch self {
        case .onDevice: "On-device"
        case .cloud: "Cloud"
        case .unknown: "Unknown"
        case .notUsed: "Words only"
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
}

/// One model answer plus the SDK's report of who produced it.
struct AIResult: Sendable {
    let text: String
    let modelVersion: String
    let source: AnswerSource
    let latency: Duration

    var latencyMilliseconds: Int {
        Int(Double(latency.components.seconds) * 1000 + Double(latency.components.attoseconds) / 1e15)
    }
}

/// Firebase AI Logic hybrid calls. Every call uses a fresh session: a session
/// answers one request at a time, and the SDK only falls back from on-device
/// to cloud while the on-device session has no history.
enum HybridText {
    /// Prefer the on-device model; fall back to Gemini in the cloud.
    nonisolated static func preferOnDevice(prompt: String, instructions: String? = nil) async throws -> AIResult {
        let (session, systemModelName) = makeSession(instructions: instructions)
        let clock = ContinuousClock()
        let start = clock.now
        let response = try await session.respond(to: prompt)
        return result(response, latency: clock.now - start, systemModelName: systemModelName)
    }

    /// Same hybrid session with a photo. Apple's on-device model accepts text
    /// only, so the SDK's on-device session throws `unsupportedPromptContent`
    /// and the hybrid session retries on Gemini: routing by capability.
    /// (firebase-ios-sdk 12.19.3: Types/Public/Part.swift, HybridModelSession.swift)
    nonisolated static func preferOnDevice(image: UIImage, prompt: String) async throws -> AIResult {
        let (session, systemModelName) = makeSession(instructions: nil)
        let clock = ContinuousClock()
        let start = clock.now
        let response = try await session.respond(to: image, prompt)
        return result(response, latency: clock.now - start, systemModelName: systemModelName)
    }

    /// Cloud only (Gemini), for the long post-round debrief: no on-device
    /// attempt, so it needs signal. The SDK's report still drives the badge.
    nonisolated static func cloudOnly(prompt: String, instructions: String?) async throws -> AIResult {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let cloudModel = ai.geminiModel(name: AIConfig.cloudModelName)
        let session = ai.generativeModelSession(model: cloudModel, instructions: instructions)
        let clock = ContinuousClock()
        let start = clock.now
        let response = try await session.respond(to: prompt)
        return result(
            response,
            latency: clock.now - start,
            systemModelName: FirebaseAI.SystemLanguageModel.default._modelName
        )
    }

    nonisolated private static func makeSession(instructions: String?) -> (GenerativeModelSession, String) {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let systemModel = FirebaseAI.SystemLanguageModel.default
        let cloudModel = ai.geminiModel(name: AIConfig.cloudModelName)
        let session = ai.generativeModelSession(
            model: HybridModel(primary: systemModel, secondary: cloudModel),
            instructions: instructions
        )
        return (session, systemModel._modelName)
    }

    /// The SDK sets modelVersion to the answering model's name. Comparing to the
    /// system model's `_modelName` mirrors the SDK's own hybrid integration test
    /// (FirebaseAI/Tests/TestApp/Tests/Integration/GenerativeModelSessionHybridTests.swift).
    nonisolated private static func result(
        _ response: GenerativeModelSession.Response<String>,
        latency: Duration,
        systemModelName: String
    ) -> AIResult {
        let modelVersion = response.rawResponse.modelVersion
        let source: AnswerSource
        if modelVersion == systemModelName {
            source = .onDevice
        } else if modelVersion.isEmpty || modelVersion == AIConfig.unknownModelVersion {
            source = .unknown
        } else {
            source = .cloud
        }
        return AIResult(text: response.content, modelVersion: modelVersion, source: source, latency: latency)
    }

    /// Whether Apple's on-device model can answer right now, in words.
    @MainActor
    static var onDeviceStatus: String {
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
}
