import SwiftUI
import SwiftData

struct WorkoutTemplateExerciseEditor: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Bindable
    var exercise: SetDeckExercise

    // Used by Replace → Custom Exercise. The draft is not in SwiftData.
    var isReplacementDraft = false
    var onSave: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @State private var showInvalidName = false

    @State
    private var mediaOpen = false

    private var sets: [SetDeckSet] {
        (exercise.sets ?? [])
            .sorted {
                $0.orderIndex < $1.orderIndex
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 28
                    ) {
                        hero

                        exerciseDetails

                        actionRow

                        if !isReplacementDraft {
                            setsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 44)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button {
                        onCancel?()
                        dismiss()
                    } label: {
                        Image(
                            systemName: "xmark"
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
                        .frame(
                            width: 40,
                            height: 40
                        )
                        .background(
                            StrengthLabFigmaTheme.blush,
                            in: Circle()
                        )
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button {
                        if isReplacementDraft {
                            let name = exercise.name.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            guard !name.isEmpty,
                                  name.localizedCaseInsensitiveCompare("New Exercise") != .orderedSame
                            else {
                                showInvalidName = true
                                return
                            }
                            exercise.name = name
                            onSave?()
                        } else {
                            try? modelContext.save()
                        }
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(14)
                            )
                            .foregroundStyle(.white)
                            .padding(
                                .horizontal,
                                18
                            )
                            .frame(height: 40)
                            .background(
                                StrengthLabFigmaTheme
                                    .coralGradient,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(
                Color.white,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
        }
        .preferredColorScheme(.light)
        .tint(
            StrengthLabFigmaTheme.coral
        )
        .sheet(
            isPresented: $mediaOpen
        ) {
            mediaSheet
        }
        .alert("Name your exercise", isPresented: $showInvalidName) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enter a name before replacing the exercise.")
        }
    }

    // MARK: - Header

    private var hero: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 10) {
                Text("EXERCISE")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(11)
                    )
                    .tracking(1.2)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                Capsule()
                    .fill(
                        StrengthLabFigmaTheme
                            .coral
                            .opacity(0.16)
                    )
                    .frame(
                        width: 34,
                        height: 4
                    )
            }

            Text(exercise.name)
                .font(
                    StrengthLabFigmaTheme
                        .bold(29)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            if
                let equipment =
                    exercise.equipment,
                !equipment.isEmpty
            {
                Text(equipment)
                    .font(
                        StrengthLabFigmaTheme
                            .regular(15)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
            }
        }
    }

    // MARK: - Exercise Details

    private var exerciseDetails:
        some View
    {
        VStack(spacing: 0) {
            editorField(
                title: "Exercise name",
                systemImage:
                    "figure.strengthtraining.traditional"
            ) {
                TextField(
                    "Exercise name",
                    text: $exercise.name
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .multilineTextAlignment(
                    .trailing
                )
            }

            Divider()
                .padding(.leading, 54)

            editorField(
                title: "Equipment",
                systemImage: "dumbbell.fill"
            ) {
                TextField(
                    "None",
                    text:
                        equipmentBinding
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .multilineTextAlignment(
                    .trailing
                )
            }
        }
        .padding(.horizontal, 18)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.07),
                lineWidth: 1
            )
        }
    }

    private func editorField<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder
        content: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .blush
                )
                .frame(
                    width: 38,
                    height: 38
                )
                .overlay {
                    Image(
                        systemName:
                            systemImage
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(15)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

            Spacer(
                minLength: 12
            )

            content()
                .frame(
                    maxWidth: 180
                )
        }
        .frame(
            minHeight: 62
        )
    }

    private var equipmentBinding:
        Binding<String>
    {
        Binding(
            get: {
                exercise.equipment ?? ""
            },
            set: {
                exercise.equipment =
                    $0.isEmpty
                    ? nil
                    : $0
            }
        )
    }

    // MARK: - Quick Actions

    private var actionRow:
        some View
    {
        HStack(spacing: 12) {
            warmupCard

            mediaCard
        }
    }

    private var warmupCard:
        some View
    {
        Button {
            exercise.isWarmup.toggle()
        } label: {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                HStack {
                    Circle()
                        .fill(
                            exercise.isWarmup
                            ? StrengthLabFigmaTheme
                                .coral
                            : StrengthLabFigmaTheme
                                .blush
                        )
                        .frame(
                            width: 40,
                            height: 40
                        )
                        .overlay {
                            Image(
                                systemName:
                                    "flame.fill"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight:
                                        .semibold
                                )
                            )
                            .foregroundStyle(
                                exercise.isWarmup
                                ? Color.white
                                : StrengthLabFigmaTheme
                                    .coral
                            )
                        }

                    Spacer()

                    Image(
                        systemName:
                            exercise.isWarmup
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.system(size: 18))
                    .foregroundStyle(
                        exercise.isWarmup
                        ? StrengthLabFigmaTheme
                            .coral
                        : Color.black
                            .opacity(0.18)
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Warm-up")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(16)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                    Text(
                        exercise.isWarmup
                        ? "Included"
                        : "Optional"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                exercise.isWarmup
                ? StrengthLabFigmaTheme
                    .blush
                    .opacity(0.72)
                : Color.white,
                in:
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    exercise.isWarmup
                    ? StrengthLabFigmaTheme
                        .coral
                        .opacity(0.28)
                    : Color.black
                        .opacity(0.07),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var mediaCard:
        some View
    {
        Button {
            mediaOpen = true
        } label: {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                HStack {
                    Circle()
                        .fill(
                            StrengthLabFigmaTheme
                                .blush
                        )
                        .frame(
                            width: 40,
                            height: 40
                        )
                        .overlay {
                            Image(
                                systemName:
                                    "play.rectangle.fill"
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight:
                                        .semibold
                                )
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )
                        }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Media")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(16)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                    Text(mediaSubtitle)
                        .font(
                            StrengthLabFigmaTheme
                                .regular(13)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color.white,
                in:
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    Color.black.opacity(
                        0.07
                    ),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var mediaSubtitle:
        String
    {
        if
            exercise.gifURL != nil ||
            exercise.videoURL != nil
        {
            if
                exercise.gifTrimStart != nil ||
                exercise.gifTrimEnd != nil ||
                exercise.videoTrimStart != nil ||
                exercise.videoTrimEnd != nil
            {
                return "Demo · trimmed"
            }

            return "Demo attached"
        }

        return "Add a demo"
    }

    // MARK: - Sets

    private var setsSection:
        some View
    {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Sets")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(22)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                    Text(
                        sets.count == 1
                        ? "1 working set"
                        : "\(sets.count) working sets"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Spacer()

                Text("\(sets.count)")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in: Circle()
                    )
            }

            ForEach(
                Array(
                    sets.enumerated()
                ),
                id: \.element.uuid
            ) {
                index,
                set in

                TemplateSetEditorCard(
                    set: set,
                    number: index + 1
                ) {
                    deleteSet(set)
                }
            }

            Button {
                addSet()
            } label: {
                HStack(spacing: 10) {
                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .bold
                        )
                    )

                    Text("Add set")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(15)
                        )
                }
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 54)
                .background(
                    StrengthLabFigmaTheme
                        .coralGradient,
                    in:
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Media Sheet

    private var mediaSheet:
        some View
    {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                Form {
                    ExerciseMediaEditorWithTrim(
                        exercise: exercise
                    )
                }
                .scrollContentBackground(
                    .hidden
                )
                .background(Color.white)
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
                        mediaOpen = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }
            }
            .tint(
                StrengthLabFigmaTheme
                    .coral
            )
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Data Actions

    private func addSet() {
        let set =
            SetDeckSet(
                setType: .reps,
                targetReps: 10,
                weight: 0,
                rpe: 6,
                restTimeInSeconds: 60,
                orderIndex: sets.count
            )

        set.exercise = exercise

        var current = sets
        current.append(set)

        exercise.sets = current

        modelContext.insert(set)

        try? modelContext.save()
    }

    private func deleteSet(
        _ set: SetDeckSet
    ) {
        var current = sets

        current.removeAll {
            $0.uuid == set.uuid
        }

        exercise.sets = current

        for (
            index,
            set
        ) in current.enumerated() {
            set.orderIndex = index
        }

        modelContext.delete(set)

        try? modelContext.save()
    }
}


// MARK: - Set Card

private struct TemplateSetEditorCard:
    View
{
    @Bindable
    var set: SetDeckSet

    let number: Int
    let onDelete: () -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            cardHeader

            setTypePicker

            metrics
        }
        .padding(18)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(
                    0.07
                ),
                lineWidth: 1
            )
        }
        .shadow(
            color:
                Color.black.opacity(
                    0.035
                ),
            radius: 14,
            y: 5
        )
    }

    private var cardHeader:
        some View
    {
        HStack {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                    .frame(
                        width: 34,
                        height: 34
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in: Circle()
                    )

                Text("Set \(number)")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(17)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
            }

            Spacer()

            Button(
                role: .destructive
            ) {
                onDelete()
            } label: {
                Image(
                    systemName:
                        "trash"
                )
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.red.opacity(
                        0.78
                    )
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Color.red.opacity(
                        0.07
                    ),
                    in: Circle()
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Delete set"
            )
        }
    }

    // MARK: Set Type

    private var setTypePicker:
        some View
    {
        HStack(spacing: 7) {
            setTypeButton(
                "Reps",
                type: .reps
            )

            setTypeButton(
                "AMAP",
                type: .amap
            )

            setTypeButton(
                "Time",
                type: .duration
            )

            setTypeButton(
                "Free",
                type: .freeform
            )
        }
        .padding(5)
        .background(
            StrengthLabFigmaTheme
                .blush
                .opacity(0.62),
            in:
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
        )
    }

    private func setTypeButton(
        _ title: String,
        type: SetType
    ) -> some View {
        let selected =
            set.setType == type

        return Button {
            set.setType = type
        } label: {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .bold(12)
                )
                .foregroundStyle(
                    selected
                    ? Color.white
                    : StrengthLabFigmaTheme
                        .muted
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(height: 36)
                .background(
                    selected
                    ? AnyShapeStyle(
                        StrengthLabFigmaTheme
                            .coralGradient
                    )
                    : AnyShapeStyle(
                        Color.clear
                    ),
                    in:
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Metrics

    @ViewBuilder
    private var metrics:
        some View
    {
        VStack(spacing: 10) {
            if
                set.setType == .reps ||
                set.setType == .amap
            {
                CompactIntControl(
                    title:
                        set.setType == .amap
                        ? "Target reps"
                        : "Reps",
                    systemImage:
                        "repeat",
                    value:
                        repsBinding,
                    range: 0...100,
                    step: 1
                )

                CompactDoubleControl(
                    title: "Weight",
                    systemImage:
                        "scalemass.fill",
                    value:
                        weightBinding,
                    range: 0...1000,
                    step: 2.5,
                    suffix: ""
                )
            }

            if
                set.setType ==
                    .duration
            {
                CompactIntControl(
                    title: "Duration",
                    systemImage:
                        "timer",
                    value:
                        durationBinding,
                    range: 0...3600,
                    step: 15,
                    suffix: "s"
                )
            }

            CompactIntControl(
                title: "Rest",
                systemImage:
                    "timer",
                value:
                    restBinding,
                range: 0...600,
                step: 15,
                suffix: "s"
            )

            CompactIntControl(
                title: "RPE",
                systemImage:
                    "gauge.with.dots.needle.33percent",
                value:
                    rpeBinding,
                range: 0...10,
                step: 1
            )
        }
    }

    private var repsBinding:
        Binding<Int>
    {
        Binding(
            get: {
                set.targetReps ?? 0
            },
            set: {
                set.targetReps = $0
            }
        )
    }

    private var weightBinding:
        Binding<Double>
    {
        Binding(
            get: {
                set.weight ?? 0
            },
            set: {
                set.weight = $0
            }
        )
    }

    private var durationBinding:
        Binding<Int>
    {
        Binding(
            get: {
                Int(
                    set.targetDuration ??
                    0
                )
            },
            set: {
                set.targetDuration =
                    TimeInterval($0)
            }
        )
    }

    private var restBinding:
        Binding<Int>
    {
        Binding(
            get: {
                set.restTimeInSeconds ??
                0
            },
            set: {
                set.restTimeInSeconds =
                    $0 <= 0
                    ? nil
                    : $0
            }
        )
    }


    private var rpeBinding:
        Binding<Int>
    {
        Binding(
            get: {
                set.rpe ?? 0
            },
            set: {
                set.rpe = $0
            }
        )
    }
}


// MARK: - Compact Integer Control

private struct CompactIntControl:
    View
{
    let title: String
    let systemImage: String

    @Binding
    var value: Int

    let range:
        ClosedRange<Int>

    let step: Int

    var suffix: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .blush
                )
                .frame(
                    width: 36,
                    height: 36
                )
                .overlay {
                    Image(
                        systemName:
                            systemImage
                    )
                    .font(
                        .system(
                            size: 13,
                            weight:
                                .semibold
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

            Spacer()

            HStack(spacing: 4) {
                controlButton(
                    systemName:
                        "minus"
                ) {
                    value =
                        max(
                            range.lowerBound,
                            value - step
                        )
                }

                Text(
                    "\(value)\(suffix)"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(15)
                )
                .monospacedDigit()
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
                .frame(
                    minWidth: 58
                )

                controlButton(
                    systemName:
                        "plus"
                ) {
                    value =
                        min(
                            range.upperBound,
                            value + step
                        )
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func controlButton(
        systemName: String,
        action:
            @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            Image(
                systemName:
                    systemName
            )
            .font(
                .system(
                    size: 12,
                    weight: .bold
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .coral
            )
            .frame(
                width: 34,
                height: 34
            )
            .background(
                StrengthLabFigmaTheme
                    .blush,
                in: Circle()
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Compact Double Control

private struct CompactDoubleControl:
    View
{
    let title: String
    let systemImage: String

    @Binding
    var value: Double

    let range:
        ClosedRange<Double>

    let step: Double

    var suffix: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .blush
                )
                .frame(
                    width: 36,
                    height: 36
                )
                .overlay {
                    Image(
                        systemName:
                            systemImage
                    )
                    .font(
                        .system(
                            size: 13,
                            weight:
                                .semibold
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

            Spacer()

            HStack(spacing: 4) {
                controlButton(
                    systemName:
                        "minus"
                ) {
                    value =
                        max(
                            range.lowerBound,
                            value - step
                        )
                }

                Text(
                    "\(formattedValue)\(suffix)"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(15)
                )
                .monospacedDigit()
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
                .frame(
                    minWidth: 58
                )

                controlButton(
                    systemName:
                        "plus"
                ) {
                    value =
                        min(
                            range.upperBound,
                            value + step
                        )
                }
            }
        }
        .padding(.vertical, 3)
    }

    private var formattedValue:
        String
    {
        if value.rounded() == value {
            return "\(Int(value))"
        }

        return String(
            format: "%.1f",
            value
        )
    }

    private func controlButton(
        systemName: String,
        action:
            @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            Image(
                systemName:
                    systemName
            )
            .font(
                .system(
                    size: 12,
                    weight: .bold
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .coral
            )
            .frame(
                width: 34,
                height: 34
            )
            .background(
                StrengthLabFigmaTheme
                    .blush,
                in: Circle()
            )
        }
        .buttonStyle(.plain)
    }
}
