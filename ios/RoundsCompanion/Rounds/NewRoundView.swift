import PhotosUI
import RoundsKit
import SwiftUI
import UIKit

/// Set up a round: course name, 9 or 18 holes, and the par of each hole.
struct NewRoundView: View {
    @Environment(\.dismiss) private var dismiss
    let onStart: (Round) -> Void

    @State private var courseName = ""
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 4, count: 18)
    @State private var uncertainHoles: Set<Int> = []
    @State private var photoItem: PhotosPickerItem?
    @State private var isReading = false
    @State private var scan: AIResult?
    @State private var scanProblem: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    TextField("Course name", text: $courseName)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack {
                            Label("Read pars from a scorecard photo", systemImage: "camera.viewfinder")
                            if isReading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isReading)

                    if let scan {
                        HStack {
                            Text(uncertainHoles.isEmpty
                                ? "Read \(holeCount) pars. Check them below."
                                : "Read \(holeCount) pars; check the highlighted holes.")
                            Spacer()
                            SourceBadge(source: scan.source, compact: true)
                        }
                        .font(.footnote)
                        Text("\(scan.latencyMilliseconds) ms · \(scan.modelVersion)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let scanProblem {
                        Text(scanProblem).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Scorecard")
                } footer: {
                    Text("Reading a photo needs signal: the on-device model handles text only, so photos go to Gemini in the cloud.")
                }

                Section("Holes") {
                    Picker("Holes", selection: $holeCount) {
                        Text("9 holes").tag(9)
                        Text("18 holes").tag(18)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ForEach(0..<holeCount, id: \.self) { index in
                        Stepper(value: $pars[index], in: 3...6) {
                            HStack {
                                Text("Hole \(index + 1)")
                                if uncertainHoles.contains(index) {
                                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                                }
                                Spacer()
                                Text("Par \(pars[index])").foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Pars")
                } footer: {
                    Text("Total par \(pars.prefix(holeCount).reduce(0, +)).")
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await readScorecard(item) }
            }
            .navigationTitle("New round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let name = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let round = Round(
                            courseName: name.isEmpty ? "Unnamed course" : name,
                            pars: Array(pars.prefix(holeCount))
                        )
                        onStart(round)
                        dismiss()
                    }
                }
            }
        }
    }

    private func readScorecard(_ item: PhotosPickerItem) async {
        isReading = true
        scanProblem = nil
        scan = nil
        defer {
            isReading = false
            photoItem = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            scanProblem = "Couldn't open that photo."
            return
        }
        do {
            let answer = try await HybridText.preferOnDevice(
                image: Self.downscaled(image, maxSide: 1600),
                prompt: ScorecardReader.prompt
            )
            guard let read = ScorecardReader.pars(from: answer.text) else {
                scan = nil
                scanProblem = "Couldn't read a 9- or 18-hole par row from that photo. Set the pars by hand."
                return
            }
            holeCount = read.count
            var updated = pars
            var unsure: Set<Int> = []
            for (index, par) in read.enumerated() {
                if let par {
                    updated[index] = par
                } else {
                    unsure.insert(index)
                }
            }
            pars = updated
            uncertainHoles = unsure
            scan = answer
        } catch {
            scanProblem = "Couldn't read the photo. It needs signal, because photos go to the cloud model."
        }
    }

    /// Phone photos are large; a smaller copy is plenty for reading a scorecard.
    private static func downscaled(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
