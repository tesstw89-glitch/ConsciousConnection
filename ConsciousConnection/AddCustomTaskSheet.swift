import SwiftUI

enum CustomTaskInputMode: String, CaseIterable, Identifiable {
    case newTask = "Write new"
    case existingTask = "Choose existing"
    var id: Self { self }
}

struct AddCustomTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store = CustomTaskListStore.shared
    let list: CustomTaskList

    @State var inputMode: CustomTaskInputMode = .newTask
    @State var title = ""
    @State var selectedMinutes = 10
    @State var selectedBuiltInTaskIDs: Set<String> = []
    @State var existingTaskSearch = ""

    var builtInTasks: [FlexTask] {
        TASKS.filter { $0.id != "saturday_focus" && $0.scope != .monthly }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    var filteredBuiltInTasks: [FlexTask] {
        let search = existingTaskSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        return search.isEmpty ? builtInTasks : builtInTasks.filter {
            $0.title.localizedCaseInsensitiveContains(search)
        }
    }
    var selectedBuiltInTasks: [FlexTask] {
        builtInTasks.filter { selectedBuiltInTaskIDs.contains($0.id) }
    }
    var canAddTask: Bool {
        inputMode == .newTask
            ? !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            : !selectedBuiltInTaskIDs.isEmpty
    }
    var addButtonTitle: String {
        guard inputMode == .existingTask else { return "Add task" }
        return selectedBuiltInTaskIDs.count == 1 ? "Add 1 task" : "Add \(selectedBuiltInTaskIDs.count) tasks"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Picker("Task source", selection: $inputMode) {
                        ForEach(CustomTaskInputMode.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)

                    if inputMode == .newTask { newTaskSection; durationSection }
                    else { existingTaskSection }

                    Button(addButtonTitle) { addSelectedTasks() }
                        .buttonStyle(CustomListPrimaryButtonStyle())
                        .disabled(!canAddTask)
                }.padding(20)
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onChange(of: inputMode) { _, _ in
                title = ""; selectedBuiltInTaskIDs = []; existingTaskSearch = ""
            }
        }.presentationDetents([.large])
    }

    func addSelectedTasks() {
        if inputMode == .newTask {
            store.addTask(to: list.id, title: title, minutes: selectedMinutes)
        } else {
            selectedBuiltInTasks.forEach {
                store.addTask(to: list.id, title: $0.title, minutes: $0.minutes)
            }
        }
        dismiss()
    }
}
