import AVFAudio
import Foundation
import Observation
import Speech

/// Hands-free shot entry. Recognition is forced on-device
/// (`requiresOnDeviceRecognition`), so audio never leaves the phone and it
/// works in Airplane Mode. APIs checked against Apple's documentation
/// (Speech: SFSpeechRecognizer, SFSpeechAudioBufferRecognitionRequest;
/// AVFAudio: AVAudioApplication.requestRecordPermission()).
@MainActor
@Observable
final class SpeechInput {
    enum State: Equatable {
        case idle
        case listening
        case unavailable(String)
    }

    private(set) var state: State = .idle
    private(set) var transcript = ""

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var onFinish: ((String) -> Void)?

    var isListening: Bool { state == .listening }

    /// Words that help the recognizer with golf vocabulary.
    private static let golfTerms = [
        "driver", "wood", "hybrid", "iron", "wedge", "pitching wedge", "gap wedge", "sand wedge",
        "lob wedge", "putter", "fairway", "green", "fringe", "rough", "bunker", "trap", "trees",
        "water", "out of bounds", "holed", "left", "right", "short", "long", "yards",
    ]

    func start(onFinish: @escaping (String) -> Void) async {
        guard state != .listening else { return }
        transcript = ""

        guard let recognizer, recognizer.supportsOnDeviceRecognition else {
            state = .unavailable("On-device speech recognition isn't available for English on this phone.")
            return
        }
        guard await Self.speechAuthorized() else {
            state = .unavailable("Speech recognition is off for Rounds. Turn it on in Settings.")
            return
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            state = .unavailable("Microphone access is off for Rounds. Turn it on in Settings.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            request.addsPunctuation = false
            request.contextualStrings = Self.golfTerms

            let engine = AVAudioEngine()
            Self.installTap(on: engine.inputNode, feeding: request)
            engine.prepare()
            try engine.start()

            self.engine = engine
            self.request = request
            self.onFinish = onFinish
            state = .listening

            task = Self.startRecognition(recognizer: recognizer, request: request) { [weak self] text, done in
                Task { @MainActor in
                    guard let self else { return }
                    if let text { self.transcript = text }
                    if done { self.finish() }
                }
            }
        } catch {
            stopAudio()
            state = .unavailable("Couldn't start the microphone: \(error.localizedDescription)")
        }
    }

    /// Stop listening; the final transcript is handed to the `onFinish` callback.
    func stop() {
        guard state == .listening else { return }
        request?.endAudio()
        // The recognizer normally delivers a final result right away; finish
        // anyway if it doesn't.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.finish()
        }
    }

    func clearProblem() {
        if case .unavailable = state { state = .idle }
    }

    private func finish() {
        guard state == .listening else { return }
        state = .idle
        stopAudio()
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let callback = onFinish
        onFinish = nil
        if !text.isEmpty { callback?(text) }
    }

    private func stopAudio() {
        if let engine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        engine = nil
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // The audio tap and the recognition callback run on background threads, so
    // they are created outside the main actor.

    nonisolated private static func installTap(on input: AVAudioInputNode,
                                               feeding request: SFSpeechAudioBufferRecognitionRequest) {
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    nonisolated private static func startRecognition(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        update: @escaping @Sendable (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            let text = result?.bestTranscription.formattedString
            let done = (result?.isFinal ?? false) || error != nil
            update(text, done)
        }
    }

    nonisolated private static func speechAuthorized() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
