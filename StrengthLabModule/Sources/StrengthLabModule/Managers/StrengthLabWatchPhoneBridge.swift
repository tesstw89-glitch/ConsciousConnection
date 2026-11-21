import Foundation
import SwiftData
import WatchConnectivity

// Lightweight wire models. Kept independent of SwiftData so the watch never needs
// the iPhone's database or StrengthLabModule (which targets iOS only).
struct SLWatchSnapshot: Codable {
    var programme: String
    var workouts: [SLWatchWorkout]
}
struct SLWatchWorkout: Codable, Identifiable {
    var id: UUID
    var name: String
    var exercises: [SLWatchExercise]
}
struct SLWatchExercise: Codable, Identifiable {
    var id: UUID
    var name: String
    var sets: [SLWatchSet]
}
struct SLWatchSet: Codable, Identifiable {
    var id: UUID
    var kind: String
    var reps: Int?
    var weight: Double?
    var duration: Double?
    var rest: Int
    var unit: String
}
struct SLWatchEvent: Codable {
    var id: UUID
    var kind: String // started, navigated, adjusted, completed, finished
    var workoutID: UUID
    var setID: UUID?
    var reps: Int?
    var weight: Double?
    var duration: Double?
    var calories: Double?
    var when: Date
}

extension Notification.Name {
    static let strengthLabWatchEvent = Notification.Name("strengthLab.watchEvent")
}

@MainActor
final class StrengthLabWatchPhoneBridge: NSObject, WCSessionDelegate {
    static let shared = StrengthLabWatchPhoneBridge()
    private var session: WCSession?
    private var context: ModelContext?
    private var manager: ExerciseManager?
    private var processed: Set<UUID> = []
    private let processedKey = "strengthlab.watch.eventIDs.v1"
    private(set) var phoneWorkoutID: UUID?

    private override init() {
        super.init()
        processed = Set((UserDefaults.standard.stringArray(forKey: processedKey) ?? [])
            .compactMap(UUID.init(uuidString:)))
    }

    func activate(context: ModelContext, manager: ExerciseManager) {
        self.context = context
        self.manager = manager
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        session = wc
        wc.delegate = self
        wc.activate()
        publishWorkouts()
    }

    func publishWorkouts() {
        guard let context, let session, session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { return }
        let all = (try? context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []
        let programme = StrengthLabProgramStore.shared.activeProgram
        let chosen: [WorkoutTemplate]
        if let programme {
            chosen = programme.workoutIDs.compactMap { id in all.first(where: { $0.uuid == id }) }
        } else {
            chosen = all.sorted { $0.name < $1.name }
        }
        let usesMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        let payload = SLWatchSnapshot(
            programme: programme?.name ?? "My workouts",
            workouts: chosen.map { workout in
                SLWatchWorkout(
                    id: workout.uuid, name: workout.name,
                    exercises: (workout.exercises ?? []).sorted { $0.orderIndex < $1.orderIndex }.map { exercise in
                        SLWatchExercise(
                            id: exercise.uuid, name: exercise.name,
                            sets: (exercise.sets ?? []).sorted { $0.orderIndex < $1.orderIndex }.map { set in
                                SLWatchSet(
                                    id: set.uuid,
                                    kind: set.setType.rawValue,
                                    reps: set.targetReps,
                                    weight: set.weight,
                                    duration: set.targetDuration,
                                    rest: set.restTimeInSeconds ?? 0,
                                    unit: usesMetric ? "kg" : "lb"
                                )
                            }
                        )
                    }
                )
            }
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? session.updateApplicationContext(["slSnapshot": data])
        if session.isReachable {
            session.sendMessage(["slSnapshot": data], replyHandler: nil, errorHandler: nil)
        }
    }

    func phoneStarted(workoutID: UUID) {
        phoneWorkoutID = workoutID
        send(kind: "started", workoutID: workoutID)
    }

    func phoneAdvanced(workoutID: UUID, setID: UUID) {
        send(kind: "navigated", workoutID: workoutID, setID: setID)
    }

    func phoneCompleted(workoutID: UUID, setID: UUID, reps: Int?, weight: Double?) {
        send(kind: "completed", workoutID: workoutID, setID: setID, reps: reps, weight: weight)
    }

    func phoneFinished(workoutID: UUID) {
        if phoneWorkoutID == workoutID { phoneWorkoutID = nil }
        send(kind: "finished", workoutID: workoutID)
        publishWorkouts()
    }

    private func send(kind: String, workoutID: UUID, setID: UUID? = nil,
                      reps: Int? = nil, weight: Double? = nil) {
        guard let wc = session, wc.isReachable else { return }
        let event = SLWatchEvent(id: UUID(), kind: kind, workoutID: workoutID,
                                 setID: setID, reps: reps, weight: weight,
                                 duration: nil, calories: nil, when: Date())
        if let data = try? JSONEncoder().encode(event) {
            wc.sendMessage(["slEvent": data], replyHandler: nil, errorHandler: nil)
        }
    }

    private func receive(_ data: Data) {
        guard let event = try? JSONDecoder().decode(SLWatchEvent.self, from: data) else { return }
        guard processed.insert(event.id).inserted else { return }
        UserDefaults.standard.set(processed.suffix(1000).map(\.uuidString), forKey: processedKey)
        guard let context else { return }

        if event.kind == "adjusted", let setID = event.setID,
           let set = findSet(setID, in: context) {
            if let reps = event.reps { set.targetReps = reps }
            if let weight = event.weight { set.weight = weight }
            if let duration = event.duration { set.targetDuration = duration }
            try? context.save()
        }
        if event.kind == "completed", let setID = event.setID,
           let set = findSet(setID, in: context) {
            // Stable event UUID is the history UUID: queue retries cannot double-log a set.
            let id = event.id
            let descriptor = FetchDescriptor<SetDeckSetHistory>(predicate: #Predicate { $0.uuid == id })
            if ((try? context.fetch(descriptor)) ?? []).isEmpty {
                let history = SetDeckSetHistory(
                    uuid: event.id, completedDate: event.when,
                    actualReps: event.reps ?? set.targetReps,
                    actualWeight: event.weight ?? set.weight,
                    actualDuration: event.duration ?? set.targetDuration,
                    note: "Apple Watch · \(event.workoutID.uuidString)"
                )
                history.set = set
                context.insert(history)
                try? context.save()
            }
        }
        if event.kind == "finished" {
            // Calories are from HealthKit's workout builder, not a fabricated estimate.
            if let kcal = event.calories {
                UserDefaults.standard.set(kcal, forKey: "strengthlab.watch.calories.\(event.workoutID)")
            }
            publishWorkouts()
        }
        NotificationCenter.default.post(
            name: .strengthLabWatchEvent, object: nil,
            userInfo: ["event": event]
        )
    }

    private func findSet(_ id: UUID, in context: ModelContext) -> SetDeckSet? {
        let query = FetchDescriptor<SetDeckSet>(predicate: #Predicate { $0.uuid == id })
        return try? context.fetch(query).first
    }

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in self.publishWorkouts() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.publishWorkouts() }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.publishWorkouts() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let event = message["slEvent"] as? Data
        let wantsSnapshot = message["slRequest"] != nil
        Task { @MainActor in
            if let event { self.receive(event) }
            if wantsSnapshot { self.publishWorkouts() }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let data = userInfo["slEvent"] as? Data else { return }
        Task { @MainActor in self.receive(data) }
    }
}
