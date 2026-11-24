import SwiftUI

/// Set up a round: course name, 9 or 18 holes, and the par of each hole.
struct NewRoundView: View {
    @Environment(\.dismiss) private var dismiss
    let onStart: (Round) -> Void

    @State private var courseName = ""
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 4, count: 18)

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    TextField("Course name", text: $courseName)
                        .textInputAutocapitalization(.words)
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
}
