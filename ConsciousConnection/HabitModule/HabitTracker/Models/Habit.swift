//
//  Habit.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import SwiftData

// MARK: - Habit Type

enum HabitType: String, Codable {
    case manual              // Standard binary habit (done/not done)
    case healthKitSleep      // Auto-sync from HKCategoryType.sleepAnalysis
    case healthKitWater      // Auto-sync from HKQuantityType.dietaryWater
    case healthKitCalories   // Auto-sync from HKQuantityType.dietaryEnergyConsumed
}

// MARK: - Data Source

enum HabitDataSource: String, Codable {
    case manual
    case healthKit
}

// MARK: - Cheat Day Period

enum CheatDayPeriod: String, Codable, CaseIterable, Identifiable {
    case week
    case month

    var id: Self { self }

    var displayName: String {
        switch self {
        case .week: return "Per week"
        case .month: return "Per month"
        }
    }

    var unitName: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        }
    }

    fileprivate var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

// MARK: - Goal Progression

enum GoalProgression: String, Codable, CaseIterable {
    case fixed
    case rampUp
    case adaptive

    var displayName: String {
        switch self {
        case .fixed: return "Fixed"
        case .rampUp: return "Ramp Up"
        case .adaptive: return "Adaptive"
        }
    }

    var description: String {
        switch self {
        case .fixed: return "Goal stays the same"
        case .rampUp: return "Goal increases over time"
        case .adaptive: return "Adjusts based on your performance"
        }
    }

    var icon: String {
        switch self {
        case .fixed: return "equal.circle.fill"
        case .rampUp: return "arrow.up.circle.fill"
        case .adaptive: return "waveform.path.ecg"
        }
    }
}

// MARK: - Habit Model

@Model
class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "checkmark.circle.fill"
    var color: String = "#34C759"
    var createdAt: Date = Date()

    // HealthKit properties
    var habitTypeRaw: String = HabitType.manual.rawValue
    var dataSourceRaw: String = HabitDataSource.manual.rawValue
    var dailyGoal: Double?
    var unit: String?

    // Dynamic Goal properties
    var goalProgressionRaw: String = GoalProgression.fixed.rawValue
    var initialGoal: Double?
    var goalIncrement: Double?
    var goalIncrementIntervalDays: Int?
    var lastGoalAdjustment: Date?
    var restDaysPerWeek: Int?
    var restDays: [Int]? // Days of week (1=Sunday, 7=Saturday)

    // Cheat Day properties
    var cheatDaysAllowed: Int = 0
    var cheatDayPeriodRaw: String = CheatDayPeriod.week.rawValue

    // Stack properties
    var stackId: UUID?
    var stackOrder: Int?

    // Focus Session properties
    var focusEnabled: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]?

    // MARK: - Enum wrappers

    var habitType: HabitType {
        get { HabitType(rawValue: habitTypeRaw) ?? .manual }
        set { habitTypeRaw = newValue.rawValue }
    }

    var dataSource: HabitDataSource {
        get { HabitDataSource(rawValue: dataSourceRaw) ?? .manual }
        set { dataSourceRaw = newValue.rawValue }
    }

    var goalProgression: GoalProgression {
        get { GoalProgression(rawValue: goalProgressionRaw) ?? .fixed }
        set { goalProgressionRaw = newValue.rawValue }
    }

    var cheatDayPeriod: CheatDayPeriod {
        get { CheatDayPeriod(rawValue: cheatDayPeriodRaw) ?? .week }
        set { cheatDayPeriodRaw = newValue.rawValue }
    }

    /// Check if today is a rest day for this habit
    var isRestDayToday: Bool {
        isRestDay(on: Date())
    }

    /// Get the effective daily goal (may be adjusted for ramp-up/adaptive)
    var effectiveDailyGoal: Double? {
        dailyGoal
    }

    init(
        name: String,
        icon: String = "checkmark.circle.fill",
        color: String = "#34C759",
        habitType: HabitType = .manual,
        dataSource: HabitDataSource = .manual,
        dailyGoal: Double? = nil,
        unit: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.completions = []
        self.habitTypeRaw = habitType.rawValue
        self.dataSourceRaw = dataSource.rawValue
        self.dailyGoal = dailyGoal
        self.unit = unit
    }

    // MARK: - Goal Completion Helper

    /// Check if a value meets the goal for this habit type.
    /// For calories, uses a tolerance range (goal - 300 to goal + 200).
    /// For other habits, checks if value >= goal.
    func isGoalMet(value: Double, goal: Double) -> Bool {
        switch habitType {
        case .healthKitCalories:
            let lowerBound = max(0, goal - 300)
            let upperBound = goal + 200
            return value >= lowerBound && value <= upperBound
        default:
            return value >= goal
        }
    }

    // MARK: - Computed Properties

    /// Safe accessor for completions (returns empty array if nil)
    var safeCompletions: [HabitCompletion] {
        completions ?? []
    }

    // MARK: - Date-aware helpers

    func isRestDay(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let restDays = restDays, !restDays.isEmpty else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return restDays.contains(weekday)
    }

    func completion(on date: Date, calendar: Calendar = .current) -> HabitCompletion? {
        safeCompletions.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func value(on date: Date, calendar: Calendar = .current) -> Double? {
        completion(on: date, calendar: calendar)?.value
    }

    func isCheatDay(on date: Date, calendar: Calendar = .current) -> Bool {
        completion(on: date, calendar: calendar)?.isCheatDay == true
    }

    private func isGenuinelyCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let completion = completion(on: date, calendar: calendar),
              !completion.isCheatDay else {
            return false
        }

        if let goal = dailyGoal, let value = completion.value {
            return isGoalMet(value: value, goal: goal)
        }

        return true
    }

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let completion = completion(on: date, calendar: calendar) else {
            return false
        }

        // A cheat day resolves the habit for the day without counting as a
        // genuine completion in streak length or completion-rate analytics.
        if completion.isCheatDay {
            return true
        }

        if let goal = dailyGoal, let value = completion.value {
            return isGoalMet(value: value, goal: goal)
        }

        return true
    }

    func progress(on date: Date, calendar: Calendar = .current) -> Double {
        guard let goal = dailyGoal, goal > 0 else {
            return isCompleted(on: date, calendar: calendar) ? 1.0 : 0.0
        }

        if isCheatDay(on: date, calendar: calendar) {
            return 1.0
        }

        guard let value = value(on: date, calendar: calendar) else {
            return 0.0
        }

        return value / goal
    }

    // MARK: - Cheat Days

    func cheatDaysUsed(
        inPeriodContaining date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard cheatDaysAllowed > 0,
              let interval = calendar.dateInterval(
                of: cheatDayPeriod.calendarComponent,
                for: date
              ) else {
            return 0
        }

        return safeCompletions.filter { completion in
            completion.isCheatDay && interval.contains(completion.date)
        }.count
    }

    func remainingCheatDays(
        inPeriodContaining date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        max(0, cheatDaysAllowed - cheatDaysUsed(inPeriodContaining: date, calendar: calendar))
    }

    func canUseCheatDay(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard cheatDaysAllowed > 0,
              completion(on: date, calendar: calendar) == nil else {
            return false
        }

        return remainingCheatDays(inPeriodContaining: date, calendar: calendar) > 0
    }

    // MARK: - Today wrappers (backwards compatible)

    var todayValue: Double? {
        value(on: Date())
    }

    var todayProgress: Double {
        progress(on: Date())
    }

    var isCompletedToday: Bool {
        isCompleted(on: Date())
    }

    // MARK: - Streaks / Analytics

    private var completedDates: [Date] {
        let calendar = Calendar.current

        return Set(safeCompletions.compactMap { completion -> Date? in
            guard !completion.isCheatDay else { return nil }

            let date = calendar.startOfDay(for: completion.date)

            if let goal = dailyGoal, goal > 0 {
                guard let value = completion.value,
                      isGoalMet(value: value, goal: goal) else {
                    return nil
                }
            }

            return date
        }).sorted()
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let creationDay = calendar.startOfDay(for: createdAt)

        var cursor = today
        var streak = 0
        var hasCountedCompletion = false

        while cursor >= creationDay {
            if isGenuinelyCompleted(on: cursor, calendar: calendar) {
                streak += 1
                hasCountedCompletion = true
            } else if isCheatDay(on: cursor, calendar: calendar) ||
                        isRestDay(on: cursor, calendar: calendar) {
                // Exempt days preserve the chain without increasing its length.
            } else if !hasCountedCompletion && calendar.isDate(cursor, inSameDayAs: today) {
                // Today is still in progress, so yesterday may still continue the streak.
            } else {
                break
            }

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let creationDay = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())

        var cursor = creationDay
        var longest = 0
        var current = 0

        while cursor <= today {
            if isGenuinelyCompleted(on: cursor, calendar: calendar) {
                current += 1
                longest = max(longest, current)
            } else if isCheatDay(on: cursor, calendar: calendar) ||
                        isRestDay(on: cursor, calendar: calendar) {
                // Preserve the current run without adding a completed day.
            } else {
                current = 0
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = nextDay
        }

        return longest
    }

    var completionRate: Double {
        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

        guard daysSinceCreation > 0 else {
            return isGenuinelyCompleted(on: Date(), calendar: calendar) ? 1.0 : 0.0
        }

        return Double(completedDates.count) / Double(daysSinceCreation + 1)
    }
}
