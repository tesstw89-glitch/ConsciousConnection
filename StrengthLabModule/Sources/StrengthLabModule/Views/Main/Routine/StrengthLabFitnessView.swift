import SwiftUI
import SwiftData

// MARK: - StrengthLab Fitness UI
//
// New iPhone workout presentation.
// Keeps the existing StrengthLab models/managers underneath.

struct StrengthLabFitnessView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedDay: Int = 0

    private let purple = Color(
        red: 0.40,
        green: 0.22,
        blue: 0.94
    )

    private let violet = Color(
        red: 0.53,
        green: 0.34,
        blue: 0.98
    )

    private let lime = Color(
        red: 0.78,
        green: 0.94,
        blue: 0.28
    )

    private let warmBackground = Color(
        red: 0.965,
        green: 0.958,
        blue: 0.945
    )

    private var routine: SetDeckRoutine {
        exerciseManager.routine(for: selectedDay)
    }

    private var exercises: [SetDeckExercise] {
        (routine.exercises ?? [])
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var totalSets: Int {
        exercises.reduce(0) { result, exercise in
            result + exerciseManager.sets(for: exercise).count
        }
    }

    private var demoCount: Int {
        exercises.filter { $0.gifURL != nil }.count
    }

    private var dayName: String {
        Calendar.current.weekdaySymbols[selectedDay]
    }

    var body: some View {
        let _ = exerciseManager.changeStamp

        ZStack {
            warmBackground
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        topHeader

                        heroCard {
                            Haptics.lightImpact()

                            withAnimation(
                                .spring(
                                    response: 0.45,
                                    dampingFraction: 0.86
                                )
                            ) {
                                proxy.scrollTo(
                                    "exercise-section",
                                    anchor: .top
                                )
                            }
                        }

                    weekStrip

                    summaryCards

                    exerciseHeader
                        .id("exercise-section")

                    if exercises.isEmpty {
                        restDayCard
                    } else {
                        ForEach(
                            Array(exercises.enumerated()),
                            id: \.element.uuid
                        ) { index, exercise in
                            StrengthLabFitnessExerciseCard(
                                number: index + 1,
                                exercise: exercise,
                                purple: purple,
                                lime: lime
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            selectedDay = todayIndex

            for day in 0..<7 {
                _ = exerciseManager.routine(for: day)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                selectedDay = todayIndex
            }
        }
    }

    // MARK: Header

    private var topHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("STRENGTHLAB")
                    .font(.caption2.weight(.black))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Workout")
                    .font(
                        .system(
                            size: 34,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(-1.1)
                    .foregroundStyle(.black)
            }

            Spacer()

            Button {
                Haptics.lightImpact()
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(
                        Color.white,
                        in: Circle()
                    )
                    .shadow(
                        color: .black.opacity(0.06),
                        radius: 10,
                        y: 5
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Hero

    private func heroCard(
        onOpenWorkout: @escaping () -> Void
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [
                    purple,
                    violet
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.09))
                .frame(width: 190, height: 190)
                .offset(x: 65, y: 75)

            Circle()
                .stroke(
                    .white.opacity(0.10),
                    lineWidth: 18
                )
                .frame(width: 130, height: 130)
                .offset(x: 25, y: 38)

            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                HStack {
                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("TODAY'S WORKOUT")
                            .font(.caption2.weight(.black))
                            .tracking(1.7)
                            .foregroundStyle(
                                .white.opacity(0.72)
                            )

                        Text(dayName)
                            .font(
                                .system(
                                    size: 29,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Image(
                        systemName:
                            "figure.strengthtraining.traditional"
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.black)
                    .frame(width: 55, height: 55)
                    .background(
                        lime,
                        in: RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                }

                HStack(spacing: 22) {
                    heroStat(
                        value: "\(exercises.count)",
                        label: "Exercises"
                    )

                    heroStat(
                        value: "\(totalSets)",
                        label: "Sets"
                    )

                    heroStat(
                        value: "\(demoCount)",
                        label: "Demos"
                    )
                }

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.bold))

                    Text(
                        Date.now.formatted(
                            .dateTime
                                .month(.wide)
                                .day()
                        )
                    )
                    .font(.subheadline.weight(.semibold))

                    Spacer()

                    Button(action: onOpenWorkout) {
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 40, height: 40)
                            .background(
                                .white,
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View today's exercises")
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 225)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
        .shadow(
            color: purple.opacity(0.22),
            radius: 22,
            y: 12
        )
    }

    private func heroStat(
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(
                    .system(
                        size: 23,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.68)
                )
        }
    }

    // MARK: Week

    private var weekStrip: some View {
        HStack(spacing: 7) {
            ForEach(0..<7, id: \.self) { day in
                let selected = day == selectedDay
                let today = day == todayIndex

                Button {
                    withAnimation(
                        .snappy(duration: 0.28)
                    ) {
                        selectedDay = day
                    }

                    Haptics.lightImpact()
                } label: {
                    VStack(spacing: 7) {
                        Text(shortDay(day))
                            .font(
                                .caption.weight(.bold)
                            )

                        Text("\(dayDate(day))")
                            .font(
                                .subheadline.weight(.bold)
                            )

                        Circle()
                            .fill(
                                today
                                    ? (
                                        selected
                                            ? Color.white
                                            : purple
                                    )
                                    : Color.clear
                            )
                            .frame(width: 4, height: 4)
                    }
                    .foregroundStyle(
                        selected
                            ? Color.white
                            : Color.black
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 70
                    )
                    .background(
                        selected
                            ? purple
                            : Color.white,
                        in: RoundedRectangle(
                            cornerRadius: 19,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: .black.opacity(
                            selected ? 0.09 : 0.035
                        ),
                        radius: 10,
                        y: 5
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Summary

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                icon: "dumbbell.fill",
                title: "\(exercises.count)",
                subtitle: "Exercises",
                tint: purple
            )

            summaryCard(
                icon: "square.stack.3d.up.fill",
                title: "\(totalSets)",
                subtitle: "Total sets",
                tint: Color(
                    red: 1.0,
                    green: 0.48,
                    blue: 0.30
                )
            )

            summaryCard(
                icon: "play.rectangle.fill",
                title: "\(demoCount)",
                subtitle: "Demos",
                tint: Color(
                    red: 0.12,
                    green: 0.70,
                    blue: 0.58
                )
            )
        }
    }

    private func summaryCard(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    tint.opacity(0.12),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            Text(title)
                .font(
                    .system(
                        size: 23,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.black)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    // MARK: Exercise section

    private var exerciseHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Your exercises")
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.black)

            Spacer()

            Text("\(exercises.count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 3)
    }

    private var restDayCard: some View {
        VStack(spacing: 15) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 38))
                .foregroundStyle(purple)

            Text("Rest day")
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.black)

            Text(
                "Nothing scheduled today. Recovery counts too."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 25)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
        )
    }

    // MARK: Calendar helpers

    private var todayIndex: Int {
        Calendar.current.component(
            .weekday,
            from: Date()
        ) - 1
    }

    private func shortDay(_ day: Int) -> String {
        let symbols =
            Calendar.current.veryShortWeekdaySymbols

        guard symbols.indices.contains(day)
        else {
            return ""
        }

        return symbols[day]
    }

    private func dayDate(_ day: Int) -> Int {
        let calendar = Calendar.current

        let todayWeekday =
            calendar.component(
                .weekday,
                from: Date()
            ) - 1

        let difference = day - todayWeekday

        let date =
            calendar.date(
                byAdding: .day,
                value: difference,
                to: Date()
            ) ?? Date()

        return calendar.component(
            .day,
            from: date
        )
    }
}


// MARK: - Exercise Card

private struct StrengthLabFitnessExerciseCard: View {
    @Environment(ExerciseManager.self)
    private var exerciseManager

    let number: Int
    let exercise: SetDeckExercise
    let purple: Color
    let lime: Color

    @State private var expandedSetID: UUID?
    @State private var showMediaEditor = false
    @State private var showDemo = true

    private var sets: [SetDeckSet] {
        let fetched =
            exerciseManager.sets(for: exercise)

        if !fetched.isEmpty {
            return fetched
        }

        return (exercise.sets ?? [])
            .sorted {
                $0.orderIndex < $1.orderIndex
            }
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            exerciseTopRow

            if
                let gifURL = exercise.gifURL,
                showDemo
            {
                ZStack(alignment: .topTrailing) {
                    ExerciseMediaPlaybackView(exercise: exercise)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .background(Color.black)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 21,
                                style: .continuous
                            )
                        )

                    Button {
                        withAnimation(.snappy) {
                            showDemo = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(
                                .white.opacity(0.92),
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
            }

            if
                exercise.gifURL != nil,
                !showDemo
            {
                Button {
                    withAnimation(.snappy) {
                        showDemo = true
                    }
                } label: {
                    Label(
                        "Show exercise demo",
                        systemImage:
                            "play.rectangle.fill"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(purple)
                }
                .buttonStyle(.plain)
            }

            if
                let note = exercise.note,
                !note.isEmpty
            {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .opacity(0.55)

            HStack {
                Text("SETS")
                    .font(.caption2.weight(.black))
                    .tracking(1.6)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(sets.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if sets.isEmpty {
                Text("No sets yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 5)
            } else {
                VStack(spacing: 9) {
                    ForEach(
                        sets,
                        id: \.uuid
                    ) { set in
                        let binding =
                            Binding<Bool>(
                                get: {
                                    expandedSetID ==
                                        set.uuid
                                },
                                set: {
                                    expandedSetID =
                                        $0
                                        ? set.uuid
                                        : nil
                                }
                            )

                        SetRowView(
                            isEditing: binding,
                            set: set
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 27,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 27,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.04),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.055),
            radius: 14,
            y: 7
        )
        .sheet(
            isPresented: $showMediaEditor
        ) {
            NavigationStack {
                Form {
                    ExerciseMediaEditorWithTrim(
                        exercise: exercise
                    )
                }
                .navigationTitle("Exercise Media")
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    ToolbarItem(
                        placement:
                            .confirmationAction
                    ) {
                        Button("Done") {
                            showMediaEditor = false
                        }
                    }
                }
            }
            .presentationDetents([
                .medium,
                .large
            ])
        }
    }

    private var exerciseTopRow: some View {
        HStack(
            alignment: .top,
            spacing: 13
        ) {
            Text(
                String(
                    format: "%02d",
                    number
                )
            )
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 39, height: 39)
            .background(
                purple,
                in: RoundedRectangle(
                    cornerRadius: 13,
                    style: .continuous
                )
            )

            VStack(
                alignment: .leading,
                spacing: 7
            ) {
                Text(
                    exercise.name.isEmpty
                        ? "Exercise"
                        : exercise.name
                )
                .font(
                    .system(
                        size: 20,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.black)
                .lineLimit(2)

                HStack(spacing: 6) {
                    if
                        let equipment =
                            exercise.equipment,
                        !equipment.isEmpty
                    {
                        metaChip(
                            equipment,
                            icon: "dumbbell.fill"
                        )
                    }

                    if exercise.isWarmup {
                        metaChip(
                            "Warm-up",
                            icon: "flame.fill"
                        )
                    }

                    if exercise.gifURL != nil {
                        metaChip(
                            "Demo",
                            icon:
                                "play.rectangle.fill"
                        )
                    }
                }
            }

            Spacer()

            Menu {
                Button {
                    showMediaEditor = true
                } label: {
                    Label(
                        "Exercise Media",
                        systemImage:
                            "photo.on.rectangle"
                    )
                }

                if let videoURL = exercise.videoURL {
                    Link(destination: videoURL) {
                        Label(
                            "Open Video",
                            systemImage:
                                "play.rectangle"
                        )
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 38, height: 38)
                    .background(
                        Color(
                            red: 0.95,
                            green: 0.95,
                            blue: 0.95
                        ),
                        in: Circle()
                    )
            }
        }
    }

    private func metaChip(
        _ title: String,
        icon: String
    ) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Color(
                    red: 0.95,
                    green: 0.95,
                    blue: 0.95
                ),
                in: Capsule()
            )
    }
}
