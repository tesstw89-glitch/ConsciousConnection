//
//  EditRoutineView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/23/25.
//

import SwiftUI
import SwiftData
import TipKit
#if canImport(UIKit)
import UIKit
#endif

struct EditRoutineView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ViewModel()
    @State private var showingExerciseLibrary = false
    @State private var mediaExercise: SetDeckExercise?

    @FocusState private var focusedExerciseID: UUID?
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    private let fitnessPurple = Color(
        red: 0.40,
        green: 0.22,
        blue: 0.94
    )

    private let fitnessLime = Color(
        red: 0.78,
        green: 0.94,
        blue: 0.28
    )

    private let fitnessBackground = Color(
        red: 0.965,
        green: 0.958,
        blue: 0.945
    )

    // TipKit
    private let addExerciseTip = AddExerciseTip()
    private let addSetTip = AddSetTip()

    var body: some View {
        let currentRoutine =
            viewModel.currentRoutine(
                using: exerciseManager
            )

        let exercises =
            viewModel.exercises(
                using: exerciseManager
            )
            .sorted {
                $0.orderIndex < $1.orderIndex
            }

        let _ = exerciseManager.changeStamp

        let setsForExercise: [UUID: [SetDeckSet]] =
            Dictionary(
                uniqueKeysWithValues:
                    exercises.map { exercise in
                        (
                            exercise.uuid,
                            exerciseManager
                                .sets(for: exercise)
                                .sorted {
                                    $0.orderIndex <
                                        $1.orderIndex
                                }
                        )
                    }
            )

        ZStack {
            fitnessBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Day selector

                DayPickerView(
                    selectedDay:
                        $viewModel.selectedDay
                )
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // MARK: Routine summary

                HStack(spacing: 14) {
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text("BUILD YOUR SESSION")
                            .font(
                                .caption2.weight(.black)
                            )
                            .tracking(1.7)
                            .foregroundStyle(.secondary)

                        Text(
                            "\(exercises.count) " +
                            (
                                exercises.count == 1
                                ? "exercise"
                                : "exercises"
                            )
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                    }

                    Spacer()

                    Image(
                        systemName:
                            "figure.strengthtraining.traditional"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.black)
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .background(
                        fitnessLime,
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                }
                .padding(16)
                .background(
                    Color.white,
                    in: RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 12,
                    y: 5
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                // MARK: Routine editor

                List {
                    if exercises.isEmpty {

                        Section {
                            VStack(spacing: 18) {
                                Image(
                                    systemName:
                                        "dumbbell.fill"
                                )
                                .font(
                                    .system(size: 34)
                                )
                                .foregroundStyle(
                                    fitnessPurple
                                )

                                VStack(spacing: 5) {
                                    Text(
                                        "No exercises yet"
                                    )
                                    .font(
                                        .title3.bold()
                                    )
                                    .foregroundStyle(
                                        .black
                                    )

                                    Text(
                                        "Build today's workout from your exercise library."
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                    .multilineTextAlignment(
                                        .center
                                    )
                                }

                                Button {
                                    addExerciseTip
                                        .invalidate(
                                            reason:
                                                .actionPerformed
                                        )

                                    showingExerciseLibrary =
                                        true

                                    Task {
                                        await TipEvents
                                            .firstExerciseAdded
                                            .donate()
                                    }
                                } label: {
                                    Label(
                                        "Add exercise",
                                        systemImage:
                                            "plus"
                                    )
                                    .font(
                                        .headline.weight(
                                            .bold
                                        )
                                    )
                                    .frame(
                                        maxWidth:
                                            .infinity
                                    )
                                    .padding(
                                        .vertical,
                                        14
                                    )
                                    .foregroundStyle(
                                        .white
                                    )
                                    .background(
                                        fitnessPurple,
                                        in:
                                            RoundedRectangle(
                                                cornerRadius:
                                                    18,
                                                style:
                                                    .continuous
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .popoverTip(
                                    addExerciseTip,
                                    arrowEdge: .top
                                )
                            }
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding(.vertical, 28)
                        }
                        .listRowInsets(
                            EdgeInsets(
                                top: 10,
                                leading: 16,
                                bottom: 10,
                                trailing: 16
                            )
                        )
                        .listRowBackground(
                            Color.clear
                        )
                        .listRowSeparator(.hidden)

                    } else {

                        ForEach(
                            exercises,
                            id: \.uuid
                        ) { exercise in

                            let isFirstExercise =
                                exercise.uuid ==
                                    exercises.first?.uuid

                            Section(
                                header:
                                    exerciseHeader(
                                        for: exercise,
                                        allExercises:
                                            exercises
                                    )
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 8,
                                            leading: 16,
                                            bottom: 6,
                                            trailing: 16
                                        )
                                    ),
                                footer:
                                    addSetFooter(
                                        for: exercise,
                                        isFirstExercise:
                                            isFirstExercise
                                    )
                            ) {
                                let sets =
                                    setsForExercise[
                                        exercise.uuid
                                    ] ?? []

                                ForEach(
                                    sets,
                                    id: \.uuid
                                ) { set in

                                    EditSetRowView(
                                        set: set,
                                        setCount:
                                            sets.count
                                    )
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 6,
                                            leading: 16,
                                            bottom: 6,
                                            trailing: 16
                                        )
                                    )
                                    .listRowSeparator(
                                        .hidden
                                    )
                                    .listRowBackground(
                                        Color.white
                                    )
                                }
                                .onDelete { offsets in
                                    DispatchQueue
                                        .main
                                        .async {
                                            withAnimation(
                                                .snappy
                                            ) {
                                                viewModel
                                                    .deleteSets(
                                                        at:
                                                            offsets,
                                                        from:
                                                            sets,
                                                        using:
                                                            exerciseManager
                                                    )
                                            }
                                        }
                                }
                                .onMove {
                                    indices,
                                    destination in

                                    viewModel.moveSets(
                                        from: indices,
                                        to: destination,
                                        in: sets,
                                        exercise:
                                            exercise,
                                        using:
                                            exerciseManager
                                    )
                                }
                            }
                        }
                        .onDelete { offsets in
                            focusedExerciseID = nil

                            DispatchQueue
                                .main
                                .async {
                                    withAnimation(
                                        .snappy
                                    ) {
                                        viewModel
                                            .deleteExercises(
                                                at:
                                                    offsets,
                                                from:
                                                    exercises,
                                                using:
                                                    exerciseManager
                                            )

                                        let remaining =
                                            viewModel
                                                .exercises(
                                                    using:
                                                        exerciseManager
                                                )
                                                .sorted {
                                                    $0.orderIndex <
                                                        $1.orderIndex
                                                }

                                        for (
                                            index,
                                            exercise
                                        ) in remaining
                                            .enumerated()
                                        {
                                            exerciseManager
                                                .updateExercise(
                                                    exercise
                                                ) {
                                                    $0.orderIndex =
                                                        index
                                                }
                                        }
                                    }
                                }
                        }
                        .onMove {
                            indices,
                            destination in

                            viewModel
                                .moveExercises(
                                    from: indices,
                                    to: destination,
                                    in: exercises,
                                    currentRoutine:
                                        currentRoutine,
                                    using:
                                        exerciseManager
                                )

                            let reordered =
                                viewModel
                                    .exercises(
                                        using:
                                            exerciseManager
                                    )
                                    .sorted {
                                        $0.orderIndex <
                                            $1.orderIndex
                                    }

                            for (
                                index,
                                exercise
                            ) in reordered
                                .enumerated()
                            {
                                exerciseManager
                                    .updateExercise(
                                        exercise
                                    ) {
                                        $0.orderIndex =
                                            index
                                    }
                            }
                        }

                        Section {
                            Button {
                                showingExerciseLibrary =
                                    true
                            } label: {
                                Label(
                                    "Add exercise",
                                    systemImage:
                                        "plus"
                                )
                                .font(
                                    .headline.weight(
                                        .bold
                                    )
                                )
                                .foregroundStyle(.white)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(.vertical, 14)
                                .background(
                                    fitnessPurple,
                                    in:
                                        RoundedRectangle(
                                            cornerRadius: 18,
                                            style:
                                                .continuous
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(
                            EdgeInsets(
                                top: 16,
                                leading: 16,
                                bottom: 30,
                                trailing: 16
                            )
                        )
                        .listRowBackground(
                            Color.clear
                        )
                        .listRowSeparator(.hidden)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                .background(Color.clear)
            }
        }
        .preferredColorScheme(.light)
        .tint(fitnessPurple)
        .onAppear {
            viewModel.resetToToday()

            Task {
                await TipEvents
                    .editRoutineOpened
                    .donate()
            }
        }
        .onChange(of: scenePhase) {
            _,
            newValue in

            if newValue == .active {
                viewModel.resetToToday()
            }
        }
        .animation(
            .snappy(duration: 0.3),
            value: viewModel.selectedDay
        )
        .sheet(
            isPresented:
                $showingExerciseLibrary
        ) {
            ExerciseLibraryPicker(
                onSelect: { item in
                    withAnimation(.snappy) {
                        viewModel.addExercise(
                            from: item,
                            using:
                                exerciseManager
                        )
                    }
                },
                onCreateCustom: {
                    withAnimation(.snappy) {
                        viewModel.addExercise(
                            named:
                                "New Exercise",
                            using:
                                exerciseManager
                        )
                    }
                }
            )
        }
        .sheet(
            isPresented: Binding(
                get: {
                    mediaExercise != nil
                },
                set: {
                    if !$0 {
                        mediaExercise = nil
                    }
                }
            )
        ) {
            if let exercise =
                mediaExercise
            {
                NavigationStack {
                    Form {
                        ExerciseMediaEditorWithTrim(
                            exercise:
                                exercise
                        )
                    }
                    .navigationTitle(
                        "Exercise Media"
                    )
                    .navigationBarTitleDisplayMode(
                        .inline
                    )
                    .toolbar {
                        ToolbarItem(
                            placement:
                                .confirmationAction
                        ) {
                            Button("Done") {
                                mediaExercise =
                                    nil
                            }
                        }
                    }
                }
                .preferredColorScheme(.light)
                .presentationDetents([
                    .medium,
                    .large
                ])
            }
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button("Save") {
                    focusedExerciseID = nil
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(
                    fitnessPurple
                )
            }
        }
    }

    @ViewBuilder
    private func addSetFooter(
        for exercise: SetDeckExercise,
        isFirstExercise: Bool
    ) -> some View {
        let button = Button {
            addSetTip.invalidate(
                reason: .actionPerformed
            )

            withAnimation(.snappy) {
                viewModel.addSet(
                    to: exercise,
                    using: exerciseManager
                )
            }
        } label: {
            Label(
                "Add set",
                systemImage: "plus"
            )
            .font(
                .subheadline.weight(.bold)
            )
            .foregroundStyle(
                fitnessPurple
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                fitnessPurple.opacity(0.10),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Add set to \(exercise.name)"
        )
        .accessibilityHint(
            "Creates a new set for this exercise"
        )
        .frame(
            maxWidth: .infinity,
            alignment: .trailing
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        if isFirstExercise {
            button.popoverTip(
                addSetTip,
                arrowEdge: .bottom
            )
        } else {
            button
        }
    }

    @ViewBuilder
    private func exerciseHeader(
        for exercise: SetDeckExercise,
        allExercises: [SetDeckExercise]
    ) -> some View {
        HStack(spacing: 12) {
            TextField("Exercise Name", text: Binding(
                get: { exercise.name },
                set: { newValue in
                    exerciseManager.updateExercise(exercise) { $0.name = newValue }
                }
            ))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .focused($focusedExerciseID, equals: exercise.uuid)
            .accessibilityLabel("Exercise name")
            .accessibilityValue(exercise.name)
            .accessibilityHint("Double tap to edit the exercise name")

            // When focused, show a checkmark button to clear focus
            if focusedExerciseID == exercise.uuid {
                Button {
                    focusedExerciseID = nil
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.greenStart)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Done editing")
                .accessibilityHint("Confirms the exercise name change")
            }

            Spacer()

            if focusedExerciseID != exercise.uuid {
                Button {
                    mediaExercise = exercise
                } label: {
                    Image(systemName: exercise.gifURL == nil
                          ? "photo.badge.plus"
                          : "photo.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            exercise.gifURL == nil
                                ? Color.secondary
                                : Color.blue
                        )
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(
                                    exercise.gifURL == nil
                                        ? Color.primary.opacity(0.06)
                                        : Color.blue.opacity(0.14)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    exercise.gifURL == nil
                        ? "Add exercise media"
                        : "Edit exercise media"
                )

                Menu {
                    if exercise.supersetGroupID != nil {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                exerciseManager.removeFromSuperset(exercise)
                            }
                        } label: {
                            Label("Remove from Superset", systemImage: "link.badge.minus")
                        }

                        Divider()
                    }

                    ForEach(
                        allExercises.filter { other in
                            other.uuid != exercise.uuid &&
                            (
                                exercise.supersetGroupID == nil ||
                                other.supersetGroupID != exercise.supersetGroupID
                            )
                        },
                        id: \.uuid
                    ) { other in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                exerciseManager.linkAsSuperset(exercise, other)
                            }
                        } label: {
                            Label(
                                "Superset with \(other.name.isEmpty ? "Exercise" : other.name)",
                                systemImage: "link"
                            )
                        }
                    }
                } label: {
                    Image(
                        systemName: exercise.supersetGroupID == nil
                            ? "link.badge.plus"
                            : "link.circle.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        exercise.supersetGroupID == nil
                            ? Color.secondary
                            : Color.purple
                    )
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(
                                exercise.supersetGroupID == nil
                                    ? Color.primary.opacity(0.06)
                                    : Color.purple.opacity(0.14)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    exercise.supersetGroupID == nil
                        ? "Create superset"
                        : "Edit superset"
                )

                HStack(spacing: 8) {
                    Text("Warmup?")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)

                    Toggle("", isOn: Binding(
                        get: { exercise.isWarmup },
                        set: { newValue in
                            exerciseManager.updateExercise(exercise) { $0.isWarmup = newValue }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color.orangeStart))
                    .accessibilityLabel("Warmup exercise")
                    .accessibilityValue(exercise.isWarmup ? "On" : "Off")
                    .accessibilityHint("Mark this exercise as a warmup")
                }

                Button {
                    if focusedExerciseID == exercise.uuid {
                        focusedExerciseID = nil
                    }
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            exerciseManager.deleteExercise(exercise)
                        }
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .hoverEffectIfAvailable(.highlight)
                .accessibilityLabel("Delete \(exercise.name)")
                .accessibilityHint("Removes this exercise and all its sets")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: focusedExerciseID)
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)

    // Seed routines and exercises for preview
    if (try? context.fetch(FetchDescriptor<SetDeckRoutine>()))?.isEmpty ?? true {
        for day in 0..<3 {
            let routine = SetDeckRoutine.sample(day: day)
            context.insert(routine)
            for _ in 0..<2 {
                let ex = SetDeckExercise.sample(setCount: 3)
                ex.routine = routine
                context.insert(ex)
                for set in ex.sets ?? [] {
                    context.insert(set)
                }
            }
        }
        try? context.save()
    }

    return NavigationStack {
        EditRoutineView()
            .environment(exerciseManager)
            .preferredColorScheme(.dark)
            .onAppear {
                // Add one new exercise to the current day's routine when preview appears
                let calendar = Calendar.current
                let todayIndex = (calendar.component(.weekday, from: Date()) - 1 + 7) % 7
                // Check if there is already an exercise with this sentinel name to avoid duplicates per preview run
                let existing = exerciseManager.exercises(forDay: todayIndex).first { $0.name == "Preview Added Exercise" }
                if existing == nil {
                    _ = exerciseManager.addExercise(named: "Preview Added Exercise", toDay: todayIndex)
                }
            }
    }
}

