import SwiftUI

struct WeeklyTasksView: View {
    @StateObject private var store = TimeFlexStore()
    @ObservedObject private var customStore = CustomTaskListStore.shared
    @State private var showingCustomListPicker = false

    private let cardMaxWidth: CGFloat = 350

    private func count(for task: FlexTask) -> Int {
        TimeFlexEngine.getCount(task, data: store.data)
    }

    private func setCount(_ task: FlexTask, to newValue: Int) {
        let t = max(0, min(newValue, task.target))
        switch task.scope {
        case .daily:
            store.data.dailyCounts[task.id] = t
        case .weekly:
            store.data.weeklyCounts[task.id] = t
        case .monthly:
            store.data.monthlyCounts[task.id] = t
        }
        store.save()
        store.ensureResets()
    }

    private func weekdayName(_ weekday: TaskWeekday) -> String {
        switch weekday {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    private func weekdayHint(for task: FlexTask) -> String? {
        guard !task.weekdays.isEmpty else { return nil }

        let names = task.weekdays.map(weekdayName)

        if names.count == 1 {
            return "usually on a \(names[0])"
        } else if names.count == 2 {
            return "usually on \(names[0]) & \(names[1])"
        } else {
            let allButLast = names.dropLast().joined(separator: ", ")
            return "usually on \(allButLast) & \(names.last!)"
        }
    }

    private var dailyTasks: [FlexTask] {
        TASKS.filter { $0.scope == .daily && $0.id != "saturday_focus" }
    }

    private var weeklyTasksOnly: [FlexTask] {
        TASKS.filter { $0.scope == .weekly && $0.id != "saturday_focus" }
    }

    private var currentSaturdayFocusRoom: SaturdayFocusRoom? {
        guard !SATURDAY_FOCUS_ROOMS.isEmpty else { return nil }
        let index = store.data.satFocusIndex % SATURDAY_FOCUS_ROOMS.count
        return SATURDAY_FOCUS_ROOMS[index]
    }

    var body: some View {
        ZStack {
            Image("WeeklyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerCard
                    customListSwitchButton
                    taskSection(title: "Daily Tasks", tasks: dailyTasks)
                    taskSection(title: "Weekly Tasks", tasks: weeklyTasksOnly)
                    saturdayFocusSection
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 88)
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CustomTaskListsView()
                } label: {
                    Text("Create your own custom list")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showingCustomListPicker) {
            CustomListPickerSheet()
        }
        .onAppear {
            store.ensureResets()
            customStore.ensureDailyReset()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEKLY TASKS")
                .font(.custom("Poppins-SemiBold", size: 12))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.74))

            Text("Keep the rhythm going")
                .font(.custom("Poppins-SemiBold", size: 30))
                .foregroundStyle(.white)

            Text("Tap the circles to tick things off.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(18)
        .frame(maxWidth: cardMaxWidth, alignment: .leading)
        .background(cardBackground)
        .overlay(cardStroke)
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }

    private var customListSwitchButton: some View {
        Button {
            if customStore.isCustomListActive {
                customStore.deactivate()
            } else {
                showingCustomListPicker = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: customStore.isCustomListActive ? "xmark.circle.fill" : "arrow.triangle.2.circlepath")

                VStack(alignment: .leading, spacing: 2) {
                    Text(customStore.isCustomListActive ? "Switch off custom list" : "Switch to custom list")
                        .font(.custom("Poppins-SemiBold", size: 16))

                    if let activeList = customStore.activeList {
                        Text("Currently using: \(activeList.name)")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .opacity(customStore.isCustomListActive ? 0 : 0.8)
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: cardMaxWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(customStore.isCustomListActive ? Color.white.opacity(0.20) : Color.black.opacity(0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func taskSection(title: String, tasks: [FlexTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: cardMaxWidth, alignment: .leading)
        .background(cardBackground)
        .overlay(cardStroke)
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }

    private func taskRow(_ task: FlexTask) -> some View {
        let currentCount = count(for: task)
        let hint = weekdayHint(for: task)

        return VStack(alignment: .leading, spacing: 12) {
            Text(task.title)
                .font(.custom("Poppins-Medium", size: 17))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<task.target, id: \.self) { index in
                    BEMAnimatedCheckbox(
                        isOn: Binding(
                            get: { index < currentCount },
                            set: { newValue in
                                if newValue {
                                    setCount(task, to: index + 1)
                                } else {
                                    setCount(task, to: index)
                                }
                            }
                        ),
                        size: 26
                    )
                    .frame(width: 26, height: 26)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(currentCount)/\(task.target)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.white.opacity(0.68))

                    if let hint {
                        Text(hint)
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundStyle(.white.opacity(0.52))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var saturdayFocusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saturday Focus")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(.white)

            if let sat = TASKS.first(where: { $0.id == "saturday_focus" }),
               let room = currentSaturdayFocusRoom {

                let done = count(for: sat)
                let isDone = done > 0

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        BEMAnimatedCheckbox(
                            isOn: Binding(
                                get: { isDone },
                                set: { newValue in
                                    if newValue && !isDone {
                                        setCount(sat, to: sat.target)
                                        store.data.satFocusIndex =
                                            (store.data.satFocusIndex + 1) % SATURDAY_FOCUS_ROOMS.count
                                        store.save()
                                    } else if !newValue && isDone {
                                        setCount(sat, to: 0)
                                    }
                                }
                            ),
                            size: 30
                        )
                        .frame(width: 30, height: 30)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(room.title)
                                .font(.custom("Poppins-SemiBold", size: 18))
                                .foregroundStyle(.white)

                            Text(isDone ? "Done this week" : "Not done yet")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(room.tasks, id: \.self) { task in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.white.opacity(0.85))

                                Text(task)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundStyle(.white.opacity(0.78))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            store.data.satFocusIndex =
                                (store.data.satFocusIndex + 1) % SATURDAY_FOCUS_ROOMS.count
                            store.save()
                        } label: {
                            Text("Next room")
                                .font(.custom("Poppins-Medium", size: 15))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.black.opacity(0.18))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            if !isDone {
                                setCount(sat, to: sat.target)
                                store.data.satFocusIndex =
                                    (store.data.satFocusIndex + 1) % SATURDAY_FOCUS_ROOMS.count
                                store.save()
                            }
                        } label: {
                            Text("Mark done")
                                .font(.custom("Poppins-SemiBold", size: 15))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.95))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            } else {
                Text("Missing Saturday Focus data")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(18)
        .frame(maxWidth: cardMaxWidth, alignment: .leading)
        .background(cardBackground)
        .overlay(cardStroke)
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.black.opacity(0.22))
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
    }
}

private struct CustomListPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomTaskListStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if store.lists.isEmpty {
                    ContentUnavailableView(
                        "No custom lists",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Create a list first, then return here to switch it on.")
                    )
                } else {
                    List(store.lists) { list in
                        Button {
                            store.activate(list.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(list.name)
                                        .font(.headline)
                                    Text("\(list.tasks.count) \(list.tasks.count == 1 ? "task" : "tasks")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if store.activeListID == list.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .disabled(list.tasks.isEmpty)
                    }
                }
            }
            .navigationTitle("Choose a custom list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        WeeklyTasksView()
    }
}
