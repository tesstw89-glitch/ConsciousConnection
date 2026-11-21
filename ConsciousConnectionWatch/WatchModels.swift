import Foundation

// Identical JSON fields to the iPhone's StrengthLabWatchPhoneBridge.
// No SwiftData, iOS framework, or shared app database on the watch.
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
    var kind: String
    var workoutID: UUID
    var setID: UUID?
    var reps: Int?
    var weight: Double?
    var duration: Double?
    var calories: Double?
    var when: Date
}
