//
//  ConsciousConnectionTests.swift
//  ConsciousConnectionTests
//

import Foundation
import Testing
@testable import ConsciousConnection

struct ConsciousConnectionTests {
    @Test @MainActor
    func workoutWeeklyGoalCountsSeveralCheckoffsAndResetsOnMonday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2 // Monday

        let friday = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 12)))
        let followingMonday = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 12)))

        let workout = Habit(name: "Workout", weeklyTarget: 4)
        workout.completions = (8...11).compactMap { hour in
            calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: hour))
                .map { HabitCompletion(date: $0) }
        }

        #expect(workout.weeklyProgress(on: friday, calendar: calendar) == 4)
        #expect(workout.isCompleted(on: friday, calendar: calendar))
        #expect(workout.weeklyProgress(on: followingMonday, calendar: calendar) == 0)
        #expect(!workout.isCompleted(on: followingMonday, calendar: calendar))
    }

    @Test @MainActor
    func nonWeeklyHabitsRetainDailyBehaviour() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let friday = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 12)))
        let saturday = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 12)))

        let daily = Habit(name: "Read")
        daily.completions = [HabitCompletion(date: friday)]

        #expect(daily.isCompleted(on: friday, calendar: calendar))
        #expect(!daily.isCompleted(on: saturday, calendar: calendar))
    }
}
