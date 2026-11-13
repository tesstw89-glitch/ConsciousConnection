import SwiftUI
import SwiftData
import AVFoundation
import ImageIO
import UIKit
import Foundation


private enum StrengthLabWorkoutPhase:
    Equatable
{
    case preflight
    case countdown
    case exercise
    case rest
    case extraDecision
    case complete
}


struct WorkoutRunView:
    View
{
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Environment(ExerciseManager.self)
    private var exerciseManager

    @Environment(HealthManager.self)
    private var healthManager

    let workout:
        WorkoutTemplate

    // STRENGTHLAB_COMBINED_SESSIONS_NOV08_2026
    // Old single-workout call sites continue working unchanged.
    let additionalWorkouts: [WorkoutTemplate]

    init(workout: WorkoutTemplate, additionalWorkouts: [WorkoutTemplate] = []) {
        self.workout = workout
        self.additionalWorkouts = additionalWorkouts
    }

    private var sessionWorkouts: [WorkoutTemplate] {
        var seen = Set<UUID>()
        return ([workout] + additionalWorkouts).filter { seen.insert($0.uuid).inserted }
    }

    private var sessionName: String {
        sessionWorkouts.map(\.name).joined(separator: " + ")
    }


    @State
    private var startedAt =
        Date()

    @State
    private var now =
        Date()

    @State
    private var workoutEndedAt:
        Date?

    @State
    private var endedEarly =
        false

    @State
    private var phase:
        StrengthLabWorkoutPhase =
            .preflight

    @State
    private var currentExerciseIndex =
        0

    @State
    private var currentSetIndex =
        0

    @State
    private var pendingExerciseIndex =
        0

    @State
    private var pendingSetIndex =
        0

    @State
    private var restEndDate:
        Date?

    @State
    private var restRemaining =
        0

    @State private var timedRemaining: Int?
    @State private var timedEndDate: Date?

    @State
    private var detailsShown =
        false

    @State
    private var mediaIsLandscape =
        false

    @State
    private var showExitOptions =
        false

    @State
    private var completedSetIDs:
        Set<UUID> = []

    @State
    private var historyCommitted =
        false

    @State
    private var healthSummary:
        StrengthLabHealthWorkoutSnapshot?

    @State
    private var healthLookupFinished =
        false

    @State
    private var summaryLookupToken =
        UUID()

    @State private var countdownValue = 3
    @State private var countdownBurst = false

    // STRENGTHLAB_WORKOUT_UX_OCT27_V1
    // These extra sets only exist for this workout, never in its saved template.
    @State private var extraSets: [SetDeckSet] = []


    private var topSafeAreaInset:
        CGFloat
    {
        UIApplication.shared
            .connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }?
            .safeAreaInsets
            .top
        ??
        0
    }


    private var exercises:
        [SetDeckExercise]
    {
        sessionWorkouts.flatMap { source in
            (source.exercises ?? []).sorted { $0.orderIndex < $1.orderIndex }
        }
    }

    private var currentExercise:
        SetDeckExercise?
    {
        guard
            exercises.indices
                .contains(
                    currentExerciseIndex
                )
        else {
            return nil
        }

        return
            exercises[
                currentExerciseIndex
            ]
    }


    private var currentSets:
        [SetDeckSet]
    {
        guard
            let currentExercise
        else {
            return []
        }

        let scheduled = orderedSets(for: currentExercise)
        // A bonus set is only attached to the final exercise of this session.
        if playbackPositions.last?.exercise == currentExerciseIndex {
            return scheduled + extraSets
        }
        return scheduled
    }


    private var currentSet:
        SetDeckSet?
    {
        guard
            currentSets.indices
                .contains(
                    currentSetIndex
                )
        else {
            return nil
        }

        return
            currentSets[
                currentSetIndex
            ]
    }


    private var totalSetCount:
        Int
    {
        exercises.reduce(
            0
        ) {
            partial,
            exercise in

            partial
            +
            orderedSets(
                for:
                    exercise
            )
            .count
        } + extraSets.count
    }


    var body: some View {
        ZStack {
            switch phase {

            case .preflight:
                workoutWatchReminder

            case .countdown:
                workoutStartingCountdown

            case .exercise:
                exerciseScreen

            case .rest:
                restScreen

            case .extraDecision:
                extraDecisionScreen

            case .complete:
                completionScreen
            }
        }
        .preferredColorScheme(
            .light
        )
        .onAppear {
            // Allow audible countdowns in Silent mode while mixing with other music.
            StrengthLabCountdownBeeper.shared.prepareAudioSession()
            for source in sessionWorkouts {
                StrengthLabExercisePreferences.applySaved(to: source, in: modelContext)
            }
        }
        .task {
            await healthManager
                .requestAuthorization()
        }
        .task {
            while !Task.isCancelled {
                try?
                    await Task.sleep(
                        for:
                            .seconds(1)
                    )

                now =
                    Date()
            }
        }
        .task(
            id:
                restEndDate
        ) {
            await runRestCountdown()
        }
        .task(id: timedEndDate) {
            await runTimedSetCountdown()
        }
        .confirmationDialog(
            "Leave workout?",
            isPresented:
                $showExitOptions,
            titleVisibility:
                .visible
        ) {
            Button(
                "End Workout Here"
            ) {
                finishWorkout(
                    endedEarly:
                        true
                )
            }

            Button(
                "Cancel Workout",
                role:
                    .destructive
            ) {
                dismiss()
            }

            Button(
                "Keep Going",
                role:
                    .cancel
            ) {
            }

        } message: {
            if completedSetIDs.isEmpty {
                Text(
                    "End Workout Here will finish the session and show your workout summary. Cancel Workout exits without logging completed sets."
                )
            } else {
                Text(
                    "End Workout Here will save \(completedSetIDs.count) completed set\(completedSetIDs.count == 1 ? "" : "s") and show your workout summary."
                )
            }
        }
    }


    // STRENGTHLAB_WORKOUT_REFINEMENTS_NOV03_2026
    // Workout preparation happens BEFORE the session clock begins.
    private var workoutWatchReminder: some View {
        ZStack {
            StrengthLabFigmaTheme.paleBlush.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                Image(systemName: "applewatch")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(StrengthLabFigmaTheme.coral)
                    .frame(width: 136, height: 136)
                    .background(Color.white, in: Circle())

                Text("BEFORE YOU START")
                    .font(StrengthLabFigmaTheme.bold(13))
                    .tracking(3)
                    .foregroundStyle(StrengthLabFigmaTheme.coral)

                Text("Remember to switch on workout on your watch")
                    .font(StrengthLabFigmaTheme.bold(30))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StrengthLabFigmaTheme.ink)
                    .padding(.horizontal, 20)

                Text("Choose a workout on your Apple Watch, then you're ready to go.")
                    .font(StrengthLabFigmaTheme.regular(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StrengthLabFigmaTheme.muted)

                Spacer()

                Button {
                    countdownValue = 3
                    countdownBurst = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        phase = .countdown
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(StrengthLabFigmaTheme.bold(19))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(StrengthLabFigmaTheme.coralGradient, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 28)
        }
    }

    // STRENGTHLAB_CLEAN_COUNTDOWN_NOV03_V3
    // Use the same clean coral countdown disc as StrengthLab's rest timer.
    // A subtle ring expands and fades at GO, without persistent tick marks.
    private var workoutStartingCountdown: some View {
        ZStack {
            StrengthLabFigmaTheme.paleBlush.ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                Text("GET READY")
                    .font(StrengthLabFigmaTheme.bold(15))
                    .tracking(3)
                    .foregroundStyle(StrengthLabFigmaTheme.coral)

                ZStack {
                    Circle()
                        .fill(StrengthLabFigmaTheme.coralGradient)
                        .frame(width: 248, height: 248)
                        .shadow(
                            color: StrengthLabFigmaTheme.coral.opacity(0.16),
                            radius: 18, y: 9
                        )
                        .scaleEffect(countdownBurst ? 1.06 : 1.0)

                    // Soft inner edge, rather than a busy clock-face border.
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 238, height: 238)
                        .scaleEffect(countdownBurst ? 1.06 : 1.0)

                    // This ripple is understated during the countdown and
                    // becomes an outward fizzle as the circle says GO!.
                    Circle()
                        .stroke(
                            StrengthLabFigmaTheme.coral.opacity(0.50),
                            lineWidth: 4
                        )
                        .frame(width: 248, height: 248)
                        .scaleEffect(countdownBurst ? 1.58 : 1.03)
                        .opacity(countdownBurst ? 0 : 0.35)

                    Text(countdownBurst ? "GO!" : "\(countdownValue)")
                        .font(
                            .system(
                                size: countdownBurst ? 61 : 100,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .scaleEffect(countdownBurst ? 1.06 : 1.0)
                }
                .frame(height: 265)
                .animation(.easeOut(duration: 0.48), value: countdownBurst)

                Text(sessionName)
                    .font(StrengthLabFigmaTheme.medium(18))
                    .foregroundStyle(StrengthLabFigmaTheme.ink)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .task { await beginWorkoutAfterCountdown() }
    }

    @MainActor
    private func beginWorkoutAfterCountdown() async {
        for tick in [3, 2, 1] {
            guard !Task.isCancelled else { return }
            StrengthLabCountdownBeeper.shared.play(at: tick)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                countdownValue = tick
            }
            try? await Task.sleep(for: .seconds(1))
        }

        guard !Task.isCancelled else { return }
        StrengthLabCountdownBeeper.shared.play(at: 0)
        withAnimation(.easeOut(duration: 0.48)) {
            countdownBurst = true
        }
        try? await Task.sleep(for: .milliseconds(480))
        guard !Task.isCancelled else { return }

        startedAt = Date()
        now = startedAt
        moveToFirstPlayableSet()
    }

    // MARK: - Exercise

    @ViewBuilder
    private var exerciseScreen:
        some View
    {
        if
            let exercise =
                currentExercise,
            let set =
                currentSet
        {
            GeometryReader {
                proxy in

                ZStack {
                    if detailsShown {
                        WorkoutLiveSetEditor(
                            exercise:
                                exercise,
                            set:
                                set,
                            setNumber:
                                currentSetIndex
                                + 1,
                            setCount:
                                currentSets
                                    .count,
                            onReturn: {
                                withAnimation(.snappy(duration: 0.3)) {
                                    detailsShown = false
                                }
                            }
                        )
                        .transition(
                            .move(
                                edge:
                                    .bottom
                            )
                            .combined(
                                with:
                                    .opacity
                            )
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 35)
                                .onEnded { value in
                                    if value.translation.height > 90 &&
                                       abs(value.translation.width) < value.translation.height {
                                        withAnimation(.snappy(duration: 0.32)) {
                                            detailsShown = false
                                        }
                                    }
                                }
                        )

                    } else {
                        mediaStage(
                            exercise:
                                exercise,
                            set:
                                set,
                            size:
                                proxy.size
                        )
                        .transition(
                            .opacity
                        )
                        .gesture(
                            DragGesture(
                                minimumDistance:
                                    35
                            )
                            .onEnded {
                                value in

                                if
                                    value
                                        .translation
                                        .height
                                    <
                                    -55
                                {
                                    withAnimation(
                                        .snappy(
                                            duration:
                                                0.32
                                        )
                                    ) {
                                        detailsShown =
                                            true
                                    }
                                }
                            }
                        )
                    }

                    workoutTopBar(
                        darkText:
                            detailsShown
                            ||
                            mediaIsLandscape
                    )
                }
                .animation(
                    .snappy(
                        duration:
                            0.32
                    ),
                    value:
                        detailsShown
                )
                .task(
                    id:
                        exercise.uuid
                ) {
                    mediaIsLandscape =
                        await isLandscapeMedia(
                            exercise
                        )
                }
            }
            .ignoresSafeArea()

        } else {
            completionScreen
        }
    }


    @ViewBuilder
    private func mediaStage(
        exercise:
            SetDeckExercise,
        set:
            SetDeckSet,
        size:
            CGSize
    ) -> some View
    {
        if mediaIsLandscape {
            ZStack {
                Color.white

                VStack(
                    spacing: 0
                ) {
                    Spacer(
                        minLength:
                            90
                    )

                    ExerciseMediaPlaybackView(
                        exercise:
                            exercise
                    )
                    .frame(
                        width:
                            size.width
                    )
                    .frame(
                        height:
                            min(
                                size.height
                                * 0.53,
                                size.width
                                * 0.72
                            )
                    )
                    .background(
                        Color.black
                    )

                    instructionBand(
                        exercise:
                            exercise,
                        set:
                            set
                    )

                    Spacer(
                        minLength: 0
                    )
                }
            }

        } else {
            ZStack(
                alignment:
                    .bottom
            ) {
                Color.black

                ExerciseMediaPlaybackView(
                    exercise:
                        exercise
                )
                .frame(
                    maxWidth:
                        .infinity,
                    maxHeight:
                        .infinity
                )
                .background(
                    Color.black
                )

                instructionBand(
                    exercise:
                        exercise,
                    set:
                        set
                )
            }
        }
    }


    private func instructionBand(
        exercise:
            SetDeckExercise,
        set:
            SetDeckSet
    ) -> some View
    {
        VStack(
            alignment:
                .leading,
            spacing: 10
        ) {
            Text(
                exercise.name
            )
            .font(
                StrengthLabFigmaTheme
                    .bold(23)
            )
            .foregroundStyle(
                Color.white
            )
            .lineLimit(2)

            Text(
                "SET \(currentSetIndex + 1) OF \(currentSets.count)"
            )
            .font(
                StrengthLabFigmaTheme
                    .bold(11)
            )
            .tracking(1.2)
            .foregroundStyle(
                Color.white
                    .opacity(
                        0.72
                    )
            )

            HStack(alignment: .center, spacing: 12) {
                Text(
                    instructionText(
                        for:
                            set
                    )
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(18)
                )
                .foregroundStyle(
                    Color.white
                )
                .fixedSize(
                    horizontal:
                        false,
                    vertical:
                        true
                )

                Button {
                    withAnimation(.snappy(duration: 0.32)) {
                        detailsShown = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit reps, weight and set details")
            }

            if set.setType == .duration,
               let seconds = set.targetDuration,
               seconds > 0 {
                timedSetControl(for: set)
                    .padding(.top, 7)
            }

            HStack(
                alignment:
                    .bottom
            ) {
                if
                    let rest =
                        set
                            .restTimeInSeconds,
                    rest > 0
                {
                    Label(
                        "Rest \(formattedRest(rest))",
                        systemImage:
                            "timer"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .medium(13)
                    )
                    .foregroundStyle(
                        Color.white
                            .opacity(
                                0.76
                            )
                    )
                }

                Spacer()

                doneSetButton(
                    action:
                        completeCurrentSet
                )
            }
        }
        .padding(
            .horizontal,
            22
        )
        .padding(
            .top,
            19
        )
        .padding(
            .bottom,
            24
        )
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
        .background(
            Color.black
                .opacity(
                    0.52
                )
        )
    }


    // MARK: - Timed exercise (separate from automatic rest)

    private func timedSetControl(for set: SetDeckSet) -> some View {
        let full = max(1, Int(ceil(set.targetDuration ?? 0)))
        let remaining = timedRemaining ?? full
        return HStack(spacing: 17) {
            Button {
                toggleTimedSet(for: set)
            } label: {
                VStack(spacing: 4) {
                    Text(remaining < 60 ? "\(remaining)s" : clockText(remaining))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Image(systemName: timedEndDate == nil
                          ? (remaining == 0 ? "arrow.counterclockwise" : "play.fill")
                          : "pause.fill")
                        .font(.system(size: 19, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 112, height: 112)
                .background(StrengthLabFigmaTheme.coralGradient, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(timedEndDate == nil ? "Start or resume exercise timer" : "Pause exercise timer")

            VStack(alignment: .leading, spacing: 9) {
                Text(timedEndDate == nil
                     ? (remaining == 0 ? "Timer finished" : "Tap play to start")
                     : "Exercise timer running")
                    .font(StrengthLabFigmaTheme.medium(13))
                    .foregroundStyle(.white)
                Button("Reset timer") {
                    timedEndDate = nil
                    timedRemaining = full
                }
                .font(StrengthLabFigmaTheme.medium(12))
                .foregroundStyle(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
        }
    }

    private func clockText(_ value: Int) -> String {
        String(format: "%d:%02d", value / 60, value % 60)
    }

    private func resetTimedSet() {
        timedEndDate = nil
        if let set = currentSet,
           set.setType == .duration,
           let seconds = set.targetDuration,
           seconds > 0 {
            timedRemaining = max(1, Int(ceil(seconds)))
        } else {
            timedRemaining = nil
        }
    }

    private func toggleTimedSet(for set: SetDeckSet) {
        if let end = timedEndDate {
            timedRemaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            timedEndDate = nil
            return
        }
        let full = max(1, Int(ceil(set.targetDuration ?? 0)))
        let seconds = (timedRemaining ?? full) > 0 ? (timedRemaining ?? full) : full
        timedRemaining = seconds
        if seconds <= 3 { StrengthLabCountdownBeeper.shared.play(at: seconds) }
        timedEndDate = Date().addingTimeInterval(TimeInterval(seconds))
    }

    @MainActor
    private func runTimedSetCountdown() async {
        guard let end = timedEndDate else { return }
        while !Task.isCancelled {
            let remaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if remaining != timedRemaining {
                StrengthLabCountdownBeeper.shared.play(at: remaining)
                timedRemaining = remaining
            }
            if remaining == 0 {
                timedEndDate = nil
                return // Never auto-complete the set or start the next one.
            }
            do { try await Task.sleep(for: .milliseconds(200)) }
            catch { return }
        }
    }

    private func doneSetButton(
        action:
            @escaping () -> Void
    ) -> some View
    {
        Button(
            action:
                action
        ) {
            Image(
                systemName:
                    "checkmark"
            )
            .font(
                .system(
                    size: 27,
                    weight: .bold
                )
            )
            .foregroundStyle(
                .white
            )
            .frame(
                width: 72,
                height: 72
            )
            .background(
                StrengthLabFigmaTheme
                    .coralGradient,
                in:
                    Circle()
            )
            .shadow(
                color:
                    StrengthLabFigmaTheme
                        .coral
                        .opacity(
                            0.34
                        ),
                radius: 14,
                y: 7
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            "Complete set"
        )
    }


    // MARK: - Rest

    private var restScreen:
        some View
    {
        ZStack(
            alignment:
                .bottomTrailing
        ) {
            Color.white
                .ignoresSafeArea()

            VStack(
                spacing: 20
            ) {
                Spacer()

                Text("REST")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .tracking(2)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )

                ZStack {
                    Circle()
                        .fill(
                            StrengthLabFigmaTheme
                                .coralGradient
                        )
                        .frame(
                            width: 248,
                            height: 248
                        )

                    Text(
                        restClock
                    )
                    .font(
                        .system(
                            size: 55,
                            weight: .bold,
                            design:
                                .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(
                        .white
                    )
                }

                if
                    let next =
                        pendingExercise
                {
                    VStack(
                        spacing: 6
                    ) {
                        Text("UP NEXT")
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(10)
                            )
                            .tracking(1.5)
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )

                        Text(
                            next.name
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(20)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                        Text(
                            "Set \(pendingSetIndex + 1)"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                    }
                }

                Spacer()
            }
            .frame(
                maxWidth:
                    .infinity,
                maxHeight:
                    .infinity
            )

            Button {
                finishRest()
            } label: {
                Text("Skip Rest")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(15)
                    )
                    .foregroundStyle(
                        .white
                    )
                    .padding(
                        .horizontal,
                        20
                    )
                    .frame(
                        height: 50
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .coralGradient,
                        in:
                            Capsule()
                    )
            }
            .buttonStyle(.plain)
            .padding(
                .trailing,
                22
            )
            .padding(
                .bottom,
                22
            )

            workoutTopBar(
                darkText:
                    true
            )
        }
    }


    // MARK: - Extra Set or Finish?

    private var extraDecisionScreen: some View {
        ZStack {
            StrengthLabFigmaTheme.paleBlush.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(StrengthLabFigmaTheme.coral)

                Text("All planned sets done!")
                    .font(StrengthLabFigmaTheme.bold(27))
                    .foregroundStyle(StrengthLabFigmaTheme.ink)
                    .multilineTextAlignment(.center)

                Text("Want one more set of your final exercise, or ready to finish?")
                    .font(StrengthLabFigmaTheme.medium(16))
                    .foregroundStyle(StrengthLabFigmaTheme.muted)
                    .multilineTextAlignment(.center)

                Button(action: addExtraSet) {
                    Label("Add an extra set?", systemImage: "plus.circle.fill")
                        .font(StrengthLabFigmaTheme.bold(17))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(.white)
                        .background(StrengthLabFigmaTheme.coralGradient, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Button {
                    finishWorkout(endedEarly: false)
                } label: {
                    Text("End workout now")
                        .font(StrengthLabFigmaTheme.bold(17))
                        .foregroundStyle(StrengthLabFigmaTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 25)
        }
    }


    // MARK: - Workout Finished

    private var completionScreen:
        some View
    {
        ZStack {
            StrengthLabFigmaTheme
                .paleBlush
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    spacing: 22
                ) {
                    Spacer()
                        .frame(
                            height: 52
                        )

                    Text("✨  🎉  ✨")
                        .font(
                            .system(
                                size: 37
                            )
                        )

                    Text(
                        "WORKOUT FINISHED"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(13)
                    )
                    .tracking(2)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                    Text(
                        sessionName
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(30)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    if endedEarly {
                        Text("Ended early")
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(12)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )
                            .padding(
                                .horizontal,
                                12
                            )
                            .frame(
                                height: 30
                            )
                            .background(
                                StrengthLabFigmaTheme
                                    .blush,
                                in:
                                    Capsule()
                            )
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(
                                .flexible()
                            ),
                            GridItem(
                                .flexible()
                            )
                        ],
                        spacing: 12
                    ) {
                        summaryCard(
                            title:
                                "Workout time",
                            value:
                                elapsed,
                            icon:
                                "clock"
                        )

                        summaryCard(
                            title:
                                "Sets",
                            value:
                                "\(completedSetIDs.count) / \(totalSetCount)",
                            icon:
                                "checkmark.circle"
                        )

                        summaryCard(
                            title:
                                "Active calories",
                            value:
                                calorieText,
                            icon:
                                "flame.fill"
                        )

                        summaryCard(
                            title:
                                "Avg heart rate",
                            value:
                                averageHeartRateText,
                            icon:
                                "heart.fill"
                        )

                        if
                            let maxHR =
                                healthSummary?
                                    .maximumHeartRate
                        {
                            summaryCard(
                                title:
                                    "Peak heart rate",
                                value:
                                    "\(Int(maxHR.rounded())) bpm",
                                icon:
                                    "waveform.path.ecg"
                            )
                        }

                        if
                            let watch =
                                healthSummary
                        {
                            summaryCard(
                                title:
                                    "Watch workout",
                                value:
                                    durationText(
                                        watch
                                            .duration
                                    ),
                                icon:
                                    "applewatch"
                            )
                        }
                    }

                    watchStatusCard

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(17)
                            )
                            .foregroundStyle(
                                .white
                            )
                            .frame(
                                maxWidth:
                                    .infinity
                            )
                            .frame(
                                height: 56
                            )
                            .background(
                                StrengthLabFigmaTheme
                                    .coralGradient,
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
                    .padding(
                        .top,
                        6
                    )
                }
                .padding(
                    .horizontal,
                    24
                )
                .padding(
                    .bottom,
                    30
                )
            }
            .scrollIndicators(
                .hidden
            )
        }
        .task(
            id:
                summaryLookupToken
        ) {
            await loadAppleWatchSummary()
        }
    }


    private func summaryCard(
        title:
            String,
        value:
            String,
        icon:
            String
    ) -> some View
    {
        VStack(
            alignment:
                .leading,
            spacing: 12
        ) {
            Image(
                systemName:
                    icon
            )
            .font(
                .system(
                    size: 20,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .coral
            )

            Text(value)
                .font(
                    StrengthLabFigmaTheme
                        .bold(23)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.7
                )

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(12)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
        }
        .frame(
            maxWidth:
                .infinity,
            minHeight:
                112,
            alignment:
                .leading
        )
        .padding(16)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius:
                        22,
                    style:
                        .continuous
                )
        )
    }


    @ViewBuilder
    private var watchStatusCard:
        some View
    {
        if healthSummary != nil {
            HStack(
                spacing: 12
            ) {
                Image(
                    systemName:
                        "applewatch"
                )
                .font(
                    .title3
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .coral
                )

                VStack(
                    alignment:
                        .leading,
                    spacing: 3
                ) {
                    Text(
                        "Apple Watch workout matched"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                    Text(
                        "Calories and heart-rate data came from Apple Health."
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(12)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Spacer()
            }
            .padding(16)
            .background(
                Color.white,
                in:
                    RoundedRectangle(
                        cornerRadius:
                            20,
                        style:
                            .continuous
                    )
            )

        } else if !healthLookupFinished {
            HStack(
                spacing: 12
            ) {
                ProgressView()
                    .tint(
                        StrengthLabFigmaTheme
                            .coral
                    )

                VStack(
                    alignment:
                        .leading,
                    spacing: 3
                ) {
                    Text(
                        "Syncing Apple Watch data…"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )

                    Text(
                        "Looking for the Traditional Strength Training workout that overlaps this StrengthLab session."
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(12)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }
            }
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )
            .padding(16)
            .background(
                Color.white,
                in:
                    RoundedRectangle(
                        cornerRadius:
                            20
                    )
            )

        } else {
            VStack(
                alignment:
                    .leading,
                spacing: 12
            ) {
                Text(
                    "Apple Watch data hasn't appeared yet."
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

                Text(
                    "If you just stopped the Watch workout, Health may still be syncing it."
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(12)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

                Button {
                    healthSummary =
                        nil

                    healthLookupFinished =
                        false

                    summaryLookupToken =
                        UUID()
                } label: {
                    Label(
                        "Check Again",
                        systemImage:
                            "arrow.clockwise"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        .white
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                    .frame(
                        height: 44
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .coralGradient,
                        in:
                            Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )
            .padding(16)
            .background(
                Color.white,
                in:
                    RoundedRectangle(
                        cornerRadius:
                            20
                    )
            )
        }
    }


    // MARK: - Top Bar

    private func workoutTopBar(
        darkText:
            Bool
    ) -> some View
    {
        VStack {
            HStack {
                Button {
                    showExitOptions =
                        true
                } label: {
                    Image(
                        systemName:
                            "xmark"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .background(
                        Color.white
                            .opacity(
                                0.96
                            ),
                        in:
                            Circle()
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(
                    alignment:
                        .trailing,
                    spacing: 3
                ) {
                    Text(
                        elapsed
                    )
                    .font(
                        .headline
                            .monospacedDigit()
                    )
                    .foregroundStyle(
                        darkText
                        ? StrengthLabFigmaTheme
                            .ink
                        : Color.white
                    )

                    if phase == .exercise {
                        Text(
                            "\(currentExerciseIndex + 1)/\(max(exercises.count, 1))"
                        )
                        .font(
                            .caption
                                .weight(
                                    .bold
                                )
                        )
                        .foregroundStyle(
                            darkText
                            ? StrengthLabFigmaTheme
                                .muted
                            : Color.white
                                .opacity(
                                    0.72
                                )
                        )
                    }
                }
                .padding(
                    .horizontal,
                    14
                )
                .frame(
                    height: 48
                )
                .background(
                    darkText
                    ? Color.white
                        .opacity(
                            0.92
                        )
                    : Color.black
                        .opacity(
                            0.34
                        ),
                    in:
                        Capsule()
                )
            }
            .padding(
                .horizontal,
                20
            )
            .padding(
                .top,
                max(
                    12,
                    topSafeAreaInset
                    +
                    8
                )
            )

            Spacer()
        }
    }


    // MARK: - Progression

    private func moveToFirstPlayableSet()
    {
        guard
            let position =
                firstPlayablePosition()
        else {
            finishWorkout(
                endedEarly:
                    false
            )

            return
        }

        goTo(
            exerciseIndex:
                position.exercise,
            setIndex:
                position.set
        )
    }


    // STRENGTHLAB_COMBINED_SESSIONS_NOV08_2026
    // Each template is played completely before the next. Supersets cycle
    // inside their OWN template, even if two source templates share a group UUID.
    private var playbackPositions: [(exercise: Int, set: Int)] {
        var result: [(exercise: Int, set: Int)] = []
        var offset = 0

        for source in sessionWorkouts {
            let local = (source.exercises ?? [])
                .sorted { $0.orderIndex < $1.orderIndex }
            var handledGroups = Set<UUID>()

            for (index, exercise) in local.enumerated() {
                if let groupID = exercise.supersetGroupID {
                    guard handledGroups.insert(groupID).inserted else { continue }
                    let members = local.enumerated().filter {
                        $0.element.supersetGroupID == groupID
                    }
                    let cycles = members.map { orderedSets(for: $0.element).count }.max() ?? 0
                    if cycles > 0 {
                        for cycle in 0..<cycles {
                            for (memberIndex, member) in members {
                                if orderedSets(for: member).indices.contains(cycle) {
                                    result.append((offset + memberIndex, cycle))
                                }
                            }
                        }
                    }
                } else {
                    for setIndex in orderedSets(for: exercise).indices {
                        result.append((offset + index, setIndex))
                    }
                }
            }
            offset += local.count
        }
        return result
    }

    private func firstPlayablePosition() -> (exercise: Int, set: Int)? {
        playbackPositions.first
    }


    private func completeCurrentSet()
    {
        guard
            let set =
                currentSet
        else {
            finishWorkout(
                endedEarly:
                    false
            )

            return
        }

        timedEndDate = nil
        completedSetIDs.insert(
            set.uuid
        )

        try?
            modelContext.save()

        guard let next = nextPosition() else {
            showExtraSetDecision()
            return
        }

        let rest =
            max(
                0,
                set
                    .restTimeInSeconds
                ??
                0
            )

        if rest > 0 {
            pendingExerciseIndex =
                next.exercise

            pendingSetIndex =
                next.set

            restRemaining =
                rest

            if rest <= 3 { StrengthLabCountdownBeeper.shared.play(at: rest) }

            restEndDate =
                Date()
                    .addingTimeInterval(
                        TimeInterval(
                            rest
                        )
                    )

            detailsShown =
                false

            withAnimation(
                .snappy(
                    duration:
                        0.3
                )
            ) {
                phase =
                    .rest
            }

        } else {
            goTo(
                exerciseIndex:
                    next.exercise,
                setIndex:
                    next.set
            )
        }
    }


    private func showExtraSetDecision() {
        timedEndDate = nil
        timedRemaining = nil
        restEndDate = nil
        detailsShown = false
        withAnimation(.snappy(duration: 0.3)) {
            phase = .extraDecision
        }
    }

    private func addExtraSet() {
        guard let last = playbackPositions.last,
              exercises.indices.contains(last.exercise),
              let previous = currentSet else {
            finishWorkout(endedEarly: false)
            return
        }
        let scheduledCount = orderedSets(for: exercises[last.exercise]).count
        let index = scheduledCount + extraSets.count
        let extra = SetDeckSet(
            setType: previous.setType,
            targetReps: previous.targetReps,
            weight: previous.weight,
            targetDuration: previous.targetDuration,
            setDescription: previous.setDescription,
            rpe: previous.rpe,
            restTimeInSeconds: 0,
            orderIndex: index
        )
        // Do NOT set extra.exercise or insert extra into modelContext:
        // that would permanently alter the saved workout template.
        extraSets.append(extra)
        goTo(exerciseIndex: last.exercise, setIndex: index)
    }

    private func finishWorkout(
        endedEarly:
            Bool
    )
    {
        guard
            phase !=
                .complete
        else {
            return
        }

        self.endedEarly =
            endedEarly

        workoutEndedAt =
            Date()

        restEndDate =
            nil

        restRemaining =
            0

        timedEndDate = nil
        timedRemaining = nil

        detailsShown =
            false

        commitCompletedSetHistory(
            endedEarly:
                endedEarly
        )

        if !completedSetIDs.isEmpty {
            StrengthLabCompletedSessions.record(
                workoutName: sessionName,
                startedAt: startedAt,
                endedAt: workoutEndedAt ?? Date(),
                completedSetCount: completedSetIDs.count,
                endedEarly: endedEarly
            )
        }

        healthSummary =
            nil

        healthLookupFinished =
            false

        summaryLookupToken =
            UUID()

        withAnimation(
            .snappy(
                duration:
                    0.35
            )
        ) {
            phase =
                .complete
        }
    }


    private func nextPosition() -> (exercise: Int, set: Int)? {
        let positions = playbackPositions
        guard let index = positions.firstIndex(where: {
            $0.exercise == currentExerciseIndex && $0.set == currentSetIndex
        }) else { return nil }
        let next = positions.index(after: index)
        return positions.indices.contains(next) ? positions[next] : nil
    }


    private func goTo(
        exerciseIndex:
            Int,
        setIndex:
            Int
    )
    {
        currentExerciseIndex =
            exerciseIndex

        currentSetIndex =
            setIndex

        resetTimedSet()

        detailsShown =
            false

        mediaIsLandscape =
            false

        restEndDate =
            nil

        withAnimation(
            .snappy(
                duration:
                    0.3
            )
        ) {
            phase =
                .exercise
        }
    }


    private func finishRest()
    {
        guard
            phase ==
                .rest
        else {
            return
        }

        restEndDate =
            nil

        restRemaining =
            0

        goTo(
            exerciseIndex:
                pendingExerciseIndex,
            setIndex:
                pendingSetIndex
        )
    }


    @MainActor
    private func runRestCountdown()
        async
    {
        guard
            phase ==
                .rest,
            let end =
                restEndDate
        else {
            return
        }

        while !Task.isCancelled {
            let remaining =
                max(
                    0,
                    Int(
                        ceil(
                            end
                                .timeIntervalSinceNow
                        )
                    )
                )

            if remaining != restRemaining {
                StrengthLabCountdownBeeper.shared.play(at: remaining)
                restRemaining = remaining
            }

            if remaining <= 0 {
                finishRest()
                return
            }

            try?
                await Task.sleep(
                    for:
                        .milliseconds(
                            250
                        )
                )
        }
    }


    // MARK: - Apple Health Summary

    @MainActor
    private func loadAppleWatchSummary()
        async
    {
        guard
            phase ==
                .complete,
            let ended =
                workoutEndedAt
        else {
            return
        }

        healthLookupFinished =
            false

        /*
         Give Apple Watch / HealthKit a short window to sync after
         the user taps End on Traditional Strength Training.
        */
        for attempt in 0..<12 {
            if Task.isCancelled {
                return
            }

            if
                let snapshot =
                    await healthManager
                        .matchingStrengthWorkoutSnapshot(
                            strengthLabStart:
                                startedAt,
                            strengthLabEnd:
                                ended
                        )
            {
                healthSummary =
                    snapshot

                healthLookupFinished =
                    true

                return
            }

            if attempt < 11 {
                try?
                    await Task.sleep(
                        for:
                            .seconds(1)
                    )
            }
        }

        healthLookupFinished =
            true
    }


    // MARK: - History

    private func commitCompletedSetHistory(
        endedEarly:
            Bool
    )
    {
        guard
            !historyCommitted
        else {
            return
        }

        try?
            modelContext.save()

        guard
            !completedSetIDs.isEmpty
        else {
            historyCommitted =
                true

            return
        }

        let completedAt =
            Date()

        for exercise in exercises {
            let sets =
                orderedSets(
                    for:
                        exercise
                )

            for set in sets
            where
                completedSetIDs
                    .contains(
                        set.uuid
                    )
            {
                _ =
                    exerciseManager
                        .recordHistory(
                            for:
                                set,
                            completedDate:
                                completedAt,
                            actualReps:
                                set.targetReps,
                            actualWeight:
                                set.weight,
                            actualWeightUnit:
                                nil,
                            actualDuration:
                                set.setType
                                ==
                                .duration
                                ? set.targetDuration
                                : nil,
                            actualDescription:
                                set.setDescription,
                            actualRpe:
                                set.rpe,
                            note:
                                endedEarly
                                ? "Ended early · \(sessionName)"
                                : "Workout · \(sessionName)"
                        )
            }
        }

        // Store an extra performance against the final planned set, not as
        // a newly programmed set. The history note identifies it as extra.
        if let last = playbackPositions.last,
           exercises.indices.contains(last.exercise),
           let source = orderedSets(for: exercises[last.exercise]).last {
            for extra in extraSets where completedSetIDs.contains(extra.uuid) {
                _ = exerciseManager.recordHistory(
                    for: source,
                    completedDate: completedAt,
                    actualReps: extra.targetReps,
                    actualWeight: extra.weight,
                    actualWeightUnit: nil,
                    actualDuration: extra.setType == .duration ? extra.targetDuration : nil,
                    actualDescription: extra.setDescription,
                    actualRpe: extra.rpe,
                    note: "Extra set · \(sessionName)"
                )
            }
        }

        historyCommitted =
            true
    }


    // MARK: - Data

    private func orderedSets(
        for exercise:
            SetDeckExercise
    ) -> [SetDeckSet]
    {
        let managed =
            exerciseManager
                .sets(
                    for:
                        exercise
                )

        if !managed.isEmpty {
            return
                managed.sorted {
                    $0.orderIndex <
                    $1.orderIndex
                }
        }

        return
            (exercise.sets ?? [])
                .sorted {
                    $0.orderIndex <
                    $1.orderIndex
                }
    }


    private var pendingExercise:
        SetDeckExercise?
    {
        guard
            exercises.indices
                .contains(
                    pendingExerciseIndex
                )
        else {
            return nil
        }

        return
            exercises[
                pendingExerciseIndex
            ]
    }


    private func instructionText(
        for set:
            SetDeckSet
    ) -> String
    {
        // STRENGTHLAB_DYNAMIC_REPS_INSTRUCTION_NOV03_2026
        // The main workout screen must always reflect edits to current reps.
        // A saved instructional note may contain obsolete phrases such as
        // "20 total • plate core • 2 rounds"; don't use it as the live target.
        if set.setType == .reps {
            if let reps = set.targetReps {
                return "\(reps) reps"
            }
            return "Complete the set"
        }

        if set.setType == .amap {
            if let reps = set.targetReps, reps > 0 {
                return "AMAP · aim for \(reps)+ reps"
            }
            return "As many reps as possible"
        }

        if
            let description =
                set
                    .setDescription?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
            !description.isEmpty
        {
            // A copied note like "16 reps" must not override the live target.
            if (set.setType == .reps || set.setType == .amap),
               let reps = set.targetReps,
               description.range(
                   of: #"^\s*\d+\s*reps?\s*$"#,
                   options: [.regularExpression, .caseInsensitive]
               ) != nil {
                return "\(reps) reps"
            }
            return description
        }

        switch set.setType {

        case .reps:
            if
                let reps =
                    set.targetReps
            {
                return
                    "\(reps) reps"
            }

            return
                "Complete the set"

        case .amap:
            if
                let reps =
                    set.targetReps,
                reps > 0
            {
                return
                    "AMAP · aim for \(reps)+ reps"
            }

            return
                "As many reps as possible"

        case .duration:
            if
                let duration =
                    set.targetDuration
            {
                return
                    formattedRest(
                        Int(
                            duration
                        )
                    )
            }

            return
                "Timed set"

        case .freeform:
            return
                "Complete this set"
        }
    }


    private var elapsed:
        String
    {
        let endpoint =
            workoutEndedAt
            ??
            now

        let total =
            max(
                0,
                Int(
                    endpoint
                        .timeIntervalSince(
                            startedAt
                        )
                )
            )

        return
            durationText(
                TimeInterval(
                    total
                )
            )
    }


    private var restClock:
        String
    {
        let minutes =
            restRemaining / 60

        let seconds =
            restRemaining % 60

        return
            String(
                format:
                    "%02d:%02d",
                minutes,
                seconds
            )
    }


    private var calorieText:
        String
    {
        guard
            let calories =
                healthSummary?
                    .activeEnergyKCal
        else {
            return
                healthLookupFinished
                ? "—"
                : "…"
        }

        return
            "\(Int(calories.rounded())) kcal"
    }


    private var averageHeartRateText:
        String
    {
        guard
            let heartRate =
                healthSummary?
                    .averageHeartRate
        else {
            return
                healthLookupFinished
                ? "—"
                : "…"
        }

        return
            "\(Int(heartRate.rounded())) bpm"
    }


    private func durationText(
        _ duration:
            TimeInterval
    ) -> String
    {
        let total =
            max(
                0,
                Int(
                    duration.rounded()
                )
            )

        let hours =
            total / 3600

        let minutes =
            (
                total % 3600
            )
            / 60

        let seconds =
            total % 60

        if hours > 0 {
            return
                String(
                    format:
                        "%d:%02d:%02d",
                    hours,
                    minutes,
                    seconds
                )
        }

        return
            String(
                format:
                    "%02d:%02d",
                minutes,
                seconds
            )
    }


    private func formattedRest(
        _ seconds:
            Int
    ) -> String
    {
        if seconds >= 60 {
            let minutes =
                seconds / 60

            let remainder =
                seconds % 60

            if remainder == 0 {
                return
                    minutes == 1
                    ? "1 min"
                    : "\(minutes) min"
            }

            return
                "\(minutes):\(String(format: "%02d", remainder))"
        }

        return
            "\(seconds)s"
    }


    // MARK: - Media Orientation

    private func isLandscapeMedia(
        _ exercise:
            SetDeckExercise
    ) async -> Bool
    {
        if
            let gif =
                exercise.gifURL,
            gif.isFileURL,
            let source =
                CGImageSourceCreateWithURL(
                    gif as CFURL,
                    nil
                ),
            let image =
                CGImageSourceCreateImageAtIndex(
                    source,
                    0,
                    nil
                )
        {
            return
                image.width >
                image.height
        }

        let candidate:
            URL?

        if
            let imported =
                exercise
                    .importedVideoURL,
            !imported.isFileURL
            ||
            FileManager.default
                .fileExists(
                    atPath:
                        imported.path
                )
        {
            candidate =
                imported

        } else if
            let video =
                exercise.videoURL,
            video.isFileURL
            ||
            [
                "mp4",
                "mov",
                "m4v",
                "m3u8"
            ]
            .contains(
                video
                    .pathExtension
                    .lowercased()
            )
        {
            candidate =
                video

        } else {
            candidate =
                nil
        }

        guard
            let candidate
        else {
            return false
        }

        let asset =
            AVURLAsset(
                url:
                    candidate
            )

        do {
            let tracks =
                try await asset
                    .loadTracks(
                        withMediaType:
                            .video
                    )

            guard
                let track =
                    tracks.first
            else {
                return false
            }

            let size =
                try await track
                    .load(
                        .naturalSize
                    )

            let transform =
                try await track
                    .load(
                        .preferredTransform
                    )

            let rect =
                CGRect(
                    origin:
                        .zero,
                    size:
                        size
                )
                .applying(
                    transform
                )

            return
                abs(
                    rect.width
                )
                >
                abs(
                    rect.height
                )

        } catch {
            return false
        }
    }
}


// MARK: - Live Set Editor

private struct WorkoutLiveSetEditor:
    View
{
    @AppStorage(
        AppStorageKeys
            .useMetricUnits
    )
    private var useMetricUnits =
        false

    @Environment(\.modelContext) private var modelContext

    @Bindable
    var set:
        SetDeckSet

    let exercise:
        SetDeckExercise

    let setNumber:
        Int

    let setCount:
        Int

    let onReturn:
        () -> Void


    init(
        exercise:
            SetDeckExercise,
        set:
            SetDeckSet,
        setNumber:
            Int,
        setCount:
            Int,
        onReturn:
            @escaping () -> Void
    ) {
        self.exercise =
            exercise

        self.set =
            set

        self.setNumber =
            setNumber

        self.setCount =
            setCount

        self.onReturn =
            onReturn
    }


    var body: some View {
        ZStack(
            alignment:
                .bottomTrailing
        ) {
            StrengthLabFigmaTheme
                .paleBlush
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment:
                        .leading,
                    spacing: 18
                ) {
                    Spacer()
                        .frame(
                            height: 88
                        )

                    Text(
                        exercise.name
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(29)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                    HStack {
                        Text(
                            "SET \(setNumber) OF \(setCount)"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(11)
                        )
                        .tracking(1.4)
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )

                        Spacer()

                        Image(
                            systemName:
                                "chevron.down"
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                    }

                    Button(action: onReturn) {
                        Label("Back to exercise", systemImage: "chevron.down.circle.fill")
                            .font(StrengthLabFigmaTheme.bold(15))
                            .foregroundStyle(StrengthLabFigmaTheme.coral)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    Text(
                        "Swipe down to return to the demo"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )

                    VStack(
                        spacing: 12
                    ) {
                        if
                            set.setType ==
                                .reps
                            ||
                            set.setType ==
                                .amap
                        {
                            WorkoutIntAdjuster(
                                title:
                                    set
                                        .setType
                                    ==
                                    .amap
                                    ? "Target reps"
                                    : "Reps",
                                value:
                                    repsBinding,
                                range:
                                    0...100,
                                step:
                                    1
                            )

                            WorkoutDoubleAdjuster(
                                title:
                                    "Weight (\(useMetricUnits ? "kg" : "lbs"))",
                                value:
                                    weightBinding,
                                range:
                                    0...1000,
                                step:
                                    0.5
                            )
                        }

                        if
                            set.setType ==
                                .duration
                        {
                            WorkoutIntAdjuster(
                                title:
                                    "Duration",
                                value:
                                    durationBinding,
                                range:
                                    0...3600,
                                step:
                                    15,
                                suffix:
                                    "s"
                            )
                        }

                        WorkoutIntAdjuster(
                            title:
                                "RPE",
                            value:
                                rpeBinding,
                            range:
                                0...10,
                            step:
                                1
                        )

                        WorkoutIntAdjuster(
                            title:
                                "Rest after set",
                            value:
                                restBinding,
                            range:
                                0...600,
                            step:
                                15,
                            suffix:
                                "s",
                            zeroText:
                                "Off"
                        )
                    }

                    if
                        let note =
                            set
                                .setDescription,
                        !note.isEmpty
                    {
                        Text(note)
                            .font(
                                StrengthLabFigmaTheme
                                    .medium(16)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .ink
                            )
                            .padding(18)
                            .frame(
                                maxWidth:
                                    .infinity,
                                alignment:
                                    .leading
                            )
                            .background(
                                Color.white,
                                in:
                                    RoundedRectangle(
                                        cornerRadius:
                                            20
                                    )
                            )
                    }

                    Spacer()
                        .frame(
                            height: 110
                        )
                }
                .padding(
                    .horizontal,
                    22
                )
            }
            .scrollIndicators(
                .hidden
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
                StrengthLabExercisePreferences.change(.reps($0), for: exercise, in: modelContext)
            }
        )
    }


    private var durationBinding:
        Binding<Int>
    {
        Binding(
            get: {
                Int(
                    set.targetDuration
                    ??
                    0
                )
            },
            set: {
                set.targetDuration =
                    TimeInterval(
                        $0
                    )
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


    private var restBinding:
        Binding<Int>
    {
        Binding(
            get: {
                set.restTimeInSeconds
                ??
                0
            },
            set: {
                set.restTimeInSeconds =
                    $0 <= 0
                    ? nil
                    : $0
                StrengthLabExercisePreferences.change(.rest($0), for: exercise, in: modelContext)
            }
        )
    }


    private var weightBinding:
        Binding<Double>
    {
        Binding(
            get: {
                let pounds =
                    set.weight
                    ??
                    0

                return
                    useMetricUnits
                    ? pounds
                        * 0.45359237
                    : pounds
            },
            set: {
                value in

                set.weight =
                    useMetricUnits
                    ? value
                        / 0.45359237
                    : value
                StrengthLabExercisePreferences.change(.weight(set.weight ?? 0), for: exercise, in: modelContext)
            }
        )
    }
}


// MARK: - Live Controls

private struct WorkoutIntAdjuster:
    View
{
    let title:
        String

    @Binding
    var value:
        Int

    let range:
        ClosedRange<Int>

    let step:
        Int

    var suffix:
        String = ""

    var zeroText:
        String? = nil


    var body: some View {
        VStack(
            alignment:
                .leading,
            spacing: 10
        ) {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(15)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

            HStack {
                Button {
                    value =
                        max(
                            range.lowerBound,
                            value - step
                        )
                } label: {
                    Image(
                        systemName:
                            "minus"
                    )
                    .font(
                        .headline
                            .bold()
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in:
                            Circle()
                    )
                }

                Spacer()

                Text(
                    displayValue
                )
                .font(
                    .system(
                        size: 36,
                        weight: .medium,
                        design:
                            .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

                Spacer()

                Button {
                    value =
                        min(
                            range.upperBound,
                            value + step
                        )
                } label: {
                    Image(
                        systemName:
                            "plus"
                    )
                    .font(
                        .headline
                            .bold()
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in:
                            Circle()
                    )
                }
            }
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )
        }
        .padding(18)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius: 22
                )
        )
    }


    private var displayValue:
        String
    {
        if
            value == 0,
            let zeroText
        {
            return zeroText
        }

        return
            "\(value)\(suffix)"
    }
}


private struct WorkoutDoubleAdjuster:
    View
{
    let title:
        String

    @Binding
    var value:
        Double

    let range:
        ClosedRange<Double>

    let step:
        Double


    var body: some View {
        VStack(
            alignment:
                .leading,
            spacing: 10
        ) {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(15)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

            HStack {
                Button {
                    value =
                        max(
                            range.lowerBound,
                            value - step
                        )
                } label: {
                    Image(
                        systemName:
                            "minus"
                    )
                    .font(
                        .headline
                            .bold()
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in:
                            Circle()
                    )
                }

                Spacer()

                Text(
                    formattedWeight
                )
                .font(
                    .system(
                        size: 36,
                        weight: .medium,
                        design:
                            .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

                Spacer()

                Button {
                    value =
                        min(
                            range.upperBound,
                            value + step
                        )
                } label: {
                    Image(
                        systemName:
                            "plus"
                    )
                    .font(
                        .headline
                            .bold()
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .blush,
                        in:
                            Circle()
                    )
                }
            }
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )
        }
        .padding(18)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius: 22
                )
        )
    }


    private var formattedWeight:
        String
    {
        if
            value.rounded()
            ==
            value
        {
            return
                String(
                    format:
                        "%.0f",
                    value
                )
        }

        return
            String(
                format:
                    "%.1f",
                value
            )
    }
}

// Play the user's 3-short-then-long countdown recording. The last beep is
// already part of the 3.79-second clip, so don't also play generated tones.
// Short countdowns (<3 seconds) retain a small synthesized fallback.
@MainActor
private final class StrengthLabCountdownBeeper {
    static let shared = StrengthLabCountdownBeeper()

    private let countdownClip: AVAudioPlayer?
    private let shortBeep: AVAudioPlayer?
    private let longBeep: AVAudioPlayer?

    private init() {
        if let url = Bundle.main.url(forResource: "mixkit-sport-start-bleeps-918", withExtension: "wav") {
            countdownClip = try? AVAudioPlayer(contentsOf: url)
        } else {
            countdownClip = nil
            #if DEBUG
            print("Workout countdown WAV not found in app bundle; using synthesized fallback.")
            #endif
        }
        shortBeep = Self.makeTone(duration: 0.12)
        longBeep = Self.makeTone(duration: 0.55)
        countdownClip?.prepareToPlay()
        shortBeep?.prepareToPlay()
        longBeep?.prepareToPlay()
    }

    func prepareAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Could not activate audible workout countdowns: \(error)")
            #endif
        }
    }

    func play(at remaining: Int) {
        guard (0...3).contains(remaining) else { return }
        prepareAudioSession()

        if let clip = countdownClip {
            if remaining == 3 {
                clip.stop()
                clip.currentTime = 0
                clip.play()
                return
            }
            // The recorded sound includes the later beats at 2, 1 and 0.
            if clip.isPlaying { return }
        }

        // Fallback for a 1- or 2-second timer, or if the WAV is not bundled.
        switch remaining {
        case 1...3:
            shortBeep?.stop()
            shortBeep?.currentTime = 0
            shortBeep?.play()
        case 0:
            longBeep?.stop()
            longBeep?.currentTime = 0
            longBeep?.play()
        default:
            break
        }
    }

    private static func makeTone(duration: Double) -> AVAudioPlayer? {
        let sampleRate = 22_050
        let frameCount = Int(Double(sampleRate) * duration)
        let pcmByteCount = frameCount * MemoryLayout<Int16>.size
        var wav = Data()

        func put<T: FixedWidthInteger>(_ value: T) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { wav.append(contentsOf: $0) }
        }

        wav.append(contentsOf: "RIFF".utf8)
        put(UInt32(36 + pcmByteCount))
        wav.append(contentsOf: "WAVEfmt ".utf8)
        put(UInt32(16))
        put(UInt16(1))
        put(UInt16(1))
        put(UInt32(sampleRate))
        put(UInt32(sampleRate * 2))
        put(UInt16(2))
        put(UInt16(16))
        wav.append(contentsOf: "data".utf8)
        put(UInt32(pcmByteCount))

        for sampleIndex in 0..<frameCount {
            let position = Double(sampleIndex) / Double(frameCount)
            let attack = min(1, position / 0.03)
            let release = min(1, (1 - position) / 0.14)
            let envelope = max(0, min(attack, release))
            let tone = sin(2 * Double.pi * 880 * Double(sampleIndex) / Double(sampleRate))
            put(Int16(tone * envelope * 12_000))
        }
        return try? AVAudioPlayer(data: wav)
    }
}
