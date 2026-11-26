import SwiftUI
import Combine
import WatchKit

@main
struct ConsciousConnectionWatchApp: App {
    @StateObject private var controller = SLWatchController()

    var body: some Scene {
        WindowGroup {
            SLWatchRootView(controller: controller)
                .task { controller.activate() }
        }
    }
}

private struct SLWatchRootView: View {
    @ObservedObject var controller: SLWatchController
    @State private var showingEditor = false
    @State private var confirmingEnd = false

    private let coral = Color(red: 1, green: 0.38, blue: 0.48)
    private let ticks = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if controller.activeWorkout != nil {
                if showingEditor && controller.current != nil {
                    editor
                } else {
                    activeScreen
                }
            } else if controller.finishedName != nil {
                finishedScreen
            } else {
                picker
            }
        }
        .onReceive(ticks) { _ in controller.tick() }
        .onChange(of: controller.currentSetID) { _, _ in
            showingEditor = false
            controller.timedRemaining = 0
        }
        .confirmationDialog("Finish workout?", isPresented: $confirmingEnd,
                            titleVisibility: .visible) {
            Button("Finish & save") {
                Task { await controller.finish() }
            }
            Button("Keep going", role: .cancel) {}
        }
        .tint(coral)
    }

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(coral)
                    Text("StrengthLab").font(.headline)
                }

                if let snapshot = controller.snapshot {
                    Text(snapshot.programme)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(snapshot.workouts) { workout in
                        Button {
                            Task { await controller.start(workout) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.name).font(.headline).lineLimit(2)
                                Text("\(workout.exercises.count) exercises")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                    if snapshot.workouts.isEmpty {
                        Text("This programme has no saved workouts.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Open Conscious Connection → StrengthLab on your phone to load your workouts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = controller.errorMessage {
                    Text(error).font(.caption2).foregroundStyle(.orange)
                }
                Button("Refresh from phone", systemImage: "arrow.clockwise") {
                    controller.requestSnapshot()
                }
                .font(.caption2)
            }
            .padding(.horizontal, 6)
        }
    }

    private var activeScreen: some View {
        VStack(spacing: 6) {
            if let workout = controller.activeWorkout {
                Text(workout.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if controller.allCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("All sets completed").font(.headline)
                Button("Finish workout") { confirmingEnd = true }
                    .buttonStyle(.borderedProminent)

            } else if let current = controller.current {
                if let end = controller.restEnd, end > Date() {
                    HStack(spacing: 5) {
                        Text("REST")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                        Text(timerInterval: Date()...end, countsDown: true)
                            .monospacedDigit().font(.headline)
                        Button("Skip") { controller.restEnd = nil }
                            .font(.caption2).buttonStyle(.plain)
                    }
                }

                Text(current.exercise.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text("Set \(current.index) of \(current.total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if current.set.kind == "duration" {
                    Text("\(controller.timedRemaining > 0 ? controller.timedRemaining : Int(current.set.duration ?? 0)) sec")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Button(controller.timedEnd == nil ? "Start timer" : "Pause timer",
                           systemImage: controller.timedEnd == nil ? "play.fill" : "pause.fill") {
                        controller.startOrPauseTimedSet()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text(target(current.set))
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                }

                Button {
                    controller.complete(reps: current.set.reps, weight: current.set.weight)
                } label: {
                    Label("Complete set", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("Swipe down to edit reps or weight")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

            } else {
                Text("Choose a set on your phone, or finish this workout.")
                    .multilineTextAlignment(.center).font(.caption)
            }

            Button("End workout", role: .destructive) {
                confirmingEnd = true
            }
            .font(.caption2)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 5)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.height > 45 { showingEditor = true }
        })
    }

    private func target(_ set: SLWatchSet) -> String {
        switch set.kind {
        case "amap": return "AMAP" + (set.weight.map { " · \(formatted($0)) \(set.unit)" } ?? "")
        case "freeform": return "Freeform"
        default:
            let reps = "\(set.reps ?? 0) reps"
            return reps + (set.weight.map { " · \(formatted($0)) \(set.unit)" } ?? "")
        }
    }

    private func formatted(_ n: Double) -> String {
        n.rounded() == n ? "\(Int(n))" : String(format: "%.1f", n)
    }

    private var editor: some View {
        VStack(spacing: 9) {
            Text("EDIT SET")
                .font(.caption.bold())
                .foregroundStyle(coral)
            if let set = controller.current?.set {
                if set.kind == "reps" || set.kind == "amap" {
                    Stepper("Reps: \(set.reps ?? 0)", value: Binding(
                        get: { controller.current?.set.reps ?? 0 },
                        set: { controller.updateCurrent(reps: max(0, $0), weight: nil) }
                    ), in: 0...999)
                    if set.weight != nil {
                        Stepper("Weight: \(formatted(set.weight ?? 0)) \(set.unit)",
                                value: Binding(
                            get: { controller.current?.set.weight ?? 0 },
                            set: { controller.updateCurrent(reps: nil, weight: max(0, $0)) }
                        ), in: 0...500, step: 0.5)
                    }
                }
                if set.kind == "duration" {
                    Stepper("Seconds: \(Int(set.duration ?? 0))", value: Binding(
                        get: { Int(controller.current?.set.duration ?? 0) },
                        set: { controller.updateCurrent(reps: nil, weight: nil, duration: Double(max(1, $0))) }
                    ), in: 1...3600, step: 5)
                }
            }
            Button("Back to workout", systemImage: "arrow.up") {
                showingEditor = false
            }
            .buttonStyle(.borderedProminent)
            Text("Swipe up to return")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 5)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 40).onEnded { value in
            if value.translation.height < -45 { showingEditor = false }
        })
    }

    private var finishedScreen: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle).foregroundStyle(.green)
            Text("Workout finished").font(.headline)
            Text(controller.finishedName ?? "").font(.caption).lineLimit(2)
            if let kcal = controller.calories {
                Text("\(Int(kcal.rounded())) active kcal")
                    .font(.headline).foregroundStyle(coral)
            }
            Text("Open phone app to sync workout")
                .font(.caption)
                .multilineTextAlignment(.center)
            Button("Back to workouts") {
                controller.finishedName = nil
            }
        }
        .padding(.horizontal, 7)
    }
}
