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

            Text("Make as many reusable lists as you like, then add tasks with a chosen duration.")
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

    private func listCard(_ list: CustomTaskList) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.name)
                        .font(.custom("Poppins-SemiBold", size: 21))
                        .foregroundStyle(.white)

                    Text("\(list.tasks.count) \(list.tasks.count == 1 ? "task" : "tasks")")
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
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title)
                                    .font(.custom("Poppins-Medium", size: 16))
                                    .foregroundStyle(.white)

                                Text("\(task.minutes) mins")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundStyle(.white.opacity(0.62))
                            }

                            Spacer()

                            Button(role: .destructive) {
                                store.deleteTask(task.id, from: list.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.18))
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

private struct AddCustomTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomTaskListStore.shared

    let list: CustomTaskList
    @State private var title = ""
    @State private var selectedMinutes = 10

    private let columns = [
        GridItem(.adaptive(minimum: 62), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task")
                        .font(.headline)
                    TextField("Write the task", text: $title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }

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

                Spacer()

                Button("OK") {
                    store.addTask(to: list.id, title: title, minutes: selectedMinutes)
                    dismiss()
                }
                .buttonStyle(CustomListPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
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
