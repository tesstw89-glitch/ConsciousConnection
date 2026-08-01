import SwiftUI
import UIKit

struct TodaysWorkoutView: View {
    @EnvironmentObject private var router: AppRouter

    private let day = WorkoutPlanner.today()
    private var blocks: [WorkoutBlock] { WorkoutPlanLibrary.blocks(for: day) }

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(day.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    if day.isRestDay {
                        Text("Rest day. You can still check your log or calendar.")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.92))

                        WorkoutMenuButton(
                            title: "Go to Calendar",
                            subtitle: nil
                        ) {
                            makeTapFeelGood()
                            router.path.append(.workoutCalendar)
                        }

                    } else {
                        ForEach(blocks) { block in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(block.title)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                if let note = block.note {
                                    Text(note)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                ForEach(block.exercises) { exercise in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("• \(exercise.title)")
                                            .foregroundColor(.white)

                                        if let detail = exercise.detail {
                                            Text(detail)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .padding(.leading, 14)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        Button {
                            makeTapFeelGood()
                            router.path.append(.workoutSession(day))
                        } label: {
                            Image("StartWorkout")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 240)
                        }
                        .buttonStyle(WorkoutPressStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .padding(.top, 44)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func makeTapFeelGood() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
