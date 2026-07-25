import SwiftUI

struct CustomTaskListsView: View {
    @ObservedObject private var store = CustomTaskListStore.shared
    @State private var showingNewList = false
    @State private var listToAddTaskTo: CustomTaskList?

    var body: some View {
        ZStack {
            Image("WeeklyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.22)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    introCard

                    if store.lists.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.lists) { list in
                            listCard(list)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Custom Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewList = true
                } label: {
                    Label("New list", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewList) {
            NewCustomListSheet { name in
                if let list = store.createList(named: name) {
                    listToAddTaskTo = list
                }
            }
        }
        .sheet(item: $listToAddTaskTo) { list in
            AddCustomTaskSheet(list: list)
        }
        .onAppear {
            store.ensureDailyReset()
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREATE YOUR OWN CUSTOM LIST")
                .font(.custom("Poppins-SemiBold", size: 12))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.74))

            Text("Build a list for the day")
                .font(.custom("Poppins-SemiBold", size: 28))
                .foregroundStyle(.white)

            Text("Add reusable tasks, then tap their circles to tick them off for today.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(.white.opacity(0.76))
        }
        .padding(18)
        .frame(maxWidth: 350, alignment: .leading)
        .background(cardBackground)
        .overlay(cardStroke)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 38))
                .foregroundStyle(.white.opacity(0.9))

            Text("No custom lists yet")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(.white)

            Button("New List") {
                showingNewList = true
            }
            .buttonStyle(CustomListPrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 350)
        .background(cardBackground)
        .overlay(cardStroke)
    }

    private func completedCount(in list: CustomTaskList) -> Int {
        list.tasks.filter { store.completedTaskIDs.contains($0.id) }.count
    }

    private func listCard(_ list: CustomTaskList) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.name)
                        .font(.custom("Poppins-SemiBold", size: 21))
                        .foregroundStyle(.white)

                    Text("\(completedCount(in: list))/\(list.tasks.count) done today")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                Button {
                    listToAddTaskTo = list
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add task to \(list.name)")
            }

            if list.tasks.isEmpty {
                Text("Tap + to add the first task.")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(list.tasks) { task in
                        let isDone = store.completedTaskIDs.contains(task.id)

                        HStack(spacing: 12) {
                            Button {
                                store.toggleCompletion(taskID: task.id)
                            } label: {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundStyle(isDone ? Color.white : Color.white.opacity(0.68))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isDone ? "Mark \(task.title) not done" : "Mark \(task.title) done")

                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title)
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundStyle(.white)
                                    .strikethrough(isDone, color: .white.opacity(0.8))

                                Text("\(task.minutes) mins")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(.white.opacity(0.62))
                            }
                            .opacity(isDone ? 0.62 : 1)

                            Spacer()

                            Button(role: .destructive) {
                                store.deleteTask(task.id, from: list.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .accessibilityLabel("Delete \(task.title)")
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isDone ? Color.black.opacity(0.10) : Color.black.opacity(0.18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isDone ? Color.white.opacity(0.16) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: 350, alignment: .leading)
        .background(cardBackground)
        .overlay(cardStroke)
        .contextMenu {
            Button(role: .destructive) {
                store.deleteList(id: list.id)
            } label: {
                Label("Delete list", systemImage: "trash")
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.black.opacity(0.24))
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
    }
}

private struct NewCustomListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("List name") {
                    TextField("For example: Sunday reset", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("New List") {
                        onCreate(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private enum CustomTaskInputMode: String, CaseIterable, Identifiable {
    case newTask = "Write new"
    case existingTask = "Choose existing"

    var id: Self { self }
}

private struct AddCustomTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomTaskListStore.shared

    let list: CustomTaskList

    @State private var inputMode: CustomTaskInputMode = .newTask
    @State private var title = ""
    @State private var selectedMinutes = 10
    @State private var selectedBuiltInTaskIDs: Set<String> = []
    @State private var existingTaskSearch = ""

    private let columns = [
        GridItem(.adaptive(minimum: 62), spacing: 10)
    ]

    private var builtInTasks: [FlexTask] {
        TASKS.filter { task in
            guard task.id != "saturday_focus" else { return false }

            switch task.scope {
            case .daily, .weekly:
                return true
            case .monthly:
                return false
            }
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private var filteredBuiltInTasks: [FlexTask] {
        let search = existingTaskSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return builtInTasks }
        return builtInTasks.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    private var selectedBuiltInTasks: [FlexTask] {
        builtInTasks.filter { selectedBuiltInTaskIDs.contains($0.id) }
    }

    private var canAddTask: Bool {
        switch inputMode {
        case .newTask:
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .existingTask:
            return !selectedBuiltInTaskIDs.isEmpty
        }
    }

    private var addButtonTitle: String {
        switch inputMode {
        case .newTask:
            return "Add task"
        case .existingTask:
            let count = selectedBuiltInTaskIDs.count
            return count == 1 ? "Add 1 task" : "Add \(count) tasks"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Picker("Task source", selection: $inputMode) {
                        ForEach(CustomTaskInputMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if inputMode == .newTask {
                        newTaskSection
                        durationSection
                    } else {
                        existingTaskSection
                    }

                    Button(addButtonTitle) {
                        addSelectedTasks()
                    }
                    .buttonStyle(CustomListPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!canAddTask)
                }
                .padding(20)
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: inputMode) { _, _ in
                title = ""
                selectedBuiltInTaskIDs = []
                existingTaskSearch = ""
            }
        }
        .presentationDetents([.large])
    }

    private func addSelectedTasks() {
        switch inputMode {
        case .newTask:
            store.addTask(
                to: list.id,
                title: title,
                minutes: selectedMinutes
            )

        case .existingTask:
            for task in selectedBuiltInTasks {
                store.addTask(
                    to: list.id,
                    title: task.title,
                    minutes: task.minutes
                )
            }
        }

        dismiss()
    }

    private func toggleBuiltInTask(_ task: FlexTask) {
        if selectedBuiltInTaskIDs.contains(task.id) {
            selectedBuiltInTaskIDs.remove(task.id)
        } else {
            selectedBuiltInTaskIDs.insert(task.id)
        }
    }

    private var newTaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task")
                .font(.headline)

            TextField("Write the task", text: $title, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var existingTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Choose from your usual tasks")
                        .font(.headline)

                    Text("Select as many as you like. Each keeps its usual duration.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !selectedBuiltInTaskIDs.isEmpty {
                    Text("\(selectedBuiltInTaskIDs.count) selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            TextField("Search tasks", text: $existingTaskSearch)
                .textFieldStyle(.roundedBorder)

            if filteredBuiltInTasks.isEmpty {
                Text("No matching tasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredBuiltInTasks) { task in
                        let isSelected = selectedBuiltInTaskIDs.contains(task.id)

                        Button {
                            toggleBuiltInTask(task)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(task.title)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text("\(task.minutes) mins")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                            }
                            .padding(13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CustomTaskListStore.allowedDurations, id: \.self) { minutes in
                    Button {
                        selectedMinutes = minutes
                    } label: {
                        Text("\(minutes)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(selectedMinutes == minutes ? .white : .primary)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedMinutes == minutes ? Color.accentColor : Color.secondary.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(minutes) minutes")
                }
            }

            Text("minutes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CustomListPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.82 : 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    NavigationStack {
        CustomTaskListsView()
    }
}
