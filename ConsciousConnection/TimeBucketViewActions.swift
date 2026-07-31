import Foundation

extension TimeBucketView {
    func ensureSuggestion() {
        if usesCustomList {
            customStore.ensureSuggestion(for: suggestionKey, minutes: isRandomMode ? nil : minutes)
            currentIndex = 0
            return
        }
        store.ensureResets()
        let now = Date()
        if let ids = store.data.currentSuggestions[suggestionKey] {
            let cached = ids.compactMap { id in TASKS.first(where: { $0.id == id }) }
            if (!isRandomMode && cached.contains { $0.minutes != minutes }) || cached.contains(where: { !$0.isAvailable(at: now) }) {
                store.data.currentSuggestions[suggestionKey] = nil; store.save()
            }
        }
        if store.data.currentSuggestions[suggestionKey] == nil {
            let picks = isRandomMode
                ? TimeFlexEngine.buildRandomTask(data: store.data, now: now)
                : TimeFlexEngine.buildCombo(target: minutes, data: store.data, now: now)
            store.data.currentSuggestions[suggestionKey] = picks.map(\.id); store.save()
        }
        currentIndex = 0
    }

    func swap(task: FlexTask) {
        let now = Date()
        let existing = Set(store.data.currentSuggestions[suggestionKey] ?? [])
        var pool = isRandomMode
            ? TimeFlexEngine.availableTasks(data: store.data, now: now)
            : TimeFlexEngine.availableTasks(duration: task.minutes, data: store.data, now: now)
        pool.removeAll { $0.id == task.id || existing.contains($0.id) }
        guard let replacement = pool.randomElement(),
              var ids = store.data.currentSuggestions[suggestionKey],
              let index = ids.firstIndex(of: task.id) else { return }
        ids[index] = replacement.id; store.data.currentSuggestions[suggestionKey] = ids; store.save()
    }

    func swap(customTask: CustomTask) {
        _ = customStore.swap(taskID: customTask.id, suggestionKey: suggestionKey,
                             minutes: isRandomMode ? nil : minutes)
    }

    func markDone() {
        if usesCustomList {
            guard let task = currentCustomTasks().first else { router.goHome(); return }
            customStore.markDone(taskID: task.id, suggestionKey: suggestionKey)
            customStore.ensureSuggestion(for: suggestionKey, minutes: isRandomMode ? nil : minutes)
            return
        }

        let tasks = currentTasks()
        guard tasks.indices.contains(currentIndex) else { router.goHome(); return }
        let task = tasks[currentIndex]
        TimeFlexEngine.inc(task, data: &store.data); store.save()
        if currentIndex >= tasks.count - 1 {
            store.data.currentSuggestions[suggestionKey] = nil; store.save(); router.goHome()
        } else {
            currentIndex += 1
        }
    }
}
