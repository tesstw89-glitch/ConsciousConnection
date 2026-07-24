import Foundation

struct CustomTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var minutes: Int

    init(id: UUID = UUID(), title: String, minutes: Int) {
        self.id = id
        self.title = title
        self.minutes = minutes
    }
}

struct CustomTaskList: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var tasks: [CustomTask]

    init(id: UUID = UUID(), name: String, tasks: [CustomTask] = []) {
        self.id = id
        self.name = name
        self.tasks = tasks
    }
}

private struct CustomTaskListData: Codable {
    var lists: [CustomTaskList] = []
    var activeListID: UUID?
    var completedDate: String = ""
    var completedTaskIDs: Set<UUID> = []
    var currentSuggestions: [String: [UUID]] = [:]
}

@MainActor
final class CustomTaskListStore: ObservableObject {
    static let shared = CustomTaskListStore()

    @Published private(set) var lists: [CustomTaskList] = []
    @Published private(set) var activeListID: UUID?
    @Published private(set) var completedTaskIDs: Set<UUID> = []

    private var currentSuggestions: [String: [UUID]] = [:]
    private let defaultsKey = "customTaskListData.v1"

    private init() {
        load()
        ensureDailyReset()
    }

    var activeList: CustomTaskList? {
        guard let activeListID else { return nil }
        return lists.first { $0.id == activeListID }
    }

    var isCustomListActive: Bool {
        activeList != nil
    }

    @discardableResult
    func createList(named rawName: String) -> CustomTaskList? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let list = CustomTaskList(name: name)
        lists.append(list)
        save()
        return list
    }

    func renameList(id: UUID, to rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = lists.firstIndex(where: { $0.id == id }) else { return }
        lists[index].name = name
        save()
    }

    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
        if activeListID == id {
            activeListID = nil
            currentSuggestions = [:]
        }
        save()
    }

    func addTask(to listID: UUID, title rawTitle: String, minutes: Int) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              Self.allowedDurations.contains(minutes),
              let index = lists.firstIndex(where: { $0.id == listID }) else { return }

        lists[index].tasks.append(CustomTask(title: title, minutes: minutes))
        currentSuggestions = [:]
        save()
    }

    func deleteTask(_ taskID: UUID, from listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].tasks.removeAll { $0.id == taskID }
        completedTaskIDs.remove(taskID)
        currentSuggestions = currentSuggestions.mapValues { ids in
            ids.filter { $0 != taskID }
        }
        save()
    }

    func activate(_ listID: UUID) {
        guard lists.contains(where: { $0.id == listID }) else { return }
        activeListID = listID
        currentSuggestions = [:]
        completedTaskIDs = []
        save()
    }

    func deactivate() {
        activeListID = nil
        currentSuggestions = [:]
        save()
    }

    func availableTasks(minutes: Int?) -> [CustomTask] {
        ensureDailyReset()
        guard let activeList else { return [] }

        return activeList.tasks.filter { task in
            !completedTaskIDs.contains(task.id) && (minutes == nil || task.minutes == minutes)
        }
    }

    func tasks(for suggestionKey: String) -> [CustomTask] {
        ensureDailyReset()
        guard let activeList else { return [] }
        let ids = currentSuggestions[suggestionKey] ?? []
        return ids.compactMap { id in activeList.tasks.first(where: { $0.id == id }) }
    }

    func ensureSuggestion(for suggestionKey: String, minutes: Int?) {
        ensureDailyReset()

        let existing = tasks(for: suggestionKey)
        let existingIsValid = !existing.isEmpty && existing.allSatisfy { task in
            !completedTaskIDs.contains(task.id) && (minutes == nil || task.minutes == minutes)
        }

        if existingIsValid { return }

        currentSuggestions[suggestionKey] = availableTasks(minutes: minutes)
            .randomElement()
            .map { [$0.id] } ?? []
        save()
    }

    @discardableResult
    func swap(taskID: UUID, suggestionKey: String, minutes: Int?) -> Bool {
        let currentIDs = Set(currentSuggestions[suggestionKey] ?? [])
        let pool = availableTasks(minutes: minutes).filter {
            $0.id != taskID && !currentIDs.contains($0.id)
        }

        guard let replacement = pool.randomElement() else { return false }
        currentSuggestions[suggestionKey] = [replacement.id]
        save()
        return true
    }

    func markDone(taskID: UUID, suggestionKey: String) {
        ensureDailyReset()
        completedTaskIDs.insert(taskID)
        currentSuggestions[suggestionKey] = nil
        save()
    }

    func clearSuggestion(for suggestionKey: String) {
        currentSuggestions[suggestionKey] = nil
        save()
    }

    func ensureDailyReset() {
        let today = Self.todayKey()
        let savedDate = UserDefaults.standard.string(forKey: "customTaskCompletedDate.v1") ?? ""

        guard savedDate != today else { return }
        completedTaskIDs = []
        currentSuggestions = [:]
        UserDefaults.standard.set(today, forKey: "customTaskCompletedDate.v1")
        save()
    }

    static let allowedDurations = [2, 5, 10, 15, 20, 30, 45, 60]

    private func load() {
        guard let raw = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(CustomTaskListData.self, from: raw) else {
            return
        }

        lists = decoded.lists
        activeListID = decoded.activeListID
        completedTaskIDs = decoded.completedTaskIDs
        currentSuggestions = decoded.currentSuggestions
        UserDefaults.standard.set(decoded.completedDate, forKey: "customTaskCompletedDate.v1")
    }

    private func save() {
        let data = CustomTaskListData(
            lists: lists,
            activeListID: activeListID,
            completedDate: UserDefaults.standard.string(forKey: "customTaskCompletedDate.v1") ?? Self.todayKey(),
            completedTaskIDs: completedTaskIDs,
            currentSuggestions: currentSuggestions
        )

        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: defaultsKey)
    }

    private static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
