import SwiftUI

enum Route: Hashable {
    case goodMorning

    // Morning flow
    case fearMorning
    case collectFearMorning
    case breatheMorning
    case breatheYouAreHere
    case gratitude
    case checklist
    case gratitudeNow
    case sedona
    case gratitudeTouchstone
    case workMorningIntro
    case workMorningRoutine
    case morningMeditation
    case setIntention
    case workEveningIntro
    case workEveningTasks

    case createWorkoutTemplate
    case workoutTemplateSession(UUID)

    case timeBucket(Int)
    case weeklyTasks

    case nightVideo1
    case nightVideo2
    case nightVideo3

    case resetMenu
    case states
    case stateDetail(Int)
    case spiral
    case spiralStates(String)
    case spiralDetail(String, Int)
    case spiralEMT(String, Int)
    case spiralSedona(String, Int)

    // Workout
    case workoutMenu
    case todaysWorkout
    case workoutSession(WorkoutDay)
    case workoutLog
    case workoutCalendar
    case workoutTemplates

    // HabitFlow
}

final class AppRouter: ObservableObject {
    @Published var path: [Route] = []

    func goHome() {
        path.removeAll()
    }

    func goToTime(_ minutes: Int) {
        path.append(.timeBucket(minutes))
    }

    func goToWeekly() {
        path.append(.weeklyTasks)
    }

    func goToWorkoutMenu() {
        path.append(.workoutMenu)
    }

    func goToTodaysWorkout() {
        path.append(.todaysWorkout)
    }
}
