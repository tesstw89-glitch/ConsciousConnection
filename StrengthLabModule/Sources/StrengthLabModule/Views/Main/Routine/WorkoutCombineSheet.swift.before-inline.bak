import SwiftUI

/// Builds a new, independent workout from two saved workout templates.
/// The source workouts are never edited or removed.
struct WorkoutCombineSheet: View {
    let workouts: [WorkoutTemplate]
    let onCombine: (WorkoutTemplate, WorkoutTemplate, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firstWorkoutID: UUID?
    @State private var secondWorkoutID: UUID?
    @State private var newName = ""

    private var firstWorkout: WorkoutTemplate? {
        workouts.first { $0.uuid == firstWorkoutID }
    }

    private var secondWorkout: WorkoutTemplate? {
        workouts.first { $0.uuid == secondWorkoutID }
    }

    private var suggestedName: String {
        guard let firstWorkout, let secondWorkout else {
            return "Combined Workout"
        }
        return "\(firstWorkout.name) + \(secondWorkout.name)"
    }

    private var finalName: String {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? suggestedName : trimmed
    }

    private var canCombine: Bool {
        guard let firstWorkout, let secondWorkout else { return false }
        return firstWorkout.uuid != secondWorkout.uuid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("First workout", selection: $firstWorkoutID) {
                        Text("Choose workout").tag(nil as UUID?)
                        ForEach(workouts, id: \.uuid) { workout in
                            Text(workout.name).tag(workout.uuid as UUID?)
                        }
                    }

                    if let firstWorkout {
                        Text("\(firstWorkout.exercises?.count ?? 0) exercises")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Workout 1")
                } footer: {
                    Text("These exercises will come first.")
                }

                Section("Workout 2") {
                    Picker("Second workout", selection: $secondWorkoutID) {
                        Text("Choose workout").tag(nil as UUID?)
                        ForEach(workouts.filter { $0.uuid != firstWorkoutID }, id: \.uuid) { workout in
                            Text(workout.name).tag(workout.uuid as UUID?)
                        }
                    }

                    if let secondWorkout {
                        Text("\(secondWorkout.exercises?.count ?? 0) exercises")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("Workout name", text: $newName)
                        .textInputAutocapitalization(.words)

                    if newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Suggested: \(suggestedName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("New workout")
                } footer: {
                    Text("Creates a separate workout with all exercises and sets, in order. You can edit it afterwards. Both originals stay unchanged.")
                }

                if let firstWorkout, let secondWorkout,
                   firstWorkout.uuid != secondWorkout.uuid {
                    Section("Preview") {
                        HStack {
                            Text("Exercises")
                            Spacer()
                            Text("\((firstWorkout.exercises ?? []).count + (secondWorkout.exercises ?? []).count)")
                                .foregroundStyle(.secondary)
                        }
                        Text("\(firstWorkout.name) → \(secondWorkout.name)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Combine Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .tint(StrengthLabFigmaTheme.coral)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let firstWorkout, let secondWorkout,
                              firstWorkout.uuid != secondWorkout.uuid else { return }
                        onCombine(firstWorkout, secondWorkout, finalName)
                    }
                    .disabled(!canCombine)
                }
            }
            .onChange(of: firstWorkoutID) { _, selected in
                // Do not allow the same workout to occupy both slots.
                if secondWorkoutID == selected { secondWorkoutID = nil }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
