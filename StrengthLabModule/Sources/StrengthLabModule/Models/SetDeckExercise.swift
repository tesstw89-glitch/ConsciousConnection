//
//  SetDeckExercise.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/7/25.
//

import Foundation
import SwiftData

@Model
final class SetDeckExercise {
    var uuid: UUID = UUID()
    var name: String = "New Exercise"
    var note: String?

    /// Optional source/reference video (for example, a YouTube technique video).
    var videoURL: URL?

    /// Local master video imported from the source URL.
    /// StrengthLab keeps this so a generated GIF can be
    /// re-edited later without degrading the previous GIF.
    var importedVideoURL: URL?

    /// Optional lightweight animated demo shown directly inside the workout card.
    /// Keep this remote rather than bundling hundreds of GIFs into the app.
    var gifURL: URL?

    /// Original GIF before StrengthLab creates an edited local copy.
    /// This lets the user re-edit or restore the source later.
    var gifSourceURL: URL?

    /// Output frame rate used for the current edited GIF.
    var gifEditedFPS: Double?

    /// Maximum output width used for the current edited GIF.
    /// nil means original dimensions.
    var gifEditedMaxWidth: Int?

    // Optional non-destructive crop for animated GIF playback.
    // Times are measured in seconds from the original asset.
    var gifTrimStart: Double? = nil
    var gifTrimEnd: Double? = nil

    // Optional non-destructive crop for directly playable video.
    var videoTrimStart: Double? = nil
    var videoTrimEnd: Double? = nil

    /// Exercises sharing this UUID belong to the same superset/triset.
    var supersetGroupID: UUID?

    var isWarmup: Bool = false

    var muscleGroups: [MuscleGroup] = []
    var equipment: String?
    var orderIndex: Int = 0

    // One-to-many: Exercise → Sets (no inverse here; inverse on SetDeckSet.exercise)
    @Relationship(deleteRule: .cascade)
    var sets: [SetDeckSet]?

    // Many-to-one: Exercise → Routine (no inverse here; inverse declared on Routine.exercises)
    @Relationship(deleteRule: .nullify)
    var routine: SetDeckRoutine?

    init(uuid: UUID = UUID(),
         name: String,
         note: String? = nil,
         videoURL: URL? = nil,
         importedVideoURL: URL? = nil,
         gifURL: URL? = nil,
         gifSourceURL: URL? = nil,
         gifEditedFPS: Double? = nil,
         gifEditedMaxWidth: Int? = nil,
         gifTrimStart: Double? = nil,
         gifTrimEnd: Double? = nil,
         videoTrimStart: Double? = nil,
         videoTrimEnd: Double? = nil,
         supersetGroupID: UUID? = nil,
         isWarmup: Bool = false,
         muscleGroups: [MuscleGroup] = [],
         equipment: String? = nil,
         orderIndex: Int = 0) {
        self.uuid = uuid
        self.name = name
        self.note = note
        self.videoURL = videoURL
        self.importedVideoURL = importedVideoURL
        self.gifURL = gifURL
        self.gifSourceURL = gifSourceURL
        self.gifEditedFPS = gifEditedFPS
        self.gifEditedMaxWidth = gifEditedMaxWidth
        self.gifTrimStart = gifTrimStart
        self.gifTrimEnd = gifTrimEnd
        self.videoTrimStart = videoTrimStart
        self.videoTrimEnd = videoTrimEnd
        self.supersetGroupID = supersetGroupID
        self.isWarmup = isWarmup
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.orderIndex = orderIndex
    }
}

extension SetDeckExercise {
    /// A single randomized sample exercise for testing and previews
    static func sample(seed: UInt64? = nil, name: String? = nil, setCount: Int = 3) -> SetDeckExercise {
        var rng = seed.map { SeededRandomNumberGenerator(seed: $0) }
        func randInt(_ range: ClosedRange<Int>) -> Int {
            if var g = rng { let v = Int.random(in: range, using: &g); rng = g; return v }
            return Int.random(in: range)
        }
        func randBool() -> Bool {
            if var g = rng { let v = Bool.random(using: &g); rng = g; return v }
            return Bool.random()
        }

        let exerciseName: String = name ?? {
            let options = ["Bench Press", "Squat", "Deadlift", "Overhead Press", "Pull-Up", "Row", "Lunge", "Dip"]
            if var g = rng, let s = options.randomElement(using: &g) { rng = g; return s }
            return options.randomElement() ?? "Exercise"
        }()

        let ex = SetDeckExercise(
            name: exerciseName,
            note: randBool() ? "Focus on form" : nil,
            videoURL: nil,
            gifURL: nil,
            supersetGroupID: nil,
            isWarmup: randBool(),
            muscleGroups: [],
            equipment: randBool() ? "Barbell" : nil,
            orderIndex: randInt(0...10)
        )

        // Generate sample sets and assign back-references
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        let count = max(1, setCount)
        let generatedSets = (0..<count).map { i -> SetDeckSet in
            let set = SetDeckSet.sample(seed: baseSeed &+ UInt64(i))
            set.exercise = ex
            return set
        }.sorted { ($0.orderIndex) < ($1.orderIndex) }

        ex.sets = generatedSets
        return ex
    }

    /// Generate multiple randomized sample exercises
    static func samples(_ count: Int, seed: UInt64? = nil, setCount: Int = 3) -> [SetDeckExercise] {
        let baseSeed = seed ?? UInt64.random(in: .min ... .max)
        return (0..<count).map { i in
            SetDeckExercise.sample(seed: baseSeed &+ UInt64(i), setCount: setCount)
        }
    }
}

// STRENGTHLAB_NOV03_EMBEDDED_EXERCISE_PREFS
/// Preferences are keyed by the EXERCISE name, so they survive across saved
/// workout templates. Supersets and single-set exercises are deliberately excluded.
@MainActor
enum StrengthLabExercisePreferences {
    private static let storageKey = "strengthlab_exercise_metrics_v1"

    private struct Values: Codable {
        var reps: Int?
        var weight: Double?
        var rest: Int?
    }

    enum Change {
        case reps(Int)
        case weight(Double)
        case rest(Int)
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func qualifies(_ exercise: SetDeckExercise) -> Bool {
        exercise.supersetGroupID == nil && (exercise.sets ?? []).count > 1
    }

    private static func read() -> [String: Values] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [:] }
        return (try? JSONDecoder().decode([String: Values].self, from: data)) ?? [:]
    }

    private static func apply(_ change: Change, to exercise: SetDeckExercise) {
        for set in exercise.sets ?? [] {
            switch change {
            case .reps(let reps):
                // Leave timed and freeform exercises alone.
                if set.setType == .reps || set.setType == .amap {
                    set.targetReps = reps
                }
            case .weight(let weight):
                if set.setType == .reps || set.setType == .amap {
                    set.weight = weight
                }
            case .rest(let seconds):
                set.restTimeInSeconds = seconds > 0 ? seconds : nil
            }
        }
    }

    static func change(_ change: Change, for exercise: SetDeckExercise, in context: ModelContext) {
        guard qualifies(exercise) else { return }
        let key = normalized(exercise.name)
        guard !key.isEmpty else { return }

        var settings = read()
        var values = settings[key] ?? Values()
        switch change {
        case .reps(let reps): values.reps = reps
        case .weight(let weight): values.weight = weight
        case .rest(let seconds): values.rest = seconds
        }
        settings[key] = values
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }

        // Update every occurrence of this ordinary exercise in the user's
        // existing templates. The updated set models are persisted by SwiftData.
        let all = (try? context.fetch(FetchDescriptor<SetDeckExercise>())) ?? []
        for item in all where qualifies(item) && normalized(item.name) == key {
            apply(change, to: item)
        }
        // Also handle a newly created exercise not yet included in a fetch.
        apply(change, to: exercise)
        try? context.save()
    }

    static func applySaved(to workout: WorkoutTemplate, in context: ModelContext) {
        let settings = read()
        guard !settings.isEmpty else { return }
        for exercise in workout.exercises ?? [] where qualifies(exercise) {
            guard let value = settings[normalized(exercise.name)] else { continue }
            if let reps = value.reps { apply(.reps(reps), to: exercise) }
            if let weight = value.weight { apply(.weight(weight), to: exercise) }
            if let rest = value.rest { apply(.rest(rest), to: exercise) }
        }
        try? context.save()
    }
}
