import Foundation
import Observation

/// Diagnostics: one prefer-on-device call with a fixed prompt, to check the
/// hybrid path on a device (the Wednesday kill check ran on this).
@MainActor
@Observable
final class HybridProbe {
    static let prompt = "In one sentence, give a golfer a tip for staying calm after a bad hole."

    private(set) var isRunning = false
    private(set) var result: AIResult?
    private(set) var errorMessage: String?

    var onDeviceStatus: String { HybridText.onDeviceStatus }

    func run() async {
        guard !isRunning else { return }
        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        do {
            result = try await HybridText.preferOnDevice(prompt: Self.prompt)
        } catch {
            result = nil
            errorMessage = String(describing: error)
        }
    }
}
