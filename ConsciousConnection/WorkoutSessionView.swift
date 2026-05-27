import SwiftUI
import UIKit

private enum WorkoutScreenPhase {
    case performingSet
    case resting
}

struct WorkoutSessionView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var workoutStore: WorkoutStore

    let day: WorkoutDay

    @State private var blocks: [WorkoutBlockSessionState]
    @State private var currentExerciseSequenceIndex: Int = 0
    @State private var currentSetIndex: Int = 0
    @State private var phase: WorkoutScreenPhase = .performingSet
    @State private var restRemaining: Int = 0

    @State private var showDiscardAlert = false
    @State private var showEndEarlyAlert = false
    @State private var showFinishAlert = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let nextExerciseAssetName = "Nextexercise"

    init(day: WorkoutDay) {
        self.day = day
        _blocks = State(initialValue: WorkoutPlanLibrary.sessionBlocks(for: day))
    }

    var body: some View {
        ZStack {
            backgroundView

            if let location = currentExerciseLocation {
                switch phase {
                case .performingSet:
                    performingSetView(location: location)

                case .resting:
                    restingView(location: location)
                }
            } else {
                VStack(spacing: 16) {
                    Text("No exercises found.")
                        .foregroundColor(.white)

                    Button("Back to Workout Menu") {
                        makeTapFeelGood()
                        router.path = [.workoutMenu]
                    }
                }
            }
        }
        .navigationTitle(day.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            if phase == .resting && restRemaining > 0 {
                restRemaining -= 1
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    makeTapFeelGood()
                    showDiscardAlert = true
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    makeTapFeelGood()
                    showFinishAlert = true
                }
            }
        }
        .alert("Discard this workout?", isPresented: $showDiscardAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Discard", role: .destructive) {
                router.path = [.workoutMenu]
            }
        } message: {
            Text("This will throw away the current workout.")
        }
        .alert("End workout now and save it?", isPresented: $showEndEarlyAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("End & Save") {
                finishWorkout(endedEarly: true)
            }
        } message: {
            Text("Your completed, skipped, and partial progress will all be saved.")
        }
        .alert("Finish workout?", isPresented: $showFinishAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Finish") {
                finishWorkout(endedEarly: false)
            }
        } message: {
            Text("This saves everything, including skipped sets and skipped exercises.")
        }
    }

    private var backgroundView: some View {
        Group {
            if phase == .resting {
                LoopingBackgroundVideoView(fileName: "RestTimer.mp4")
                    .ignoresSafeArea()
            } else {
                WorkoutScreenBackground()
            }
        }
    }

    private func performingSetView(location: (blockIndex: Int, exerciseIndex: Int)) -> some View {
        let exercise = blocks[location.blockIndex].exercises[location.exerciseIndex]
        let set = exercise.sets[currentSetIndex]
        let totalSets = exercise.sets.count

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(exercise.title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                if let detail = exercise.detail {
                    Text(detail)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }

                Text("Set \(currentSetIndex + 1) of \(totalSets)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))

                if let fileName = exercise.videoFileName {
                    ExerciseVideoPlayerView(fileName: fileName)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Target: \(set.targetText)")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 24) {
                        Button {
                            makeTapFeelGood()
                            decrementCurrentSetValue()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(WorkoutPressStyle())

                        Text("\(set.actualValue) \(set.metric.unitLabel)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 150)

                        Button {
                            makeTapFeelGood()
                            incrementCurrentSetValue()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(WorkoutPressStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(18)
                .background(Color.black.opacity(0.34))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                HStack(spacing: 12) {
                    Button {
                        makeTapFeelGood()
                        completeCurrentSet()
                    } label: {
                        Text("Complete")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())

                    Button {
                        makeTapFeelGood()
                        skipCurrentSet()
                    } label: {
                        Text("Skip Set")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())
                }

                HStack(spacing: 12) {
                    Button {
                        makeTapFeelGood()
                        skipCurrentExercise()
                    } label: {
                        Text("Skip Exercise")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())

                    Button {
                        makeTapFeelGood()
                        showEndEarlyAlert = true
                    } label: {
                        Text("End & Save")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(WorkoutPressStyle())
                }
            }
            .padding(20)
            .padding(.top, 44)
            .padding(.bottom, 30)
        }
    }

    private func restingView(location: (blockIndex: Int, exerciseIndex: Int)) -> some View {
        let exercise = blocks[location.blockIndex].exercises[location.exerciseIndex]

        return GeometryReader { _ in
            ZStack {
                VStack {
                    Spacer(minLength: 0)

                    Text(timerText(restRemaining))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .offset(y: -50)

                    Spacer(minLength: 0)
                }

                VStack(spacing: 14) {
                    Text("Rest")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text(exercise.title)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()

                    if restRemaining > 0 {
                        HStack(spacing: 12) {
                            Button {
                                makeTapFeelGood()
                                restRemaining = max(0, restRemaining - 30)
                            } label: {
                                Text("-30")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(WorkoutPressStyle())

                            Button {
                                makeTapFeelGood()
                                restRemaining = 0
                            } label: {
                                Text("Skip Rest")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(WorkoutPressStyle())

                            Button {
                                makeTapFeelGood()
                                restRemaining += 30
                            } label: {
                                Text("+30")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(WorkoutPressStyle())
                        }
                    } else {
                        if hasNextSetInCurrentExercise {
                            Button {
                                makeTapFeelGood()
                                goToNextSet()
                            } label: {
                                Image("Nextset")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 240)
                            }
                            .buttonStyle(WorkoutPressStyle())
                            .frame(maxWidth: .infinity, alignment: .center)

                        } else if hasNextExercise {
                            Button {
                                makeTapFeelGood()
                                goToNextExercise()
                            } label: {
                                Image(nextExerciseAssetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 260)
                            }
                            .buttonStyle(WorkoutPressStyle())
                            .frame(maxWidth: .infinity, alignment: .center)

                        } else {
                            Button {
                                makeTapFeelGood()
                                finishWorkout(endedEarly: false)
                            } label: {
                                Text("Finish Workout")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green.opacity(0.9))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(WorkoutPressStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 44)
                .padding(.bottom, 26)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var exerciseSequence: [(blockIndex: Int, exerciseIndex: Int)] {
        var result: [(Int, Int)] = []

        for blockIndex in blocks.indices {
            for exerciseIndex in blocks[blockIndex].exercises.indices {
                result.append((blockIndex, exerciseIndex))
            }
        }

        return result
    }

    private var currentExerciseLocation: (blockIndex: Int, exerciseIndex: Int)? {
        guard exerciseSequence.indices.contains(currentExerciseSequenceIndex) else { return nil }
        return exerciseSequence[currentExerciseSequenceIndex]
    }

    private var hasNextSetInCurrentExercise: Bool {
        guard let location = currentExerciseLocation else { return false }
        let count = blocks[location.blockIndex].exercises[location.exerciseIndex].sets.count
        return currentSetIndex + 1 < count
    }

    private var hasNextExercise: Bool {
        currentExerciseSequenceIndex + 1 < exerciseSequence.count
    }

    private func decrementCurrentSetValue() {
        guard let location = currentExerciseLocation else { return }
        let step = blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].metric.stepSize
        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].actualValue =
            max(0, blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].actualValue - step)
    }

    private func incrementCurrentSetValue() {
        guard let location = currentExerciseLocation else { return }
        let step = blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].metric.stepSize
        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].actualValue += step
    }

    private func completeCurrentSet() {
        guard let location = currentExerciseLocation else { return }

        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].completed = true
        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].skipped = false

        restRemaining = blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].restSeconds
        phase = .resting
    }

    private func skipCurrentSet() {
        guard let location = currentExerciseLocation else { return }

        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].skipped = true
        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].completed = false

        restRemaining = blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].restSeconds
        phase = .resting
    }

    private func skipCurrentExercise() {
        guard let location = currentExerciseLocation else { return }

        blocks[location.blockIndex].exercises[location.exerciseIndex].skipped = true

        for idx in blocks[location.blockIndex].exercises[location.exerciseIndex].sets.indices {
            if !blocks[location.blockIndex].exercises[location.exerciseIndex].sets[idx].completed {
                blocks[location.blockIndex].exercises[location.exerciseIndex].sets[idx].skipped = true
            }
        }

        restRemaining = 0

        if hasNextExercise {
            currentExerciseSequenceIndex += 1
            currentSetIndex = 0
            phase = .performingSet
        } else {
            finishWorkout(endedEarly: false)
        }
    }

    private func goToNextSet() {
        guard hasNextSetInCurrentExercise else { return }
        currentSetIndex += 1
        phase = .performingSet
    }

    private func goToNextExercise() {
        guard hasNextExercise else { return }
        currentExerciseSequenceIndex += 1
        currentSetIndex = 0
        phase = .performingSet
    }

    private func finishWorkout(endedEarly: Bool) {
        workoutStore.saveWorkout(day: day, blocks: blocks, endedEarly: endedEarly)
        restRemaining = 0
        router.path = [.workoutMenu, .workoutLog]
    }

    private func timerText(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func makeTapFeelGood() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
