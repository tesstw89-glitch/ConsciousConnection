import SwiftUI

struct WorkoutTemplatesView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var workoutStore: WorkoutStore

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Saved Workouts")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    WorkoutMenuButton(
                        title: "Create New Workout",
                        subtitle: "Build your own saved workout template"
                    ) {
                        router.path.append(.createWorkoutTemplate)
                    }

                    if workoutStore.templates.isEmpty {
                        Text("No saved workouts yet.")
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.top, 8)
                    } else {
                        ForEach(workoutStore.templates) { template in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(template.name)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)

                                Text("\(template.exerciseCount) exercises")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.82))

                                HStack(spacing: 10) {
                                    Button {
                                        router.path.append(.workoutTemplateSession(template.id))
                                    } label: {
                                        Text("Start")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.blue.opacity(0.9))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(WorkoutPressStyle())

                                    Button {
                                        workoutStore.deleteTemplate(id: template.id)
                                    } label: {
                                        Text("Delete")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.red.opacity(0.9))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(WorkoutPressStyle())
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Saved Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
