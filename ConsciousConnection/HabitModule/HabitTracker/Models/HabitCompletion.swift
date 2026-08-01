//
//  HabitCompletion.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 12.01.2026.
//

import Foundation
import SwiftData

@Model
class HabitCompletion {
    var id: UUID = UUID()
    var date: Date = Date()
    var habit: Habit?

    // HealthKit value tracking
    var value: Double?         // Numeric value (e.g., 2000ml, 7.5 hours)
    var isAutoSynced: Bool = false  // Track if from HealthKit

    // Cheat days are stored alongside completions so they sync and persist,
    // while Habit analytics can still distinguish them from genuine completions.
    var isCheatDay: Bool = false

    init(
        date: Date = Date(),
        habit: Habit? = nil,
        value: Double? = nil,
        isAutoSynced: Bool = false,
        isCheatDay: Bool = false
    ) {
        self.id = UUID()
        self.date = date
        self.habit = habit
        self.value = value
        self.isAutoSynced = isAutoSynced
        self.isCheatDay = isCheatDay
    }
}
