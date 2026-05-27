import SwiftUI

struct TemplateWorkoutSessionView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var workoutStore: WorkoutStore

    let templateID: UUID

    @State private var templateName = ""
    @State private var blocks: [WorkoutBlockSessionState] = []
    @State private var restRemaining: Int = 0
    @State private var hasLoaded = false

    @State private var showDiscardAlert = false
    @State private var showEndEarlyAlert = false
    @State private var showFinishAlert = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            WorkoutScreenBackground()

            if hasLoaded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(templateName)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        ForEach(blocks.indices, id: \.self) { blockIndex in
                            VStack(alignment: .leading, spacing: 14) {
                                Text(blocks[blockIndex].title)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                if let note = blocks[blockIndex].note {
                                    Text(note)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                ForEach(blocks[blockIndex].exercises.indices, id: \.self) { exerciseIndex in
                                    exerciseCard(blockIndex: blockIndex, exerciseIndex: exerciseIndex)
                                }
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.34))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                        }

                        Button {
                            showEndEarlyAlert = true
                        } label: {
                            Text("End & Save Now")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.orange.opacity(0.88))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(WorkoutPressStyle())
                        .padding(.top, 6)
                    }
                    .padding(20)
                    .padding(.bottom, 110)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }

            if restRemaining > 0 {
                restTimerOverlay
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTemplateIfNeeded()
        }
        .onReceive(timer) { _ in
            if restRemaining > 0 {
                restRemaining -= 1
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    showDiscardAlert = true
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
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

    private func loadTemplateIfNeeded() {
        guard !hasLoaded, let template = workoutStore.template(with: templateID) else { return }
        templateName = template.name
        blocks = WorkoutPlanLibrary.sessionBlocks(from: template)
        hasLoaded = true
    }

    private func exerciseCard(blockIndex: Int, exerciseIndex: Int) -> some View {
        let exercise = blocks[blockIndex].exercises[exerciseIndex]

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    if let detail = exercise.detail {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.82))
                    }
                }

                Spacer()

                Button {
                    toggleExerciseSkipped(blockIndex: blockIndex, exerciseIndex: exerciseIndex)
                } label: {
                    Text(exercise.skipped ? "Unskip Exercise" : "Skip Exercise")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(exercise.skipped ? Color.blue.opacity(0.85) : Color.orange.opacity(0.85))
                        .clipShape(Capsule())
                }
                .buttonStyle(WorkoutPressStyle())
            }

            if let fileName = exercise.videoFileName {
                ExerciseVideoPlayerView(fileName: fileName)
                    .opacity(exercise.skipped ? 0.35 : 1.0)
            }

            ForEach(exercise.sets.indices, id: \.self) { setIndex in
                setRow(blockIndex: blockIndex, exerciseIndex: exerciseIndex, setIndex: setIndex)
                    .opacity(exercise.skipped ? 0.45 : 1.0)
                    .disabled(exercise.skipped)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func setRow(blockIndex: Int, exerciseIndex: Int, setIndex: Int) -> some View {
        let set = blocks[blockIndex].exercises[exerciseIndex].sets[setIndex]

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Set \(setIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("Target: \(set.targetText)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.82))
            }

            HStack(spacing: 10) {
                Button {
                    decrementSetValue(blockIndex: blockIndex, exerciseIndex: exerciseIndex, setIndex: setIndex)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(WorkoutPressStyle())

                Text("\(set.actualValue) \(set.metric.unitLabel)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(minWidth: 86)

                Button {
                    incrementSetValue(blockIndex: blockIndex, exerciseIndex: exerciseIndex, setIndex: setIndex)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(WorkoutPressStyle())

                Spacer()

                Button {
                    toggleSetCompleted(blockIndex: blockIndex, exerciseIndex: exerciseIndex, setIndex: setIndex)
                } label: {
                    Text(set.completed ? "Done" : "Complete")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(set.completed ? Color.green.opacity(0.9) : Color.blue.opacity(0.9))
                        .clipShape(Capsule())
                }
                .buttonStyle(WorkoutPressStyle())

                Button {
                    toggleSetSkipped(blockIndex: blockIndex, exerciseIndex: exerciseIndex, setIndex: setIndex)
                } label: {
                    Text(set.skipped ? "Skipped" : "Skip")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(set.skipped ? Color.orange.opacity(0.95) : Color.gray.opacity(0.7))
                        .clipShape(Capsule())
                }
                .buttonStyle(WorkoutPressStyle())
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var restTimerOverlay: some View {
        VStack(spacing: 10) {
            Text("Rest Timer")
                .font(.headline.bold())
                .foregroundColor(.white)

            Text(timerText(restRemaining))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 10) {
                Button("-30s") {
                    restRemaining = max(0, restRemaining - 30)
                }
                .buttonStyle(PlainButtonStyle())

                Button("+30s") {
                    restRemaining += 30
                }
                .buttonStyle(PlainButtonStyle())

                Button("Skip") {
                    restRemaining = 0
                }
                .buttonStyle(PlainButtonStyle())
            }
            .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func decrementSetValue(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        let step = blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].metric.stepSize
        blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].actualValue =
            max(0, blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].actualValue - step)
    }

    private func incrementSetValue(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        let step = blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].metric.stepSize
        blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].actualValue += step
    }

    private func toggleSetCompleted(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].completed.toggle()

        if blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].completed {
            blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].skipped = false
            restRemaining = blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].restSeconds
        } else {
            restRemaining = 0
        }
    }

    private func toggleSetSkipped(blockIndex: Int, exerciseIndex: Int, setIndex: Int) {
        blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].skipped.toggle()

        if blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].skipped {
            blocks[blockIndex].exercises[exerciseIndex].sets[setIndex].completed = false
        }
    }

    private func toggleExerciseSkipped(blockIndex: Int, exerciseIndex: Int) {
        blocks[blockIndex].exercises[exerciseIndex].skipped.toggle()

        let isSkipped = blocks[blockIndex].exercises[exerciseIndex].skipped

        for idx in blocks[blockIndex].exercises[exerciseIndex].sets.indices {
            blocks[blockIndex].exercises[exerciseIndex].sets[idx].skipped = isSkipped
            if isSkipped {
                blocks[blockIndex].exercises[exerciseIndex].sets[idx].completed = false
            }
        }
    }

    private func finishWorkout(endedEarly: Bool) {
        workoutStore.saveTemplateWorkout(templateName: templateName, blocks: blocks, endedEarly: endedEarly)
        restRemaining = 0
        router.path = [.workoutMenu, .workoutLog]
    }

    private func timerText(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
