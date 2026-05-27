import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            if workoutStore.logs.isEmpty {
                VStack(spacing: 12) {
                    Text("No workouts logged yet.")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Finish a workout and it’ll appear here.")
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(workoutStore.logs) { entry in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.displayTitle)
                                            .font(.headline.bold())
                                            .foregroundColor(.white)

                                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.82))
                                    }

                                    Spacer()

                                    if entry.endedEarly {
                                        Text("Ended early")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.orange.opacity(0.9))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("Completed sets: \(entry.completedSetCount)")
                                    .foregroundColor(.white.opacity(0.92))

                                Text("Skipped sets: \(entry.skippedSetCount)")
                                    .foregroundColor(.white.opacity(0.92))

                                Text("Skipped exercises: \(entry.skippedExerciseCount)")
                                    .foregroundColor(.white.opacity(0.92))

                                Divider()
                                    .overlay(Color.white.opacity(0.3))

                                ForEach(entry.blocks) { block in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(block.title)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)

                                        ForEach(block.exercises) { exercise in
                                            Text("• \(exercise.title)\(exercise.skipped ? " — skipped" : "")")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.84))
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.36))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}
