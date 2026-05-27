import SwiftUI
import UIKit

struct WorkoutMenuView: View {
    @EnvironmentObject private var router: AppRouter

    private var today = WorkoutPlanner.today()

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Workout")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Today: \(today.title)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.92))

                    WorkoutMenuButton(
                        title: "Today’s Workout",
                        subtitle: "Open the workout for today"
                    ) {
                        makeTapFeelGood()
                        router.path.append(.todaysWorkout)
                    }

                    WorkoutMenuButton(
                        title: "Workout Log",
                        subtitle: "See completed and skipped sets"
                    ) {
                        makeTapFeelGood()
                        router.path.append(.workoutLog)
                    }

                    WorkoutMenuButton(
                        title: "Calendar",
                        subtitle: "See workout days across the month"
                    ) {
                        makeTapFeelGood()
                        router.path.append(.workoutCalendar)
                    }

                    WorkoutMenuButton(
                        title: "Saved Workouts",
                        subtitle: "Templates/custom workouts"
                    ) {
                        makeTapFeelGood()
                        router.path.append(.workoutTemplates)
                    }
                }
                .padding(20)
                .padding(.top, 44)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func makeTapFeelGood() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
