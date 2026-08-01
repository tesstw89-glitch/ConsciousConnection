import SwiftUI
import SwiftData
import UIKit

@main
struct ConsciousConnectionApp: App {

    @StateObject private var router = AppRouter()
    @StateObject private var workoutStore = WorkoutStore()

    let habitModelContainer: ModelContainer?
    let habitInitializationError: Error?

    init() {
        var container: ModelContainer?
        var initializationError: Error?

        do {
            let schema = Schema([
                Habit.self,
                HabitCompletion.self,
                HabitStack.self,
                FocusSession.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            initializationError = error
        }

        self.habitModelContainer = container
        self.habitInitializationError = initializationError
    }

    var body: some Scene {
        WindowGroup {
            if let container = habitModelContainer {
                NavigationStack(path: $router.path) {
                    ContentView()
                        .navigationDestination(for: Route.self) { route in
                            switch route {

                            case .goodMorning:
                                GoodMorningView()

                            case .fearMorning:
                                BreatheVideoView(
                                    videoName: "Fear",
                                    nextRoute: .collectFearMorning
                                )

                            case .collectFearMorning:
                                BreatheVideoView(
                                    videoName: "Collectfear",
                                    nextRoute: .breatheMorning
                                )

                            case .breatheMorning:
                                BreatheVideoView(nextRoute: .gratitude)

                            case .breatheYouAreHere:
                                BreatheVideoView(nextRoute: .gratitudeNow)

                            case .gratitude:
                                GratitudePromptView()

                            case .gratitudeTouchstone:
                                GratitudeTouchstoneView()

                            case .checklist:
                                MorningRoutineChecklistVideoView()

                            case .timeBucket(let minutes):
                                TimeBucketView(minutes: minutes)

                            case .weeklyTasks:
                                WeeklyTasksView()

                            case .gratitudeNow:
                                GratitudeNowView()

                            case .sedona:
                                SedonaVideoView()

                            case .nightVideo1:
                                NightRoutineVideoView(
                                    videoName: "NightVideo1",
                                    nextRoute: .nightVideo2
                                )

                            case .nightVideo2:
                                NightRoutineVideoView(
                                    videoName: "NightVideo2",
                                    nextRoute: .nightVideo3
                                )

                            case .nightVideo3:
                                NightRoutineVideoView(
                                    videoName: "NightVideo3",
                                    nextRoute: nil
                                )

                            case .resetMenu:
                                ResetMenuView()

                            case .states:
                                StatesView()

                            case .stateDetail(let idx):
                                StateDetailView(index: idx) { newIndex in
                                    router.path.append(.stateDetail(newIndex))
                                }

                            case .spiral:
                                SpiralTriggerView { trigger in
                                    router.path.append(.spiralStates(trigger))
                                }

                            case .spiralStates(let trigger):
                                SpiralStatesView(trigger: trigger) { stateIndex in
                                    router.path.append(.spiralDetail(trigger, stateIndex))
                                }

                            case .spiralDetail(let trigger, let index):
                                SpiralDetailView(
                                    trigger: trigger,
                                    rung: SCALE[index],
                                    onChangeState: { newRung in
                                        router.path.append(.spiralDetail(trigger, newRung.r - 1))
                                    },
                                    onGoEMT: { currentIndex in
                                        router.path.append(.spiralEMT(trigger, currentIndex))
                                    },
                                    onReset: {
                                        router.path = [.spiral]
                                    }
                                )

                            case .spiralEMT(let trigger, let index):
                                SpiralEMTView(trigger: trigger, index: index) {
                                    router.path.append(.spiralSedona(trigger, index))
                                }

                            case .spiralSedona(let trigger, let index):
                                SpiralSedonaView(trigger: trigger, index: index)

                            case .workMorningIntro:
                                WorkMorningIntroView()

                            case .workMorningRoutine:
                                WorkMorningRoutineView()

                            case .morningMeditation:
                                MorningMeditationView()

                            case .setIntention:
                                SetIntentionView()

                            case .workEveningIntro:
                                WorkEveningIntroView()

                            case .workEveningTasks:
                                WorkEveningTasksView()

                            case .workoutMenu:
                                WorkoutMenuView()

                            case .todaysWorkout:
                                TodaysWorkoutView()

                            case .workoutSession(let day):
                                WorkoutSessionView(day: day)

                            case .workoutLog:
                                WorkoutLogView()

                            case .workoutCalendar:
                                WorkoutCalendarView()

                            case .workoutTemplates:
                                WorkoutTemplatesView()

                            case .createWorkoutTemplate:
                                CreateWorkoutTemplateView()

                            case .workoutTemplateSession(let templateID):
                                TemplateWorkoutSessionView(templateID: templateID)
                            }
                        }
                }
                .environmentObject(router)
                .environmentObject(workoutStore)
                .modelContainer(container)
                .environment(\.isUsingLocalStorage, false)
                .onAppear {
                    NotificationManager.shared.requestPermissionAndScheduleTaskReminders()
                    handleLockScreenLaunchIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleLockScreenLaunchIfNeeded()
                }
            } else {
                DataErrorView(error: habitInitializationError)
            }
        }
    }

    private func handleLockScreenLaunchIfNeeded() {
        let defaults = UserDefaults(suiteName: "group.com.tess.ConsciousConnection")

        guard defaults?.object(forKey: "LockScreenLaunchRequest") != nil else { return }

        defaults?.removeObject(forKey: "LockScreenLaunchRequest")

        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 9 {
            router.path = [.goodMorning]
        } else if hour >= 21 {
            router.path = [.nightVideo1]
        } else {
            router.goHome()
        }
    }
}

private struct IsUsingLocalStorageKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isUsingLocalStorage: Bool {
        get { self[IsUsingLocalStorageKey.self] }
        set { self[IsUsingLocalStorageKey.self] = newValue }
    }
}

struct DataErrorView: View {
    let error: Error?
    @State private var showingDetails = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Unable to Load Habit Data")
                    .font(.title2.weight(.bold))

                Text("The habit module couldn't initialize its database.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let error {
                Button {
                    showingDetails.toggle()
                } label: {
                    HStack {
                        Text("Technical Details")
                            .font(.caption)
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if showingDetails {
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .padding()
    }
}
