import SwiftUI
import UIKit
import AVFoundation

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
                WorkoutCountdownBeeper.shared.play(at: restRemaining)
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
        if (1...3).contains(restRemaining) { WorkoutCountdownBeeper.shared.play(at: restRemaining) }
    }

    private func skipCurrentSet() {
        guard let location = currentExerciseLocation else { return }

        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].skipped = true
        blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].completed = false

        restRemaining = blocks[location.blockIndex].exercises[location.exerciseIndex].sets[currentSetIndex].restSeconds
        phase = .resting
        if (1...3).contains(restRemaining) { WorkoutCountdownBeeper.shared.play(at: restRemaining) }
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

// Recorded 3-short-then-long workout beep sequence, with a synthesized fallback.
// Playback bypasses Silent mode while still allowing other music to continue.
@MainActor
final class WorkoutCountdownBeeper {
    static let shared = WorkoutCountdownBeeper()

    private let countdownClip: AVAudioPlayer?
    private let shortBeep: AVAudioPlayer?
    private let longBeep: AVAudioPlayer?

    private init() {
        if let url = Bundle.main.url(forResource: "mixkit-sport-start-bleeps-918", withExtension: "wav") {
            countdownClip = try? AVAudioPlayer(contentsOf: url)
        } else {
            countdownClip = nil
            #if DEBUG
            print("Workout countdown WAV not bundled; using synthesized fallback.")
            #endif
        }
        shortBeep = Self.makeTone(duration: 0.12)
        longBeep = Self.makeTone(duration: 0.55)
        countdownClip?.prepareToPlay()
        shortBeep?.prepareToPlay()
        longBeep?.prepareToPlay()
    }

    func play(at remaining: Int) {
        guard (0...3).contains(remaining) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Unable to activate workout countdown audio: \(error)")
            #endif
        }

        if let clip = countdownClip {
            if remaining == 3 {
                clip.stop()
                clip.currentTime = 0
                clip.play()
                return
            }
            // The sample contains its own beeps for 2, 1, and 0.
            if clip.isPlaying { return }
        }

        // For shorter timers, or before the provided WAV is added to the app.
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
        put(UInt16(1)) // PCM
        put(UInt16(1)) // Mono
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
