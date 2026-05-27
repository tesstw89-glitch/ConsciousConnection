import Foundation

enum WorkoutMetric: String, Codable, Hashable, CaseIterable {
    case reps
    case seconds

    var unitLabel: String {
        switch self {
        case .reps: return "reps"
        case .seconds: return "sec"
        }
    }

    var stepSize: Int {
        switch self {
        case .reps: return 1
        case .seconds: return 5
        }
    }
}

struct WorkoutSetTemplate: Hashable, Identifiable {
    let id = UUID()
    let targetText: String
    let defaultValue: Int
    let metric: WorkoutMetric
    let restSeconds: Int
}

struct WorkoutExercise: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let detail: String?
    let videoFileName: String?
    let sets: [WorkoutSetTemplate]
}

struct WorkoutBlock: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let note: String?
    let exercises: [WorkoutExercise]
}

enum WorkoutDay: String, Codable, Hashable, CaseIterable {
    case mondayRest
    case tuesdayPullUpAbs
    case wednesdayDipGlutes
    case thursdayEasyPullAbs
    case fridayRest
    case saturdayDipGlutes
    case sundayHardAbs

    var title: String {
        switch self {
        case .mondayRest: return "Monday — No programmed workout"
        case .tuesdayPullUpAbs: return "Tuesday — Pull-up day + lighter plate abs"
        case .wednesdayDipGlutes: return "Wednesday — Dip day + glutes"
        case .thursdayEasyPullAbs: return "Thursday — Easier pull-up day + lighter dip bar abs"
        case .fridayRest: return "Friday — Rest"
        case .saturdayDipGlutes: return "Saturday — Dip day + glutes"
        case .sundayHardAbs: return "Sunday — Harder dip bar abs day"
        }
    }

    var shortTitle: String {
        switch self {
        case .mondayRest: return "Monday"
        case .tuesdayPullUpAbs: return "Tuesday"
        case .wednesdayDipGlutes: return "Wednesday"
        case .thursdayEasyPullAbs: return "Thursday"
        case .fridayRest: return "Friday"
        case .saturdayDipGlutes: return "Saturday"
        case .sundayHardAbs: return "Sunday"
        }
    }

    var isRestDay: Bool {
        switch self {
        case .mondayRest, .fridayRest:
            return true
        default:
            return false
        }
    }
}

enum WorkoutPlanner {
    static func today(from date: Date = Date()) -> WorkoutDay {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch weekday {
        case 2: return .mondayRest
        case 3: return .tuesdayPullUpAbs
        case 4: return .wednesdayDipGlutes
        case 5: return .thursdayEasyPullAbs
        case 6: return .fridayRest
        case 7: return .saturdayDipGlutes
        case 1: return .sundayHardAbs
        default: return .mondayRest
        }
    }
}

enum WorkoutPlanLibrary {
    static func blocks(for day: WorkoutDay) -> [WorkoutBlock] {
        switch day {

        case .mondayRest, .fridayRest:
            return []

        case .tuesdayPullUpAbs:
            return [
                WorkoutBlock(
                    title: "Assisted pull-ups",
                    note: "4 x 3 slow reps. Rest 90–120 sec.",
                    exercises: [
                        WorkoutExercise(
                            title: "Band Assisted Pull-ups",
                            detail: "Use the band where you managed the 4 x 3. Controlled reps. No bouncing.",
                            videoFileName: "Band Assisted Pull ups",
                            sets: repeatedSets(count: 4, targetText: "3 reps", defaultValue: 3, metric: .reps, restSeconds: 90)
                        )
                    ]
                ),
                WorkoutBlock(
                    title: "Plate ab finisher",
                    note: "2 rounds. Rest 1 min between rounds.",
                    exercises: [
                        WorkoutExercise(
                            title: "Dead bugs",
                            detail: nil,
                            videoFileName: "Plate Dead bugs.mp4",
                            sets: repeatedSets(count: 2, targetText: "20 reps", defaultValue: 20, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Overhead sit-ups",
                            detail: nil,
                            videoFileName: "Overhead sit-ups.mp4",
                            sets: repeatedSets(count: 2, targetText: "10 reps", defaultValue: 10, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Toe touches",
                            detail: nil,
                            videoFileName: "Toe Touches.mp4",
                            sets: repeatedSets(count: 2, targetText: "15 reps", defaultValue: 15, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Russian twists",
                            detail: "16 total",
                            videoFileName: "Russian Twists.mp4",
                            sets: repeatedSets(count: 2, targetText: "16 reps", defaultValue: 16, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Overhead hold",
                            detail: nil,
                            videoFileName: "Overhead Hold.mp4",
                            sets: repeatedSets(count: 2, targetText: "30 sec", defaultValue: 30, metric: .seconds, restSeconds: 60)
                        )
                    ]
                )
            ]

        case .wednesdayDipGlutes:
            return [
                WorkoutBlock(
                    title: "Assisted dips",
                    note: "5 x 5. Rest 90–120 sec.",
                    exercises: [
                        WorkoutExercise(
                            title: "Band Assisted Dips",
                            detail: "Use a band that lets the reps stay smooth.",
                            videoFileName: "Band Assisted Dips",
                            sets: repeatedSets(count: 5, targetText: "5 reps", defaultValue: 5, metric: .reps, restSeconds: 90)
                        )
                    ]
                ),
                WorkoutBlock(
                    title: "Glute circuit",
                    note: "2 sets. As little rest as needed between exercises, then 60–90 sec between rounds.",
                    exercises: [
                        WorkoutExercise(
                            title: "Crab Walk",
                            detail: "10 steps each direction",
                            videoFileName: "Crab-walk.mp4",
                            sets: repeatedSets(count: 2, targetText: "10 each way", defaultValue: 10, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Banded Hip Extensions",
                            detail: "12 each leg",
                            videoFileName: "Standing-Banded-Hip-Extension.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each leg", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Banded Hip Abductions",
                            detail: "15 each leg",
                            videoFileName: "Banded-Hip-Abduction.mp4",
                            sets: repeatedSets(count: 2, targetText: "15 each leg", defaultValue: 15, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Clamshells",
                            detail: "12 each side",
                            videoFileName: "Banded-Clamshells.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each side", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Donkey Kicks",
                            detail: "12 each leg",
                            videoFileName: "Banded-donkey-kicks.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each leg", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Fire Hydrants",
                            detail: "10 each side",
                            videoFileName: "Banded-Fire-Hydrants.mp4",
                            sets: repeatedSets(count: 2, targetText: "10 each side", defaultValue: 10, metric: .reps, restSeconds: 60)
                        )
                    ]
                )
            ]

        case .thursdayEasyPullAbs:
            return [
                WorkoutBlock(
                    title: "Assisted pull-ups",
                    note: "Default below uses Option A: 4 x 3 with a heavier band. Rest 90 sec.",
                    exercises: [
                        WorkoutExercise(
                            title: "Band Assisted Pull-ups",
                            detail: "Option A: 4 x 3 with a heavier band. Option B: 3 x 3 with the same band.",
                            videoFileName: "Band Assisted Pull ups",
                            sets: repeatedSets(count: 4, targetText: "3 reps", defaultValue: 3, metric: .reps, restSeconds: 90)
                        )
                    ]
                ),
                WorkoutBlock(
                    title: "Dip bar abs",
                    note: "2 rounds to start. Build to 3 rounds once it feels good. Rest 1 min between rounds.",
                    exercises: [
                        WorkoutExercise(
                            title: "Knee raises",
                            detail: "20 reps",
                            videoFileName: "Dip Bar Knee Ups",
                            sets: repeatedSets(count: 2, targetText: "20 reps", defaultValue: 20, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Alternating knee raises",
                            detail: "10 each way",
                            videoFileName: "Dip Bar Alternating Knee Ups",
                            sets: repeatedSets(count: 2, targetText: "10 each way", defaultValue: 10, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Alternating side kick outs",
                            detail: "6 each way",
                            videoFileName: "Dip Bar Kickouts",
                            sets: repeatedSets(count: 2, targetText: "6 each way", defaultValue: 6, metric: .reps, restSeconds: 60)
                        )
                    ]
                )
            ]

        case .saturdayDipGlutes:
            return [
                WorkoutBlock(
                    title: "Assisted dips",
                    note: "4 x 6–8. Rest 90 sec.",
                    exercises: [
                        WorkoutExercise(
                            title: "Band Assisted Dips",
                            detail: "Slightly easier / more volume-focused dip day.",
                            videoFileName: "Band Assisted Dips",
                            sets: repeatedSets(count: 4, targetText: "6–8 reps", defaultValue: 6, metric: .reps, restSeconds: 90)
                        )
                    ]
                ),
                WorkoutBlock(
                    title: "Glute circuit",
                    note: "2 sets. As little rest as needed between exercises, then 60–90 sec between rounds.",
                    exercises: [
                        WorkoutExercise(
                            title: "Crab Walk",
                            detail: "10 steps each direction",
                            videoFileName: "Crab-walk.mp4",
                            sets: repeatedSets(count: 2, targetText: "10 each way", defaultValue: 10, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Banded Hip Extensions",
                            detail: "12 each leg",
                            videoFileName: "Standing-Banded-Hip-Extension.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each leg", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Banded Hip Abductions",
                            detail: "15 each leg",
                            videoFileName: "Banded-Hip-Abduction.mp4",
                            sets: repeatedSets(count: 2, targetText: "15 each leg", defaultValue: 15, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Clamshells",
                            detail: "12 each side",
                            videoFileName: "Banded-Clamshells.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each side", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Donkey Kicks",
                            detail: "12 each leg",
                            videoFileName: "Banded-donkey-kicks.mp4",
                            sets: repeatedSets(count: 2, targetText: "12 each leg", defaultValue: 12, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Fire Hydrants",
                            detail: "10 each side",
                            videoFileName: "Banded-Fire-Hydrants.mp4",
                            sets: repeatedSets(count: 2, targetText: "10 each side", defaultValue: 10, metric: .reps, restSeconds: 60)
                        )
                    ]
                )
            ]

        case .sundayHardAbs:
            return [
                WorkoutBlock(
                    title: "Dip bar abs",
                    note: "4 rounds. If 4 rounds is too much at first, start with 3 and build up. Rest 1 min between rounds.",
                    exercises: [
                        WorkoutExercise(
                            title: "Knee raises",
                            detail: "20 reps",
                            videoFileName: "Dip Bar Knee Ups",
                            sets: repeatedSets(count: 4, targetText: "20 reps", defaultValue: 20, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Alternating knee raises",
                            detail: "10 each way",
                            videoFileName: "Dip Bar Alternating Knee Ups",
                            sets: repeatedSets(count: 4, targetText: "10 each way", defaultValue: 10, metric: .reps, restSeconds: 60)
                        ),
                        WorkoutExercise(
                            title: "Alternating side kick outs",
                            detail: "6 each way",
                            videoFileName: "Dip Bar Kickouts",
                            sets: repeatedSets(count: 4, targetText: "6 each way", defaultValue: 6, metric: .reps, restSeconds: 60)
                        )
                    ]
                )
            ]
        }
    }

    static func sessionBlocks(for day: WorkoutDay) -> [WorkoutBlockSessionState] {
        blocks(for: day).map { block in
            WorkoutBlockSessionState(
                title: block.title,
                note: block.note,
                exercises: block.exercises.map { exercise in
                    WorkoutExerciseSessionState(
                        title: exercise.title,
                        detail: exercise.detail,
                        videoFileName: exercise.videoFileName,
                        skipped: false,
                        sets: exercise.sets.map {
                            WorkoutSetSessionState(
                                targetText: $0.targetText,
                                metric: $0.metric,
                                restSeconds: $0.restSeconds,
                                actualValue: $0.defaultValue,
                                completed: false,
                                skipped: false
                            )
                        }
                    )
                }
            )
        }
    }

    static func sessionBlocks(from template: WorkoutTemplateModel) -> [WorkoutBlockSessionState] {
        template.blocks.map { block in
            WorkoutBlockSessionState(
                title: block.title,
                note: block.note.isEmpty ? nil : block.note,
                exercises: block.exercises.map { exercise in
                    WorkoutExerciseSessionState(
                        title: exercise.title,
                        detail: exercise.detail.isEmpty ? nil : exercise.detail,
                        videoFileName: exercise.videoFileName.isEmpty ? nil : exercise.videoFileName,
                        skipped: false,
                        sets: (0..<exercise.setCount).map { _ in
                            WorkoutSetSessionState(
                                targetText: exercise.targetText,
                                metric: exercise.metric,
                                restSeconds: exercise.restSeconds,
                                actualValue: exercise.defaultValue,
                                completed: false,
                                skipped: false
                            )
                        }
                    )
                }
            )
        }
    }

    private static func repeatedSets(
        count: Int,
        targetText: String,
        defaultValue: Int,
        metric: WorkoutMetric,
        restSeconds: Int
    ) -> [WorkoutSetTemplate] {
        (0..<count).map { _ in
            WorkoutSetTemplate(
                targetText: targetText,
                defaultValue: defaultValue,
                metric: metric,
                restSeconds: restSeconds
            )
        }
    }
}

struct WorkoutSetSessionState: Identifiable, Hashable {
    let id = UUID()
    let targetText: String
    let metric: WorkoutMetric
    let restSeconds: Int
    var actualValue: Int
    var completed: Bool
    var skipped: Bool
}

struct WorkoutExerciseSessionState: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String?
    let videoFileName: String?
    var skipped: Bool
    var sets: [WorkoutSetSessionState]
}

struct WorkoutBlockSessionState: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let note: String?
    var exercises: [WorkoutExerciseSessionState]
}

struct WorkoutSetLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var targetText: String
    var metric: WorkoutMetric
    var actualValue: Int
    var completed: Bool
    var skipped: Bool
}

struct WorkoutExerciseLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var skipped: Bool
    var sets: [WorkoutSetLog]
}

struct WorkoutBlockLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var exercises: [WorkoutExerciseLog]
}

struct WorkoutTemplateExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var detail: String
    var videoFileName: String
    var setCount: Int
    var targetText: String
    var defaultValue: Int
    var metric: WorkoutMetric
    var restSeconds: Int
}

struct WorkoutTemplateBlock: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var note: String
    var exercises: [WorkoutTemplateExercise]
}

struct WorkoutTemplateModel: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var blocks: [WorkoutTemplateBlock]

    var exerciseCount: Int {
        blocks.flatMap(\.exercises).count
    }
}

struct WorkoutLogEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var scheduledDay: WorkoutDay?
    var customTitle: String?
    var endedEarly: Bool
    var blocks: [WorkoutBlockLog]

    var displayTitle: String {
        customTitle ?? scheduledDay?.title ?? "Workout"
    }

    var completedSetCount: Int {
        blocks.flatMap(\.exercises).flatMap(\.sets).filter(\.completed).count
    }

    var skippedSetCount: Int {
        blocks.flatMap(\.exercises).flatMap(\.sets).filter(\.skipped).count
    }

    var skippedExerciseCount: Int {
        blocks.flatMap(\.exercises).filter(\.skipped).count
    }

    var exerciseCount: Int {
        blocks.flatMap(\.exercises).count
    }
}
