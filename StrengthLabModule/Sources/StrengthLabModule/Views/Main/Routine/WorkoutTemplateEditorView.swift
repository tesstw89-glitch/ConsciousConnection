import SwiftUI
import SwiftData

struct WorkoutTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var workout: WorkoutTemplate

    @State private var showingExerciseLibrary = false
    @State private var editingExercise: SetDeckExercise?

    @State private var replacementTarget: SetDeckExercise?
    @State private var appReplacementRequest: ReplacementAppRequest?
    @State private var customReplacementDraft: SetDeckExercise?

    private let purple = Color(
        red: 0.40,
        green: 0.22,
        blue: 0.94
    )

    private let lime = Color(
        red: 0.78,
        green: 0.94,
        blue: 0.28
    )

    private var exercises: [SetDeckExercise] {
        (workout.exercises ?? [])
            .sorted {
                $0.orderIndex < $1.orderIndex
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(
                    red: 0.965,
                    green: 0.958,
                    blue: 0.945
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        nameCard

                        ForEach(
                            exercises,
                            id: \.uuid
                        ) { exercise in
                            exerciseCard(exercise)
                        }

                        Button {
                            showingExerciseLibrary = true
                        } label: {
                            Label(
                                "Add exercise",
                                systemImage: "plus"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                lime,
                                in: RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Done") {
                        workout.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(purple)
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(
            isPresented: $showingExerciseLibrary
        ) {
            ExerciseLibraryPicker(
                onSelect: { item in
                    addExercise(item)
                },
                onCreateCustom: {
                    addCustomExercise()
                }
            )
        }
        .sheet(
            isPresented: Binding(
                get: {
                    editingExercise != nil
                },
                set: {
                    if !$0 {
                        editingExercise = nil
                    }
                }
            )
        ) {
            if let exercise =
                editingExercise
            {
                WorkoutTemplateExerciseEditor(
                    exercise: exercise
                )
            }
        }
        .sheet(item: $appReplacementRequest) { request in
            ReplacementAppExercisePicker(
                originalName: request.target.name
            ) { definition in
                replaceWithAppExercise(
                    definition,
                    in: request.target
                )
                appReplacementRequest = nil
            }
        }
        .sheet(
            isPresented: Binding(
                get: { customReplacementDraft != nil },
                set: { if !$0 { customReplacementDraft = nil; replacementTarget = nil } }
            )
        ) {
            if let draft = customReplacementDraft,
               let target = replacementTarget {
                WorkoutTemplateExerciseEditor(
                    exercise: draft,
                    isReplacementDraft: true,
                    onSave: {
                        replaceWithCustomExercise(draft, in: target)
                        customReplacementDraft = nil
                        replacementTarget = nil
                    },
                    onCancel: {
                        customReplacementDraft = nil
                        replacementTarget = nil
                    }
                )
            }
        }
    }

    private var nameCard: some View {
        VStack(
            alignment: .leading,
            spacing: 9
        ) {
            Text("WORKOUT NAME")
                .font(.caption2.weight(.black))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            TextField(
                "Workout name",
                text: $workout.name
            )
            .font(
                .system(
                    size: 27,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(.black)
            .onChange(of: workout.name) {
                workout.updatedAt = Date()
            }
        }
        .padding(18)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }

    private func exerciseCard(
        _ exercise: SetDeckExercise
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 13
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(exercise.name)
                        .font(
                            .system(
                                size: 20,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)

                    HStack(spacing: 7) {
                        if
                            let equipment =
                                exercise.equipment,
                            !equipment.isEmpty
                        {
                            Text(equipment)
                        }

                        Text(
                            "\(exercise.sets?.count ?? 0) sets"
                        )

                        if exercise.supersetGroupID != nil {
                            Text("SUPERSET")
                                .foregroundStyle(purple)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        editingExercise = exercise
                    } label: {
                        Label(
                            "Edit Exercise",
                            systemImage: "pencil"
                        )
                    }

                    Menu {
                        Button {
                            appReplacementRequest = ReplacementAppRequest(
                                target: exercise
                            )
                        } label: {
                            Label("App Exercise", systemImage: "square.grid.2x2")
                        }

                        Button {
                            beginCustomReplacement(for: exercise)
                        } label: {
                            Label("Custom Exercise", systemImage: "plus.square")
                        }
                    } label: {
                        Label("Replace Exercise", systemImage: "arrow.left.arrow.right")
                    }

                    if exercises.count > 1 {
                        Menu("Superset with") {
                            ForEach(
                                exercises.filter {
                                    $0.uuid !=
                                        exercise.uuid
                                },
                                id: \.uuid
                            ) { other in
                                Button(other.name) {
                                    linkSuperset(
                                        exercise,
                                        with: other
                                    )
                                }
                            }
                        }
                    }

                    if exercise.supersetGroupID != nil {
                        Button {
                            removeFromSuperset(
                                exercise
                            )
                        } label: {
                            Label(
                                "Remove from Superset",
                                systemImage:
                                    "link.badge.minus"
                            )
                        }
                    }

                    Divider()

                    Button(
                        role: .destructive
                    ) {
                        deleteExercise(exercise)
                    } label: {
                        Label(
                            "Delete Exercise",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(
                            Color(
                                red: 0.94,
                                green: 0.94,
                                blue: 0.94
                            ),
                            in: Circle()
                        )
                }
            }

            if exercise.supersetGroupID != nil {
                Rectangle()
                    .fill(lime)
                    .frame(height: 4)
                    .clipShape(Capsule())
            }

            Button {
                editingExercise = exercise
            } label: {
                HStack {
                    Text("Edit sets & media")
                        .font(
                            .subheadline.weight(.bold)
                        )

                    Spacer()

                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(purple)
            }
            .buttonStyle(.plain)
        }
        .padding(17)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
    }

    private func addExercise(
        _ item: ExerciseCatalogItem
    ) {
        let exercise =
            SetDeckExercise(
                name: item.name,
                gifURL: item.gifURL,
                equipment: item.equipment,
                orderIndex: exercises.count
            )

        let firstSet =
            SetDeckSet(
                setType: .reps,
                targetReps: 10,
                weight: 0,
                rpe: 6,
                restTimeInSeconds: 60,
                orderIndex: 0
            )

        firstSet.exercise = exercise
        exercise.sets = [firstSet]

        modelContext.insert(exercise)

        StrengthLabExerciseMediaBridge
            .applyLibraryMedia(
                to:
                    exercise,
                in:
                    modelContext
            )

        modelContext.insert(firstSet)

        var current = exercises
        current.append(exercise)

        workout.exercises = current
        workout.updatedAt = Date()

        try? modelContext.save()
    }

    private func addCustomExercise() {
        let exercise =
            SetDeckExercise(
                name: "New Exercise",
                orderIndex: exercises.count
            )

        let firstSet =
            SetDeckSet(
                setType: .reps,
                targetReps: 10,
                weight: 0,
                rpe: 6,
                restTimeInSeconds: 60,
                orderIndex: 0
            )

        firstSet.exercise = exercise
        exercise.sets = [firstSet]

        modelContext.insert(exercise)
        modelContext.insert(firstSet)

        var current = exercises
        current.append(exercise)

        workout.exercises = current
        workout.updatedAt = Date()

        try? modelContext.save()

        editingExercise = exercise
    }

    // MARK: - Replace an exercise without touching its programmed sets

    private func beginCustomReplacement(for target: SetDeckExercise) {
        replacementTarget = target
        // Detached draft: Cancel changes nothing in the workout.
        customReplacementDraft = SetDeckExercise(
            name: "New Exercise",
            isWarmup: target.isWarmup,
            orderIndex: target.orderIndex
        )
    }

    private func replaceWithAppExercise(
        _ definition: StrengthLabExerciseDefinition,
        in target: SetDeckExercise
    ) {
        target.name = definition.name
        target.equipment = definition.equipment
        target.note = nil
        target.muscleGroups = []
        clearExerciseMedia(on: target)

        // If the bank has an existing demo, use it as the fallback.
        target.gifURL = ExerciseCatalog.all.first {
            $0.name.localizedCaseInsensitiveCompare(definition.name) == .orderedSame
        }?.gifURL

        // Recover any user-saved media for the chosen app exercise.
        StrengthLabExerciseMediaBridge.applyLibraryMedia(
            to: target,
            in: modelContext
        )

        // Target UUID, set objects, rest, order and superset remain unchanged.
        workout.updatedAt = Date()
        try? modelContext.save()
    }

    private func replaceWithCustomExercise(
        _ draft: SetDeckExercise,
        in target: SetDeckExercise
    ) {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              name.localizedCaseInsensitiveCompare("New Exercise") != .orderedSame
        else { return }

        target.name = name
        target.note = draft.note
        target.equipment = draft.equipment
        target.muscleGroups = draft.muscleGroups
        target.isWarmup = draft.isWarmup
        clearExerciseMedia(on: target)
        target.videoURL = draft.videoURL
        target.importedVideoURL = draft.importedVideoURL
        target.gifURL = draft.gifURL
        target.gifSourceURL = draft.gifSourceURL
        target.gifEditedFPS = draft.gifEditedFPS
        target.gifEditedMaxWidth = draft.gifEditedMaxWidth
        target.gifTrimStart = draft.gifTrimStart
        target.gifTrimEnd = draft.gifTrimEnd
        target.videoTrimStart = draft.videoTrimStart
        target.videoTrimEnd = draft.videoTrimEnd

        // The existing workout's sets/rest and superset are deliberately kept.
        workout.updatedAt = Date()
        try? modelContext.save()
    }

    private func clearExerciseMedia(on exercise: SetDeckExercise) {
        // Clear references on THIS workout exercise; never delete media files.
        exercise.videoURL = nil
        exercise.importedVideoURL = nil
        exercise.gifURL = nil
        exercise.gifSourceURL = nil
        exercise.gifEditedFPS = nil
        exercise.gifEditedMaxWidth = nil
        exercise.gifTrimStart = nil
        exercise.gifTrimEnd = nil
        exercise.videoTrimStart = nil
        exercise.videoTrimEnd = nil
    }

    private func deleteExercise(
        _ exercise: SetDeckExercise
    ) {
        var current = exercises

        current.removeAll {
            $0.uuid == exercise.uuid
        }

        workout.exercises = current

        for (index, exercise) in
            current.enumerated()
        {
            exercise.orderIndex = index
        }

        modelContext.delete(exercise)

        workout.updatedAt = Date()

        try? modelContext.save()
    }

    private func linkSuperset(
        _ first: SetDeckExercise,
        with second: SetDeckExercise
    ) {
        let firstOld =
            first.supersetGroupID

        let secondOld =
            second.supersetGroupID

        let group =
            secondOld ??
            firstOld ??
            UUID()

        if let firstOld {
            for exercise in exercises
            where exercise.supersetGroupID ==
                firstOld
            {
                exercise.supersetGroupID =
                    group
            }
        }

        if let secondOld {
            for exercise in exercises
            where exercise.supersetGroupID ==
                secondOld
            {
                exercise.supersetGroupID =
                    group
            }
        }

        first.supersetGroupID = group
        second.supersetGroupID = group

        workout.updatedAt = Date()

        try? modelContext.save()
    }

    private func removeFromSuperset(
        _ exercise: SetDeckExercise
    ) {
        guard
            let group =
                exercise.supersetGroupID
        else {
            return
        }

        exercise.supersetGroupID = nil

        let remaining =
            exercises.filter {
                $0.supersetGroupID == group
            }

        if remaining.count <= 1 {
            remaining.forEach {
                $0.supersetGroupID = nil
            }
        }

        workout.updatedAt = Date()

        try? modelContext.save()
    }
}


// MARK: - App exercise replacement picker

private struct ReplacementAppRequest: Identifiable {
    let id = UUID()
    let target: SetDeckExercise
}

private struct ReplacementAppExercisePicker: View {
    @Environment(\.dismiss) private var dismiss
    let originalName: String
    let onReplace: (StrengthLabExerciseDefinition) -> Void

    @State private var searchText = ""
    @State private var selected: StrengthLabExerciseDefinition?
    @State private var askingToReplace = false

    private var results: [StrengthLabExerciseDefinition] {
        let all = StrengthLabExerciseLibrary.all
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return all }
        return all.filter {
            $0.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { definition in
                Button {
                    selected = definition
                    askingToReplace = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(definition.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("\(definition.browseCategory) · \(definition.equipment)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("App Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search app exercises"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Replace exercise?", isPresented: $askingToReplace) {
                Button("Cancel", role: .cancel) { selected = nil }
                Button("Replace") {
                    if let selected { onReplace(selected) }
                    selected = nil
                    dismiss()
                }
            } message: {
                Text("Replace \(originalName) with \(selected?.name ?? "this exercise")? Your existing sets, rest times and superset stay in place.")
            }
        }
        .presentationDetents([.large])
    }
}
