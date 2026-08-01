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

    func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let completion = completion(on: date, calendar: calendar) else {
            return false
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

        guard let value = value(on: date, calendar: calendar) else {
            return 0.0
        }

        return value / goal
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
        let completedDatesDescending = completedDates.sorted(by: >)

        guard !completedDatesDescending.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        if !isCompletedToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                return 0
            }
            expectedDate = yesterday
        }

        for date in completedDatesDescending {
            if date == expectedDate {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                    break
                }
                expectedDate = previousDay
            } else if date < expectedDate {
                break
            }
        }

        return streak
    }

    var longestStreak: Int {
        let calendar = Calendar.current
        let dates = completedDates

        guard !dates.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<dates.count {
            let previousDate = dates[i - 1]
            let currentDate = dates[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(nextDay, inSameDayAs: currentDate) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    var completionRate: Double {
        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

        guard daysSinceCreation > 0 else {
            return isCompletedToday ? 1.0 : 0.0
        }

        return Double(completedDates.count) / Double(daysSinceCreation + 1)
    }
}
