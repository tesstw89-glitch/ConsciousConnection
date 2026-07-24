import SwiftUI

struct TimeBucketView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var store = TimeFlexStore()
    @ObservedObject private var customStore = CustomTaskListStore.shared
    @State private var currentIndex: Int = 0

    @State private var cardVisible = false
    @State private var cardOffsetX: CGFloat = 40

    let minutes: Int
    private var isRandomMode: Bool { minutes == 0 }
    private var suggestionKey: String { isRandomMode ? "timeRandomIds" : "time\(minutes)Ids" }
    private var usesCustomList: Bool { customStore.isCustomListActive }

    private func currentTasks() -> [FlexTask] {
        let ids = store.data.currentSuggestions[suggestionKey] ?? []
        return ids.compactMap { id in TASKS.first(where: { $0.id == id }) }
    }

    private func currentCustomTasks() -> [CustomTask] {
        customStore.tasks(for: suggestionKey)
    }

    private func ensureSuggestion() {
        if usesCustomList {
            customStore.ensureSuggestion(
                for: suggestionKey,
                minutes: isRandomMode ? nil : minutes
            )
            currentIndex = 0
            return
        }

        store.ensureResets()
        let now = Date()

        if let ids = store.data.currentSuggestions[suggestionKey] {
            let cachedTasks = ids.compactMap { id in TASKS.first(where: { $0.id == id }) }

            let mismatch = !isRandomMode && cachedTasks.contains { $0.minutes != minutes }
            let unavailableNow = cachedTasks.contains { !$0.isAvailable(at: now) }

            if mismatch || unavailableNow {
                store.data.currentSuggestions[suggestionKey] = nil
                store.save()
            }
        }

        if store.data.currentSuggestions[suggestionKey] == nil {
            let picks: [FlexTask]

            if isRandomMode {
                picks = TimeFlexEngine.buildRandomTask(data: store.data, now: now)
            } else {
                picks = TimeFlexEngine.buildCombo(target: minutes, data: store.data, now: now)
            }

            store.data.currentSuggestions[suggestionKey] = picks.map { $0.id }
            store.save()
        }

        currentIndex = 0
    }

    @discardableResult
    private func swap(task: FlexTask) -> Bool {
        let now = Date()
        let existingIds = Set(store.data.currentSuggestions[suggestionKey] ?? [])

        var pool: [FlexTask]
        if isRandomMode {
            pool = TimeFlexEngine.availableTasks(data: store.data, now: now)
        } else {
            pool = TimeFlexEngine.availableTasks(duration: task.minutes, data: store.data, now: now)
        }

        pool.removeAll { $0.id == task.id || existingIds.contains($0.id) }

        guard let replacement = pool.randomElement() else { return false }

        if var ids = store.data.currentSuggestions[suggestionKey],
           let idx = ids.firstIndex(of: task.id) {
            ids[idx] = replacement.id
            store.data.currentSuggestions[suggestionKey] = ids
            store.save()
            return true
        }

        return false
    }

    @discardableResult
    private func swap(customTask: CustomTask) -> Bool {
        customStore.swap(
            taskID: customTask.id,
            suggestionKey: suggestionKey,
            minutes: isRandomMode ? nil : minutes
        )
    }

    private func animateCardIn() {
        cardVisible = false
        cardOffsetX = 40

        withAnimation(.easeOut(duration: 0.35)) {
            cardVisible = true
            cardOffsetX = 0
        }
    }

    private func animateCardRefresh(_ action: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.12)) {
            cardVisible = false
            cardOffsetX = 18
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            action()
            cardOffsetX = 40
            withAnimation(.easeOut(duration: 0.35)) {
                cardVisible = true
                cardOffsetX = 0
            }
        }
    }

    private func markDone() {
        if usesCustomList {
            let tasks = currentCustomTasks()
            guard let task = tasks.first else {
                router.goHome()
                return
            }

            customStore.markDone(taskID: task.id, suggestionKey: suggestionKey)
            router.goHome()
            return
        }

        let tasks = currentTasks()
        guard !tasks.isEmpty else {
            router.goHome()
            return
        }

        guard tasks.indices.contains(currentIndex) else {
            currentIndex = 0
            return
        }

        let isLastTask = currentIndex >= tasks.count - 1

        if isLastTask {
            let t = tasks[currentIndex]
            TimeFlexEngine.inc(t, data: &store.data)
            store.save()
            store.data.currentSuggestions[suggestionKey] = nil
            store.save()
            router.goHome()
        } else {
            animateCardRefresh {
                var refreshedTasks = currentTasks()
                guard refreshedTasks.indices.contains(currentIndex) else { return }

                let t = refreshedTasks[currentIndex]
                TimeFlexEngine.inc(t, data: &store.data)
                store.save()

                refreshedTasks = currentTasks()
                if currentIndex < refreshedTasks.count - 1 {
                    currentIndex += 1
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Image("TimeBucketBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.14)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 30)

                heading
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 3)

                if usesCustomList {
                    customTaskContent
                } else {
                    standardTaskContent
                }

                Button {
                    markDone()
                } label: {
                    Text("Done")
                }
                .buttonStyle(TimeBucketMainButtonStyle())
                .padding(.top, 4)

                Button {
                    router.goHome()
                } label: {
                    Text("Home")
                }
                .buttonStyle(TimeBucketGhostButtonStyle())

                Spacer()
            }
        }
        .onAppear {
            ensureSuggestion()
            if usesCustomList ? !currentCustomTasks().isEmpty : !currentTasks().isEmpty {
                animateCardIn()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var heading: some View {
        VStack(spacing: 6) {
            if isRandomMode {
                Text("Random")
                    .font(.custom("Didot", size: 52))
                    .foregroundStyle(.white)

                Text(usesCustomList ? "custom task" : "task")
                    .font(.custom("Didot", size: 26))
                    .foregroundStyle(.white.opacity(0.92))
            } else {
                Text("\(minutes)")
                    .font(.custom("Didot", size: 58))
                    .foregroundStyle(.white)

                Text(minutes == 1 ? "minute" : "minutes")
                    .font(.custom("Didot", size: 26))
                    .foregroundStyle(.white.opacity(0.92))
            }

            if let activeList = customStore.activeList {
                Text(activeList.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    @ViewBuilder
    private var customTaskContent: some View {
        let tasks = currentCustomTasks()

        if let task = tasks.first {
            taskCard(title: task.title) {
                if swap(customTask: task) {
                    animateCardRefresh { }
                }
            }
        } else {
            emptyTaskCard(
                message: isRandomMode
                    ? "There are no unfinished tasks left in this custom list."
                    : "There are no unfinished \(minutes)-minute tasks in this custom list."
            )
        }
    }

    @ViewBuilder
    private var standardTaskContent: some View {
        let tasks = currentTasks()

        if tasks.isEmpty {
            emptyTaskCard(message: "You’ve worked hard enough.")
        } else if tasks.indices.contains(currentIndex) {
            let task = tasks[currentIndex]
            taskCard(title: task.title) {
                if swap(task: task) {
                    animateCardRefresh { }
                }
            }
        } else {
            Text("All done ✨")
                .font(.custom("Didot", size: 36))
                .foregroundStyle(.white)
                .padding(.top, 10)
        }
    }

    private func taskCard(title: String, onSwap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your task")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .textCase(.uppercase)

            Text(title)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()

                Button(action: onSwap) {
                    Text("Swap")
                }
                .buttonStyle(TimeBucketGhostButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.26))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 22)
        .offset(x: cardOffsetX)
        .opacity(cardVisible ? 1 : 0)
    }

    private func emptyTaskCard(message: String) -> some View {
        VStack(spacing: 10) {
            Text("None for today")
                .font(.custom("Didot", size: 34))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal, 22)
    }
}

private struct TimeBucketMainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(minWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.44 : 0.32))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TimeBucketGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.34 : 0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        TimeBucketView(minutes: 10)
            .environmentObject(AppRouter())
    }
}
