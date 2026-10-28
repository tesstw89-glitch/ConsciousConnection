import SwiftUI
import SwiftData

// MARK: - Figma design tokens

enum StrengthLabFigmaTheme {
    static let ink = Color(
        red: 4.0 / 255.0,
        green: 4.0 / 255.0,
        blue: 21.0 / 255.0
    )

    static let coral = Color(
        red: 255.0 / 255.0,
        green: 96.0 / 255.0,
        blue: 121.0 / 255.0
    )

    static let coralLight = Color(
        red: 255.0 / 255.0,
        green: 128.0 / 255.0,
        blue: 147.0 / 255.0
    )

    static let blush = Color(
        red: 1.0,
        green: 0.925,
        blue: 0.935
    )

    static let paleBlush = Color(
        red: 1.0,
        green: 0.965,
        blue: 0.968
    )

    static let muted = Color(
        red: 127.0 / 255.0,
        green: 127.0 / 255.0,
        blue: 127.0 / 255.0
    )

    static let line = Color.black.opacity(0.10)

    static let coralGradient = LinearGradient(
        colors: [
            coral,
            coralLight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func regular(
        _ size: CGFloat
    ) -> Font {
        .custom(
            "DMSans-Regular",
            size: size
        )
    }

    static func medium(
        _ size: CGFloat
    ) -> Font {
        .custom(
            "DMSans-Medium",
            size: size
        )
    }

    static func bold(
        _ size: CGFloat
    ) -> Font {
        .custom(
            "DMSans-Bold",
            size: size
        )
    }
}


// MARK: - Shared Figma controls

struct FigmaNavIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(
                .system(
                    size: 17,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.ink
            )
            .frame(
                width: 56,
                height: 56
            )
            .background(
                Color.white,
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        Color.black.opacity(0.10),
                        lineWidth: 1.5
                    )
            }
    }
}


struct StrengthLabContourBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                StrengthLabFigmaTheme.blush

                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .stroke(
                            StrengthLabFigmaTheme
                                .coral
                                .opacity(0.14),
                            lineWidth: 1.3
                        )
                        .frame(
                            width:
                                360 +
                                CGFloat(index) * 105,
                            height:
                                360 +
                                CGFloat(index) * 105
                        )
                        .offset(
                            x:
                                -230 -
                                CGFloat(index) * 18,
                            y:
                                165 +
                                CGFloat(index) * 5
                        )
                }

                Circle()
                    .stroke(
                        Color.white.opacity(0.95),
                        lineWidth: 4
                    )
                    .frame(
                        width: 215,
                        height: 215
                    )
                    .offset(
                        x: proxy.size.width * 0.48,
                        y: -proxy.size.height * 0.45
                    )

                Circle()
                    .stroke(
                        Color.white.opacity(0.95),
                        lineWidth: 4
                    )
                    .frame(
                        width: 116,
                        height: 116
                    )
                    .offset(
                        x: proxy.size.width * 0.50,
                        y: -proxy.size.height * 0.45
                    )
            }
        }
        .clipped()
    }
}


// MARK: - Workout Library

struct WorkoutLibraryHomeView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \WorkoutTemplate.updatedAt,
        order: .reverse
    )
    private var workouts: [WorkoutTemplate]

    @Query
    private var schedules: [WorkoutSchedule]

    @AppStorage(
        "strengthlab.didMigrateDayRoutinesToWorkoutTemplatesV1"
    )
    private var didMigrateLegacyRoutines = false

    @State
    private var selectedWorkout: WorkoutTemplate?

    @State
    private var editingWorkout: WorkoutTemplate?

    @State
    private var calendarWorkout: WorkoutTemplate?

    @State
    private var activeWorkout: WorkoutTemplate?

    @State
    private var showingCalendar = false

    @State private var showingCombineWorkouts = false
    @State private var pendingCombinedWorkout: WorkoutTemplate?

    @State private var programStore = StrengthLabProgramStore.shared
    @State private var showingPrograms = false
    @State private var newProgramName = ""
    @State private var renameProgramName = ""
    @State private var programErrorMessage = ""
    @State private var showingProgramError = false

    private var activeWorkouts: [WorkoutTemplate] {
        guard programStore.activeProgram != nil else { return workouts }
        return workouts.filter { programStore.containsWorkout($0.uuid) }
    }

    private var unattachedWorkouts: [WorkoutTemplate] {
        workouts.filter { !programStore.containsWorkout($0.uuid) }
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    header

                    HStack {
                        Text("PROGRAM · \(programStore.activeProgram?.name ?? "Dumbbell Strength")")
                            .font(StrengthLabFigmaTheme.bold(11))
                            .foregroundStyle(StrengthLabFigmaTheme.coral)
                        Spacer()
                    }
                    .padding(.top, 12)

                    YogaPoseDayBanner()
                        .padding(.top, 18)

                    heroBanner
                        .padding(.top, 20)

                    workoutsTitle
                        .padding(.top, 38)

                    if activeWorkouts.isEmpty {
                        emptyWorkoutRow
                            .padding(.top, 26)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(
                                Array(
                                    activeWorkouts.enumerated()
                                ),
                                id: \.element.uuid
                            ) {
                                index,
                                workout in

                                workoutRow(
                                    workout,
                                    index: index
                                )
                            }
                        }
                        .padding(.top, 26)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .tint(
            StrengthLabFigmaTheme.coral
        )
        .toolbarBackground(
            Color.white,
            for: .tabBar
        )
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
        .task {
            migrateLegacyRoutinesIfNeeded()
            do {
                let currentWorkouts = try modelContext.fetch(FetchDescriptor<WorkoutTemplate>())
                let currentSchedules = try modelContext.fetch(FetchDescriptor<WorkoutSchedule>())
                try programStore.prepare(workouts: currentWorkouts, schedules: currentSchedules)
            } catch {
                showProgramError(error)
            }
        }
        .sheet(
            item: $editingWorkout
        ) { workout in
            WorkoutTemplateEditorView(
                workout: workout
            )
        }
        .fullScreenCover(
            item: $selectedWorkout
        ) { workout in
            WorkoutDetailView(
                workout: workout
            )
        }
        .fullScreenCover(
            item: $calendarWorkout
        ) { workout in
            WorkoutScheduleSheet(
                workout: workout
            )
        }
        .fullScreenCover(
            item: $activeWorkout
        ) { workout in
            WorkoutRunView(
                workout: workout
            )
        }
        .fullScreenCover(
            isPresented: $showingCalendar
        ) {
            WorkoutScheduleSheet()
        }
        .sheet(isPresented: $showingPrograms) {
            programsSheet
        }
        .sheet(isPresented: $showingCombineWorkouts, onDismiss: {
            // Open the new workout for editing after the picker closes.
            if let pendingCombinedWorkout {
                editingWorkout = pendingCombinedWorkout
                self.pendingCombinedWorkout = nil
            }
        }) {
            WorkoutCombineSheet(workouts: workouts) { first, second, name in
                combineWorkouts(first, second, named: name)
            }
        }
        .alert("Programme Error", isPresented: $showingProgramError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(programErrorMessage)
        }
    }

    // MARK: Programmes

    private var programsSheet: some View {
        NavigationStack {
            Form {
                Section("Your Programs") {
                    ForEach(programStore.programs) { program in
                        Button {
                            do {
                                try programStore.activate(program.id)
                                renameProgramName = program.name
                            } catch { showProgramError(error) }
                        } label: {
                            HStack {
                                Text(program.name)
                                Spacer()
                                Text("\(program.workoutIDs.count) workouts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if program.id == programStore.activeProgram?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(StrengthLabFigmaTheme.coral)
                                }
                            }
                        }
                    }
                }

                Section("Create New Program") {
                    TextField("Program name", text: $newProgramName)
                    Button("Create and Switch") {
                        do {
                            try programStore.create(name: newProgramName)
                            newProgramName = ""
                            renameProgramName = programStore.activeProgram?.name ?? ""
                        } catch { showProgramError(error) }
                    }
                }

                if let active = programStore.activeProgram {
                    Section("Rename Active Program") {
                        TextField("Program name", text: $renameProgramName)
                        Button("Save Name") {
                            do { try programStore.renameActive(renameProgramName) }
                            catch { showProgramError(error) }
                        }
                    }

                    if !unattachedWorkouts.isEmpty {
                        Section("Add Existing Workout to \(active.name)") {
                            ForEach(unattachedWorkouts) { workout in
                                Button {
                                    do { try programStore.addWorkout(workout.uuid) }
                                    catch { showProgramError(error) }
                                } label: {
                                    Label(workout.name, systemImage: "plus.circle")
                                }
                            }
                        }
                    }
                }

                Section {
                    Text("Exercises and imported MP4/GIF media remain available across every programme. Removing a workout from a programme never deletes it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingPrograms = false }
                }
            }
            .onAppear {
                renameProgramName = programStore.activeProgram?.name ?? ""
            }
            .onChange(of: programStore.activeID) { _, _ in
                renameProgramName = programStore.activeProgram?.name ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func showProgramError(_ error: Error) {
        programErrorMessage = error.localizedDescription
        showingProgramError = true
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                showingCalendar = true
            } label: {
                FigmaNavIcon(
                    systemName: "calendar"
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Workouts")
                .font(
                    StrengthLabFigmaTheme
                        .bold(18)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Spacer()

            Menu {
                Button {
                    createWorkout()
                } label: {
                    Label(
                        "New Workout",
                        systemImage: "plus"
                    )
                }

                if workouts.count >= 2 {
                    Button {
                        showingCombineWorkouts = true
                    } label: {
                        Label(
                            "Combine Workouts",
                            systemImage: "square.on.square"
                        )
                    }
                }

                Button {
                    showingCalendar = true
                } label: {
                    Label(
                        "Calendar",
                        systemImage: "calendar"
                    )
                }

                Menu {
                    ForEach(programStore.programs) { program in
                        Button {
                            do { try programStore.activate(program.id) }
                            catch { showProgramError(error) }
                        } label: {
                            Label(
                                program.name,
                                systemImage: program.id == programStore.activeProgram?.id
                                    ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                } label: {
                    Label("Switch Program", systemImage: "arrow.left.arrow.right")
                }

                Button {
                    newProgramName = ""
                    showingPrograms = true
                } label: {
                    Label("New Program", systemImage: "folder.badge.plus")
                }

                Button {
                    showingPrograms = true
                } label: {
                    Label("Manage Programs", systemImage: "square.stack")
                }
            } label: {
                FigmaNavIcon(
                    systemName:
                        "slider.horizontal.3"
                )
            }
        }
        .frame(height: 56)
    }

    // MARK: Banner

    private var heroBanner: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            ZStack {
                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .coralGradient
                    )
                    .frame(
                        width: 56,
                        height: 56
                    )

                Image(
                    systemName:
                        "dumbbell.fill"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
            }

            Text("Workouts, your way")
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .padding(.top, 18)

            Text(
                "Build a workout once. " +
                "Schedule it only when you want to."
            )
            .font(
                StrengthLabFigmaTheme
                    .medium(16)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.muted
            )
            .lineSpacing(5)
            .padding(.top, 8)

            Spacer(minLength: 18)

            Button {
                createWorkout()
            } label: {
                Text("New Workout")
                    .font(
                        StrengthLabFigmaTheme
                            .medium(16)
                    )
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 64)
                    .background(
                        StrengthLabFigmaTheme
                            .coralGradient,
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)

            if workouts.count >= 2 {
                Button {
                    showingCombineWorkouts = true
                } label: {
                    Label("Combine Workouts", systemImage: "square.on.square")
                        .font(StrengthLabFigmaTheme.medium(16))
                        .foregroundStyle(StrengthLabFigmaTheme.coral)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .padding(24)
        .frame(
            maxWidth: .infinity,
            minHeight: 288,
            alignment: .topLeading
        )
        .background(
            StrengthLabFigmaTheme
                .coral
                .opacity(0.10),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }

    // MARK: Workout list

    private var workoutsTitle: some View {
        HStack {
            Text("Your Workouts")
                .font(
                    StrengthLabFigmaTheme
                        .medium(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

            Spacer()

            Text("\(activeWorkouts.count)")
                .font(
                    StrengthLabFigmaTheme
                        .bold(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .coral
                )
        }
    }

    private func workoutRow(
        _ workout: WorkoutTemplate,
        index: Int
    ) -> some View {
        Button {
            selectedWorkout = workout
        } label: {
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            StrengthLabFigmaTheme
                                .blush
                        )
                        .frame(
                            width: 48,
                            height: 48
                        )

                    Image(
                        systemName:
                            workoutIcon(
                                at: index
                            )
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                }

                Text(workout.name)
                    .font(
                        StrengthLabFigmaTheme
                            .medium(16)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .lineLimit(1)

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
            }
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedWorkout =
                    workout
            } label: {
                Label(
                    "Open",
                    systemImage:
                        "chevron.right"
                )
            }

            Button {
                editingWorkout =
                    workout
            } label: {
                Label(
                    "Edit",
                    systemImage:
                        "pencil"
                )
            }

            Button {
                calendarWorkout =
                    workout
            } label: {
                Label(
                    "Schedule",
                    systemImage:
                        "calendar.badge.plus"
                )
            }

            Button {
                duplicate(workout)
            } label: {
                Label(
                    "Duplicate",
                    systemImage:
                        "square.on.square"
                )
            }

            Divider()

            Button(
                role: .destructive
            ) {
                removeFromProgram(workout)
            } label: {
                Label(
                    "Remove from Program",
                    systemImage: "minus.circle"
                )
            }
        }
    }

    private var emptyWorkoutRow: some View {
        Button {
            createWorkout()
        } label: {
            HStack(spacing: 24) {
                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .blush
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .overlay {
                        Image(
                            systemName: "plus"
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )
                    }

                Text(
                    "Create your first workout"
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private func workoutIcon(
        at index: Int
    ) -> String {
        let icons = [
            "dumbbell.fill",
            "figure.strengthtraining.traditional",
            "figure.core.training",
            "figure.cross.training"
        ]

        return icons[
            index % icons.count
        ]
    }

    // MARK: Actions

    private func createWorkout() {
        let workout = WorkoutTemplate(name: "New Workout")
        modelContext.insert(workout)
        do {
            try modelContext.save()
            try programStore.addWorkout(workout.uuid)
            editingWorkout = workout
        } catch {
            showProgramError(error)
        }
    }

    private func combineWorkouts(
        _ first: WorkoutTemplate,
        _ second: WorkoutTemplate,
        named name: String
    ) {
        guard first.uuid != second.uuid else { return }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        // Copy models, never move them: each source retains its exercises,
        // histories, schedules and programme membership.
        let combined = WorkoutTemplate(name: title)
        modelContext.insert(combined)

        let firstExercises = cloneExercises(first.exercises ?? [])
        let secondExercises = cloneExercises(second.exercises ?? [])

        // Preserve supersets within each source, but do not accidentally
        // link copied exercises to their originals or to the other source.
        remapClonedSupersets(firstExercises)
        remapClonedSupersets(secondExercises)

        let allExercises = firstExercises + secondExercises
        for (index, exercise) in allExercises.enumerated() {
            exercise.orderIndex = index
        }
        combined.exercises = allExercises
        combined.updatedAt = Date()

        do {
            try modelContext.save()
            do {
                try programStore.addWorkout(combined.uuid)
            } catch {
                // Avoid saving an unattached workout when the programme
                // index cannot be updated.
                modelContext.delete(combined)
                try? modelContext.save()
                throw error
            }
            pendingCombinedWorkout = combined
            showingCombineWorkouts = false
        } catch {
            showProgramError(error)
        }
    }

    private func remapClonedSupersets(_ exercises: [SetDeckExercise]) {
        var groups: [UUID: UUID] = [:]
        for exercise in exercises {
            guard let oldID = exercise.supersetGroupID else { continue }
            if let newID = groups[oldID] {
                exercise.supersetGroupID = newID
            } else {
                let newID = UUID()
                groups[oldID] = newID
                exercise.supersetGroupID = newID
            }
        }
    }

    private func removeFromProgram(_ workout: WorkoutTemplate) {
        // This only removes a UUID from programme membership.
        // Never delete the workout, exercises, imported MP4, or GIF files.
        do { try programStore.removeWorkout(workout.uuid) }
        catch { showProgramError(error) }
    }

    private func duplicate(_ source: WorkoutTemplate) {
        let copy = WorkoutTemplate(name: "\(source.name) Copy")
        modelContext.insert(copy)
        copy.exercises = cloneExercises(source.exercises ?? [])
        copy.updatedAt = Date()
        do {
            try modelContext.save()
            try programStore.addWorkout(copy.uuid)
        } catch {
            showProgramError(error)
        }
    }

    // MARK: Legacy migration

    private func migrateLegacyRoutinesIfNeeded() {
        guard
            !didMigrateLegacyRoutines
        else {
            return
        }

        if !workouts.isEmpty {
            didMigrateLegacyRoutines =
                true
            return
        }

        let descriptor =
            FetchDescriptor<SetDeckRoutine>()

        guard
            let routines =
                try? modelContext.fetch(
                    descriptor
                )
        else {
            didMigrateLegacyRoutines =
                true
            return
        }

        let populated =
            routines.filter {
                !($0.exercises ?? [])
                    .isEmpty
            }

        for routine in populated {
            let name =
                weekdayName(
                    index: routine.day
                )

            let workout =
                WorkoutTemplate(
                    name:
                        "\(name) Workout"
                )

            modelContext.insert(
                workout
            )

            let sourceExercises =
                (routine.exercises ?? [])
                    .sorted {
                        $0.orderIndex <
                            $1.orderIndex
                    }

            workout.exercises =
                cloneExercises(
                    sourceExercises
                )
        }

        try? modelContext.save()

        didMigrateLegacyRoutines =
            true
    }

    private func weekdayName(
        index: Int
    ) -> String {
        let symbols =
            Calendar.current
                .weekdaySymbols

        guard
            symbols.indices
                .contains(index)
        else {
            return "Imported"
        }

        return symbols[index]
    }

    private func cloneExercises(
        _ exercises:
            [SetDeckExercise]
    ) -> [SetDeckExercise] {
        exercises
            .sorted {
                $0.orderIndex <
                    $1.orderIndex
            }
            .map { oldExercise in
                let exercise =
                    SetDeckExercise(
                        name:
                            oldExercise.name,
                        note:
                            oldExercise.note,
                        videoURL:
                            oldExercise.videoURL,
                        gifURL:
                            oldExercise.gifURL,
                        isWarmup:
                            oldExercise.isWarmup,
                        muscleGroups:
                            oldExercise
                                .muscleGroups,
                        equipment:
                            oldExercise
                                .equipment,
                        orderIndex:
                            oldExercise
                                .orderIndex
                    )

                exercise.supersetGroupID = oldExercise.supersetGroupID
                exercise.importedVideoURL = oldExercise.importedVideoURL
                exercise.gifSourceURL = oldExercise.gifSourceURL
                exercise.gifEditedFPS = oldExercise.gifEditedFPS
                exercise.gifEditedMaxWidth = oldExercise.gifEditedMaxWidth
                exercise.gifTrimStart = oldExercise.gifTrimStart
                exercise.gifTrimEnd = oldExercise.gifTrimEnd
                exercise.videoTrimStart = oldExercise.videoTrimStart
                exercise.videoTrimEnd = oldExercise.videoTrimEnd

                modelContext.insert(
                    exercise
                )

                let sourceSets =
                    (oldExercise.sets ?? [])
                        .sorted {
                            $0.orderIndex <
                                $1.orderIndex
                        }

                let copiedSets =
                    sourceSets.map {
                        oldSet in

                        let set =
                            SetDeckSet(
                                setType:
                                    oldSet
                                        .setType,
                                targetReps:
                                    oldSet
                                        .targetReps,
                                weight:
                                    oldSet
                                        .weight,
                                targetDuration:
                                    oldSet
                                        .targetDuration,
                                setDescription:
                                    oldSet
                                        .setDescription,
                                rpe:
                                    oldSet.rpe,
                                orderIndex:
                                    oldSet
                                        .orderIndex
                            )

                        set.restTimeInSeconds = oldSet.restTimeInSeconds
                        set.exercise = exercise

                        modelContext.insert(
                            set
                        )

                        return set
                    }

                exercise.sets =
                    copiedSets

                return exercise
            }
    }
}

// MARK: - Combine Workouts (kept in this compiled file for Xcode/SPM)

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
