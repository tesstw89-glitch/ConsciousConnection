import Foundation
import Combine
import HealthKit
import WatchConnectivity
import WatchKit

@MainActor
final class SLWatchController: NSObject, ObservableObject, WCSessionDelegate {
    @Published var snapshot: SLWatchSnapshot?
    @Published var activeWorkoutID: UUID?
    @Published var currentSetID: UUID?
    @Published var completedSetIDs: Set<UUID> = []
    @Published var restEnd: Date?
    @Published var timedEnd: Date?
    @Published var timedRemaining: Int = 0
    @Published var finishedName: String?
    @Published var calories: Double?
    @Published var errorMessage: String?
    @Published var phoneReachable = false

    private var wc: WCSession?
    private let health = SLWatchHealth()
    private let cacheKey = "strengthlab.watch.snapshot.v1"
    private let progressKey = "strengthlab.watch.progress.v1"
    private let pendingKey = "strengthlab.watch.pendingEvents.v1"
    private var pendingEvents: [SLWatchEvent] = []
    private var startedAt: Date?

    private struct SavedProgress: Codable {
        var workoutID: UUID
        var currentSetID: UUID?
        var completedIDs: [UUID]
    }

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: cacheKey) {
            snapshot = try? JSONDecoder().decode(SLWatchSnapshot.self, from: data)
        }
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let saved = try? JSONDecoder().decode(SavedProgress.self, from: data) {
            activeWorkoutID = saved.workoutID
            currentSetID = saved.currentSetID
            completedSetIDs = Set(saved.completedIDs)
        }
        if let data = UserDefaults.standard.data(forKey: pendingKey) {
            pendingEvents = (try? JSONDecoder().decode([SLWatchEvent].self, from: data)) ?? []
        }
    }

    var activeWorkout: SLWatchWorkout? {
        snapshot?.workouts.first(where: { $0.id == activeWorkoutID })
    }

    var current: (exercise: SLWatchExercise, set: SLWatchSet, index: Int, total: Int)? {
        guard let workout = activeWorkout else { return nil }
        for exercise in workout.exercises {
            let sets = exercise.sets
            if let i = sets.firstIndex(where: { $0.id == currentSetID }) {
                return (exercise, sets[i], i + 1, sets.count)
            }
        }
        return nil
    }

    var totalSets: Int { activeWorkout?.exercises.reduce(0) { $0 + $1.sets.count } ?? 0 }
    var allCompleted: Bool { activeWorkout != nil && totalSets > 0 && completedSetIDs.count >= totalSets }

    func activate() {
        guard WCSession.isSupported() else { return }
        wc = WCSession.default
        wc?.delegate = self
        wc?.activate()
        if let data = wc?.receivedApplicationContext["slSnapshot"] as? Data {
            decodeSnapshot(data)
        }
        requestSnapshot()
    }

    func requestSnapshot() {
        guard let wc, wc.isReachable else { return }
        wc.sendMessage(["slRequest": true], replyHandler: nil, errorHandler: nil)
    }

    private func decodeSnapshot(_ data: Data) {
        guard let value = try? JSONDecoder().decode(SLWatchSnapshot.self, from: data) else { return }
        snapshot = value
        UserDefaults.standard.set(data, forKey: cacheKey)
        // Preserve the workout currently in progress when a refreshed programme arrives.
        if let id = activeWorkoutID,
           !value.workouts.contains(where: { $0.id == id }) {
            // Do not erase offline progress when the active phone programme changes.
            errorMessage = "Open the same programme on your iPhone to finish syncing."
        }
    }

    func start(_ workout: SLWatchWorkout, fromPhone: Bool = false) async {
        guard activeWorkoutID == nil else { return }
        errorMessage = nil
        finishedName = nil
        calories = nil
        do {
            try await health.start()
        } catch {
            errorMessage = "Couldn't start Apple Health workout: \(error.localizedDescription)"
            return
        }
        activeWorkoutID = workout.id
        startedAt = Date()
        completedSetIDs.removeAll()
        currentSetID = workout.exercises.flatMap(\.sets).first?.id
        restEnd = nil
        timedEnd = nil
        persist()
        if !fromPhone { emit(kind: "started", workoutID: workout.id) }
    }

    func move(to setID: UUID, fromPhone: Bool = false) {
        guard let id = activeWorkoutID else { return }
        currentSetID = setID
        timedEnd = nil
        restEnd = nil
        persist()
        if !fromPhone { emit(kind: "navigated", workoutID: id, setID: setID) }
    }

    func updateCurrent(reps: Int?, weight: Double?, duration: Double? = nil) {
        guard let id = activeWorkoutID, let setID = currentSetID,
              var value = snapshot else { return }
        for i in value.workouts.indices where value.workouts[i].id == id {
            for j in value.workouts[i].exercises.indices {
                if let k = value.workouts[i].exercises[j].sets.firstIndex(where: { $0.id == setID }) {
                    if let reps { value.workouts[i].exercises[j].sets[k].reps = reps }
                    if let weight { value.workouts[i].exercises[j].sets[k].weight = weight }
                    if let duration { value.workouts[i].exercises[j].sets[k].duration = duration }
                }
            }
        }
        snapshot = value
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
        emit(kind: "adjusted", workoutID: id, setID: setID,
             reps: reps, weight: weight, duration: duration)
    }

    func complete(reps: Int?, weight: Double?) {
        guard let workout = activeWorkout, let setID = currentSetID else { return }
        if completedSetIDs.contains(setID) { return }
        let all = workout.exercises.flatMap(\.sets)
        guard let index = all.firstIndex(where: { $0.id == setID }) else { return }
        completedSetIDs.insert(setID)
        emit(kind: "completed", workoutID: workout.id, setID: setID,
             reps: reps, weight: weight, duration: all[index].duration)
        if index + 1 < all.count {
            currentSetID = all[index + 1].id
            emit(kind: "navigated", workoutID: workout.id, setID: all[index + 1].id)
            if all[index].rest > 0 {
                restEnd = Date().addingTimeInterval(Double(all[index].rest))
            }
        } else {
            currentSetID = nil
            restEnd = nil
        }
        timedEnd = nil
        persist()
        WKInterfaceDevice.current().play(.success)
    }

    func startOrPauseTimedSet() {
        guard let current else { return }
        if let end = timedEnd {
            timedRemaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            timedEnd = nil
        } else {
            let duration = timedRemaining > 0 ? timedRemaining : max(1, Int(current.set.duration ?? 30))
            timedRemaining = duration
            timedEnd = Date().addingTimeInterval(TimeInterval(duration))
        }
    }

    func tick() {
        if let end = timedEnd {
            timedRemaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if timedRemaining == 0 {
                timedEnd = nil
                WKInterfaceDevice.current().play(.success)
            }
        }
        if let restEnd, restEnd <= Date() {
            self.restEnd = nil
            WKInterfaceDevice.current().play(.notification)
        }
    }

    func finish(fromPhone: Bool = false) async {
        guard let workout = activeWorkout else { return }
        let kcal = await health.finish()
        calories = kcal
        finishedName = workout.name
        if !fromPhone {
            emit(kind: "finished", workoutID: workout.id, calories: kcal, startedAt: startedAt)
        }
        activeWorkoutID = nil
        startedAt = nil
        currentSetID = nil
        completedSetIDs.removeAll()
        timedEnd = nil
        restEnd = nil
        UserDefaults.standard.removeObject(forKey: progressKey)
    }

    private func persist() {
        guard let id = activeWorkoutID else {
            UserDefaults.standard.removeObject(forKey: progressKey)
            return
        }
        let data = SavedProgress(workoutID: id, currentSetID: currentSetID,
                                 completedIDs: Array(completedSetIDs))
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }

    private func emit(kind: String, workoutID: UUID, setID: UUID? = nil,
                      reps: Int? = nil, weight: Double? = nil,
                      duration: Double? = nil, calories: Double? = nil,
                      startedAt: Date? = nil) {
        let event = SLWatchEvent(id: UUID(), kind: kind, workoutID: workoutID, setID: setID,
                                 reps: reps, weight: weight, duration: duration,
                                 calories: calories, when: Date(), startedAt: startedAt)
        guard let wc, wc.activationState == .activated else {
            pendingEvents.append(event)
            savePending()
            return
        }
        send(event, via: wc)
    }

    private func send(_ event: SLWatchEvent, via wc: WCSession) {
        guard let encoded = try? JSONEncoder().encode(event) else { return }
        // Important updates are queued for eventual delivery even with the phone away.
        if ["completed", "finished", "started", "adjusted"].contains(event.kind) {
            wc.transferUserInfo(["slEvent": encoded])
        }
        if wc.isReachable {
            wc.sendMessage(["slEvent": encoded], replyHandler: nil, errorHandler: nil)
        }
    }

    private func savePending() {
        if let data = try? JSONEncoder().encode(pendingEvents) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    private func flushPending() {
        guard let wc, wc.activationState == .activated else { return }
        for event in pendingEvents { send(event, via: wc) }
        pendingEvents.removeAll()
        savePending()
    }

    private func receive(_ event: SLWatchEvent) {
        if event.kind == "started", activeWorkoutID == nil,
           let workout = snapshot?.workouts.first(where: { $0.id == event.workoutID }) {
            Task { await start(workout, fromPhone: true) }
        }
        if event.kind == "navigated", activeWorkoutID == event.workoutID,
           let setID = event.setID { move(to: setID, fromPhone: true) }
        if event.kind == "completed", activeWorkoutID == event.workoutID,
           let setID = event.setID {
            completedSetIDs.insert(setID)
            if currentSetID == setID {
                let sets = activeWorkout?.exercises.flatMap(\.sets) ?? []
                if let i = sets.firstIndex(where: { $0.id == setID }) {
                    currentSetID = i + 1 < sets.count ? sets[i + 1].id : nil
                }
            }
            persist()
        }
        if event.kind == "finished", activeWorkoutID == event.workoutID {
            Task { await finish(fromPhone: true) }
        }
    }

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.phoneReachable = reachable
            self.flushPending()
            self.requestSnapshot()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.phoneReachable = reachable
            if reachable { self.requestSnapshot(); self.flushPending() }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let snap = message["slSnapshot"] as? Data
        let eventData = message["slEvent"] as? Data
        Task { @MainActor in
            if let snap { self.decodeSnapshot(snap) }
            if let eventData, let event = try? JSONDecoder().decode(SLWatchEvent.self, from: eventData) {
                self.receive(event)
            }
        }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        guard let data = context["slSnapshot"] as? Data else { return }
        Task { @MainActor in self.decodeSnapshot(data) }
    }
}

// Owns the HealthKit session, so users do NOT need to open Apple's Workout app.
@MainActor
final class SLWatchHealth {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func start() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "ConsciousConnectionWatch", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "HealthKit is unavailable."])
        }
        guard session == nil else { return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        try await store.requestAuthorization(toShare: share, read: read)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        let workoutSession = try HKWorkoutSession(healthStore: store, configuration: configuration)
        let workoutBuilder = workoutSession.associatedWorkoutBuilder()
        workoutBuilder.dataSource = HKLiveWorkoutDataSource(
            healthStore: store, workoutConfiguration: configuration
        )
        let date = Date()
        workoutSession.startActivity(with: date)
        do {
            try await workoutBuilder.beginCollection(at: date)
        } catch {
            workoutSession.end()
            throw error
        }
        self.session = workoutSession
        self.builder = workoutBuilder
    }

    func finish() async -> Double? {
        guard let session, let builder else { return nil }
        let end = Date()
        session.end()
        var calories: Double?
        do {
            try await builder.endCollection(at: end)
            let saved = try await builder.finishWorkout()
            calories = saved?.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        } catch {
            // Don't claim HealthKit saved a workout if its builder failed.
            print("HealthKit workout finish failed: \(error.localizedDescription)")
        }
        self.session = nil
        self.builder = nil
        return calories
    }
}
