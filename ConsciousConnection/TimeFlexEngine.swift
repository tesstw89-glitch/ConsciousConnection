import Foundation

struct TimeFlexEngine {

    // combos for each bucket
    static let COMBO_PATTERNS: [Int: [[Int]]] = [
        2:  [[2]],
        5:  [[5]],
        10: [[10]],
        15: [[15]],
        20: [[20]],
        30: [[30]],
        45: [[45]],
        60: [[60]]
    ]

    // MARK: - Counts

    static func getCount(_ task: FlexTask, data: TimeFlexData) -> Int {
        switch task.scope {
        case .daily:
            return data.dailyCounts[task.id] ?? 0
        case .weekly:
            return data.weeklyCounts[task.id] ?? 0
        case .monthly:
            return data.monthlyCounts[task.id] ?? 0
        }
    }

    static func remaining(_ task: FlexTask, data: TimeFlexData) -> Int {
        max(0, task.target - getCount(task, data: data))
    }

    static func inc(_ task: FlexTask, data: inout TimeFlexData, by n: Int = 1) {
        switch task.scope {
        case .daily:
            data.dailyCounts[task.id, default: 0] += n
        case .weekly:
            data.weeklyCounts[task.id, default: 0] += n
        case .monthly:
            data.monthlyCounts[task.id, default: 0] += n
        }
    }

    // MARK: - Day helpers

    static func isWorkday(_ date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let today = TaskWeekday.from(date, calendar: calendar) else { return false }
        return today.isWorkday
    }

    static func allowedWorkdayIDs(for duration: Int) -> Set<String> {
        Set(WORKDAY_WHITELIST[duration] ?? [])
    }

    static func allowedWorkdayIDsForAnyDuration() -> Set<String> {
        Set(WORKDAY_WHITELIST.values.flatMap { $0 })
    }

    // MARK: - Picking

    static func availableTasks(duration: Int, data: TimeFlexData, now: Date = Date()) -> [FlexTask] {
        let base = TASKS.filter { task in
            task.minutes == duration &&
            remaining(task, data: data) > 0 &&
            task.isAvailable(at: now)
        }

        if isWorkday(now) {
            let allowedIDs = allowedWorkdayIDs(for: duration)
            return base.filter { allowedIDs.contains($0.id) }
        } else {
            return base
        }
    }

    static func availableTasks(data: TimeFlexData, now: Date = Date()) -> [FlexTask] {
        let base = TASKS.filter { task in
            remaining(task, data: data) > 0 &&
            task.isAvailable(at: now)
        }

        if isWorkday(now) {
            let allowedIDs = allowedWorkdayIDsForAnyDuration()
            return base.filter { allowedIDs.contains($0.id) }
        } else {
            return base
        }
    }

    static func buildCombo(target: Int, data: TimeFlexData, now: Date = Date()) -> [FlexTask] {
        let patterns: [[Int]]
        if isWorkday(now) {
            patterns = WORKDAY_COMBO_PATTERNS[target] ?? [[target]]
        } else {
            patterns = COMBO_PATTERNS[target] ?? [[target]]
        }

        for pattern in patterns.shuffled() {
            var used = Set<String>()
            var picks: [FlexTask] = []
            var ok = true

            for dur in pattern {
                let pool = availableTasks(duration: dur, data: data, now: now)
                    .filter { !used.contains($0.id) }

                guard let pick = pool.randomElement() else {
                    ok = false
                    break
                }

                picks.append(pick)
                used.insert(pick.id)
            }

            if ok { return picks }
        }

        return availableTasks(data: data, now: now).randomElement().map { [$0] } ?? []
    }

    static func buildRandomTask(data: TimeFlexData, now: Date = Date()) -> [FlexTask] {
        availableTasks(data: data, now: now).randomElement().map { [$0] } ?? []
    }
}
