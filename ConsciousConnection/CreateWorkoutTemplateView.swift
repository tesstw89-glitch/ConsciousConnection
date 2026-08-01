import SwiftUI

struct CreateWorkoutTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var templateName = ""
    @State private var exercises: [TemplateExerciseDraft] = [TemplateExerciseDraft()]

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Create Workout")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workout name")
                            .foregroundColor(.white.opacity(0.9))

                        TextField("e.g. Quick Pull Day", text: $templateName)
                            .textFieldStyle(.roundedBorder)
                    }

                    ForEach($exercises) { $exercise in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercise")
                                .font(.headline.bold())
                                .foregroundColor(.white)

                            TextField("Exercise title", text: $exercise.title)
                                .textFieldStyle(.roundedBorder)

                            TextField("Detail / note", text: $exercise.detail)
                                .textFieldStyle(.roundedBorder)

                            TextField("Video filename", text: $exercise.videoFileName)
                                .textFieldStyle(.roundedBorder)

                            TextField("Target text (e.g. 8 reps / 30 sec / 6–8 reps)", text: $exercise.targetText)
                                .textFieldStyle(.roundedBorder)

                            Picker("Metric", selection: $exercise.metric) {
                                ForEach(WorkoutMetric.allCases, id: \.self) { metric in
                                    Text(metric.rawValue.capitalized).tag(metric)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper("Sets: \(exercise.setCount)", value: $exercise.setCount, in: 1...12)
                                .foregroundColor(.white)

                            Stepper("Default value: \(exercise.defaultValue)", value: $exercise.defaultValue, in: 1...200)
                                .foregroundColor(.white)

                            Stepper("Rest seconds: \(exercise.restSeconds)", value: $exercise.restSeconds, in: 0...300, step: 5)
                                .foregroundColor(.white)

                            Button {
                                removeExercise(id: exercise.id)
                            } label: {
                                Text("Remove Exercise")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.9))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(WorkoutPressStyle())
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.36))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    Button {
                        exercises.append(TemplateExerciseDraft())
                    } label: {
                        Text("Add Exercise")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())

                    Button {
                        saveTemplate()
                    } label: {
                        Text("Save Workout")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1.0)
                }
                .padding(20)
            }
        }
        .navigationTitle("Create Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func removeExercise(id: UUID) {
        if exercises.count == 1 { return }
        exercises.removeAll { $0.id == id }
    }

    private func saveTemplate() {
        let cleanName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let cleanedExercises = exercises.compactMap { draft -> WorkoutTemplateExercise? in
            let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }

            return WorkoutTemplateExercise(
                title: title,
                detail: draft.detail.trimmingCharacters(in: .whitespacesAndNewlines),
                videoFileName: draft.videoFileName.trimmingCharacters(in: .whitespacesAndNewlines),
                setCount: draft.setCount,
                targetText: draft.targetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(draft.defaultValue) \(draft.metric.unitLabel)" : draft.targetText.trimmingCharacters(in: .whitespacesAndNewlines),
                defaultValue: draft.defaultValue,
                metric: draft.metric,
                restSeconds: draft.restSeconds
            )
        }

        guard !cleanedExercises.isEmpty else { return }

        let template = WorkoutTemplateModel(
            name: cleanName,
            blocks: [
                WorkoutTemplateBlock(
                    title: cleanName,
                    note: "",
                    exercises: cleanedExercises
                )
            ]
        )

        workoutStore.addTemplate(template)
        dismiss()
    }
}

private struct TemplateExerciseDraft: Identifiable {
    let id = UUID()
    var title = ""
    var detail = ""
    var videoFileName = ""
    var setCount = 3
    var targetText = "8 reps"
    var defaultValue = 8
    var metric: WorkoutMetric = .reps
    var restSeconds = 90
}
