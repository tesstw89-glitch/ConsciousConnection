import SwiftUI
import SwiftData

struct RoutineView: View {
    var animateEntrance: Bool = false

    @State private var selectedDay: Int = 0
    @State private var hasAnimatedInitialEntrance = false

    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase

    private let accent = Color(
        red: 0.78,
        green: 0.95,
        blue: 0.25
    )

    private let dayNames = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]

    private var selectedRoutine: SetDeckRoutine {
        exerciseManager.routine(for: selectedDay)
    }

    private var exercises: [SetDeckExercise] {
        (selectedRoutine.exercises ?? [])
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var setCount: Int {
        exercises.reduce(0) {
            $0 + ($1.sets?.count ?? 0)
        }
    }

    private var summaryText: String {
        let exerciseWord = exercises.count == 1
            ? "exercise"
            : "exercises"

        let setWord = setCount == 1
            ? "set"
            : "sets"

        return "\(exercises.count) \(exerciseWord)  •  \(setCount) \(setWord)"
    }

    var body: some View {
        let _ = exerciseManager.changeStamp

        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                header
                    .padding(.horizontal, 20)

                DayPickerView(
                    selectedDay: $selectedDay
                )
                .padding(.horizontal, 16)

                RoutineDayDeckView(
                    routine: selectedRoutine,
                    animateEntrance:
                        animateEntrance &&
                        !hasAnimatedInitialEntrance
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .padding(.top, 8)
        }
        .animation(
            .snappy(duration: 0.3),
            value: selectedDay
        )
        .onAppear {
            selectedDay = todayIndex

            if animateEntrance {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.6
                ) {
                    hasAnimatedInitialEntrance = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                selectedDay = todayIndex
            }
        }
    }

    private var header: some View {
        HStack(
            alignment: .center,
            spacing: 16
        ) {
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text("TRAIN")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.secondary)

                Text(dayNames[selectedDay])
                    .font(
                        .system(
                            size: 34,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(-1)

                Text(summaryText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(
                systemName:
                    "figure.strengthtraining.traditional"
            )
            .font(.system(size: 23, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: 52, height: 52)
            .background(
                accent,
                in: RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
            )
        }
    }

    private var todayIndex: Int {
        let weekday =
            Calendar.current.component(
                .weekday,
                from: Date()
            )

        return (weekday - 1 + 7) % 7
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([
            SetDeckRoutine.self,
            SetDeckExercise.self,
            SetDeckSet.self,
            SetDeckSetHistory.self
        ])

        let configuration =
            ModelConfiguration(
                isStoredInMemoryOnly: true
            )

        return try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }()

    let context = ModelContext(container)
    let manager =
        ExerciseManager(context: context)

    return RoutineView()
        .environment(manager)
        .modelContainer(container)
}
