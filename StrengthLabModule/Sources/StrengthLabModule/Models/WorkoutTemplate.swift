import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var uuid: UUID = UUID()
    var name: String = "New Workout"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade)
    var exercises: [SetDeckExercise]?

    @Relationship(deleteRule: .cascade)
    var schedules: [WorkoutSchedule]?

    init(
        uuid: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.exercises = []
        self.schedules = []
    }
}

extension WorkoutTemplate: Identifiable {
    var id: UUID { uuid }
}


@Model
final class WorkoutSchedule {
    var uuid: UUID = UUID()

    /// The selected calendar date.
    /// When repeatsWeekly == true, only its weekday is significant.
    var scheduledDate: Date = Date()

    var repeatsWeekly: Bool = false

    @Relationship(inverse: \WorkoutTemplate.schedules)
    var workout: WorkoutTemplate?

    init(
        uuid: UUID = UUID(),
        scheduledDate: Date,
        repeatsWeekly: Bool,
        workout: WorkoutTemplate? = nil
    ) {
        self.uuid = uuid
        self.scheduledDate = scheduledDate
        self.repeatsWeekly = repeatsWeekly
        self.workout = workout
    }

    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current

        if repeatsWeekly {
            return calendar.component(
                .weekday,
                from: scheduledDate
            ) == calendar.component(
                .weekday,
                from: date
            )
        }

        return calendar.isDate(
            scheduledDate,
            inSameDayAs: date
        )
    }
}
