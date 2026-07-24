import SwiftUI
import SwiftData
import UIKit

// MARK: - Notification for Widget Updates

extension Notification.Name {
    static let habitsDidChange = Notification.Name("habitsDidChange")
    static let allHabitsCompleted = Notification.Name("allHabitsCompleted")
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isUsingLocalStorage) private var isUsingLocalStorage
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \HabitStack.createdAt, order: .reverse) private var stacks: [HabitStack]

    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var suggestionEngine = HabitSuggestionEngine.shared
    @ObservedObject private var stackManager = HabitStackManager.shared
    @ObservedObject private var focusManager = FocusSessionManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var showingAddHabit = false
    @State private var showingStacks = false
    @State private var showingCreateStack = false
    @State private var showingPaywall = false
    @State private var showingSuggestions = false
    @State private var habitToEdit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var suggestions: [HabitSuggestion] = []
    @State private var selectedSuggestion: HabitSuggestion?
    @State private var habitForFocus: Habit?
    @State private var showingCelebration = false

    @AppStorage("lastActiveDate") private var lastActiveDateTimestamp: Double = 0
    @State private var refreshID = UUID()

    @State private var syncError: String?
    @State private var showingSyncError = false
    @State private var showingLocalStorageBanner = false

    @AppStorage("dismissedWidgetPromo") private var dismissedWidgetPromo = false
    @State private var showingWidgetPromo = false

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    private var lastActiveDate: Date {
        Date(timeIntervalSince1970: lastActiveDateTimestamp)
    }

    private var isViewingToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    private var selectedDateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            return selectedDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
        }
    }

    private var visibleHabits: [Habit] {
        habits.filter { habit in
            !habit.isRestDay(on: selectedDate)
        }
    }

    private var hasHabitsButAllAreResting: Bool {
        !habits.isEmpty && visibleHabits.isEmpty
    }

    private func updateLastActiveDate() {
        lastActiveDateTimestamp = Date().timeIntervalSince1970
    }

    private func moveSelectedDate(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else { return }

        let today = Calendar.current.startOfDay(for: Date())
        if newDate > today {
            selectedDate = today
        } else {
            selectedDate = Calendar.current.startOfDay(for: newDate)
        }
    }

    private var topSectionGradient: LinearGradient {
        let (r, g, b) = themeManager.accentColor.rgbComponents

        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: r * 0.18, green: g * 0.14, blue: b * 0.28),
                    Color(red: r * 0.12, green: g * 0.10, blue: b * 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.94 + r * 0.04, green: 0.92 + g * 0.04, blue: 0.96 + b * 0.03),
                    Color(red: 0.92 + r * 0.04, green: 0.90 + g * 0.04, blue: 0.95 + b * 0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var topSectionTopColor: Color {
        if themeManager.dynamicHeaderEnabled {
            switch TimeOfDay.current {
            case .morning:
                return Color(red: 0.53, green: 0.72, blue: 0.96)
            case .afternoon:
                return Color(red: 0.42, green: 0.73, blue: 0.98)
            case .evening:
                return Color(red: 0.24, green: 0.18, blue: 0.42)
            case .night:
                return Color(red: 0.15, green: 0.12, blue: 0.28)
            }
        }

        let (r, g, b) = themeManager.accentColor.rgbComponents

        if colorScheme == .dark {
            return Color(red: r * 0.18, green: g * 0.14, blue: b * 0.28)
        } else {
            return Color(red: 0.94 + r * 0.04, green: 0.92 + g * 0.04, blue: 0.96 + b * 0.03)
        }
    }

    @ViewBuilder
    private var headerBackground: some View {
        if themeManager.dynamicHeaderEnabled {
            Image(themeManager.currentHeaderImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            topSectionGradient
        }
    }

    private var greetingSubtitleColor: Color {
        if themeManager.dynamicHeaderEnabled {
            return Color.white.opacity(0.85)
        }
        return colorScheme == .dark
            ? Color(red: 0.75, green: 0.70, blue: 0.85)
            : Color(red: 0.5, green: 0.45, blue: 0.55)
    }

    private var greetingTitleColor: Color {
        if themeManager.dynamicHeaderEnabled {
            return .white
        }
        return colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.25)
    }

    private var dayNavigator: some View {
        HStack(spacing: 8) {
            Button {
                HapticManager.shared.buttonPressed()
                moveSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.22))
                    .clipShape(Circle())
            }

            VStack(spacing: 0) {
                Text(selectedDateLabel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(greetingTitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.5) : .clear, radius: 3, x: 0, y: 1)

                if !isViewingToday {
                    Text("Retrospective view")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(greetingSubtitleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.45) : .clear, radius: 3, x: 0, y: 1)
                }
            }
            .frame(width: 145)

            Button {
                HapticManager.shared.buttonPressed()
                moveSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.22))
                    .clipShape(Circle())
            }
            .disabled(isViewingToday)
            .opacity(isViewingToday ? 0.3 : 1.0)
        }
        .frame(maxWidth: .infinity)
    }

    private var greetingHeader: some View {
        HStack(spacing: 12) {
            Image("ProfileMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(greetingSubtitleColor)
                        .lineLimit(1)
                        .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.5) : .clear, radius: 3, x: 0, y: 1)

                    Text(greetingEmoji)
                        .font(.subheadline)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    HapticManager.shared.buttonPressed()
                    dismiss()
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.22))
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Back to Conscious Connection")
                .accessibilityHint("Double tap to return to the main app")

                Button {
                    HapticManager.shared.buttonPressed()
                    if store.canAddMoreHabits(currentCount: habits.count) {
                        showingAddHabit = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(themeManager.primaryGradient)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add new habit")
                .accessibilityHint("Double tap to create a new habit")
            }
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "👋"
        case 17..<21: return "🌅"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingClouds()

                ScrollView {
                    VStack(spacing: 12) {
                        Color.clear
                            .frame(height: visibleHabits.isEmpty ? 180 : 280)

                        if habits.isEmpty {
                            emptyStateSection
                        } else if visibleHabits.isEmpty {
                            restDaySection
                        } else {
                            habitsPreviewSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        if themeManager.dynamicHeaderEnabled {
                            GeometryReader { geo in
                                Image(themeManager.currentHeaderImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: visibleHabits.isEmpty ? 220 : 320)
                                    .clipped()
                            }
                            .frame(height: visibleHabits.isEmpty ? 220 : 320)
                            .clipShape(WaveBottomEdge(amplitude: 25))
                            .ignoresSafeArea(edges: .top)
                        } else {
                            topSectionTopColor
                                .frame(height: 80)
                                .ignoresSafeArea(edges: .top)

                            VStack {}
                                .frame(maxWidth: .infinity)
                                .frame(height: visibleHabits.isEmpty ? 180 : 280)
                                .background(topSectionGradient)
                                .clipShape(WaveBottomEdge(amplitude: 25))
                        }

                        ZStack(alignment: .top) {
                            VStack(spacing: 6) {
                                greetingHeader

                                if !visibleHabits.isEmpty {
                                    WhiteProgressCard(
                                        habits: Array(visibleHabits),
                                        showDynamicBackground: themeManager.dynamicHeaderEnabled
                                    )
                                    .id(refreshID)
                                    .padding(.bottom, 8)
                                } else {
                                    Text(hasHabitsButAllAreResting ? "Rest day" : "Add habits to track progress")
                                        .font(.subheadline)
                                        .foregroundStyle(greetingSubtitleColor)
                                        .shadow(color: themeManager.dynamicHeaderEnabled ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                                        .padding(.vertical, 12)
                                }
                            }

                            dayNavigator
                                .padding(.top, 76)
                                .offset(x: -60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $habitToEdit) { habit in
                EditHabitView(habit: habit)
            }
            .sheet(isPresented: $showingSuggestions) {
                SuggestionsView()
            }
            .sheet(isPresented: $showingStacks) {
                StacksView()
            }
            .sheet(isPresented: $showingCreateStack) {
                HabitStackBuilderView()
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                AddHabitFromSuggestionView(suggestion: suggestion)
            }
            .sheet(item: $habitForFocus) { habit in
                FocusSetupSheet(habit: habit)
            }
            .fullScreenCover(isPresented: $focusManager.isShowingTimer) {
                FocusSessionView()
            }
            .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        deleteHabit(habit)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(habitToDelete?.name ?? "")\"? This action cannot be undone.")
            }
            .onChange(of: habits) { _, newHabits in
                WidgetDataManager.shared.updateWidgetData(habits: newHabits)
                refreshSuggestions()

                if !dismissedWidgetPromo && newHabits.count == 1 && !showingWidgetPromo {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                        showingWidgetPromo = true
                    }
                }
            }
            .onChange(of: selectedDate) { _, _ in
                refreshID = UUID()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    let calendar = Calendar.current
                    let now = Date()

                    if !calendar.isDate(lastActiveDate, inSameDayAs: now) {
                        refreshID = UUID()
                    }

                    updateLastActiveDate()

                    Task {
                        await syncHealthKitHabits()
                    }

                    WidgetDataManager.shared.updateWidgetData(habits: habits)
                }
            }
            .onAppear {
                let calendar = Calendar.current
                let now = Date()

                if lastActiveDateTimestamp == 0 || !calendar.isDate(lastActiveDate, inSameDayAs: now) {
                    refreshID = UUID()
                    updateLastActiveDate()
                }

                WidgetDataManager.shared.updateWidgetData(habits: habits)
                refreshSuggestions()

                if !dismissedWidgetPromo && !habits.isEmpty {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                        showingWidgetPromo = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .habitsDidChange)) { _ in
                WidgetDataManager.shared.updateWidgetData(habits: habits)
            }
            .onReceive(NotificationCenter.default.publisher(for: .allHabitsCompleted)) { _ in
                showingCelebration = true
            }
            .overlay {
                if showingCelebration {
                    CelebrationView(isShowing: $showingCelebration)
                        .ignoresSafeArea()
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if showingLocalStorageBanner {
                        LocalStorageBanner {
                            withAnimation {
                                showingLocalStorageBanner = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if showingSyncError, let error = syncError {
                        SyncErrorBanner(message: error) {
                            withAnimation {
                                showingSyncError = false
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 60)
            }
            .onAppear {
                if isUsingLocalStorage && !UserDefaults.standard.bool(forKey: "dismissedLocalStorageBanner") {
                    showingLocalStorageBanner = true
                }
            }
        }
    }

    private struct LocalStorageBanner: View {
        let onDismiss: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.subheadline.weight(.medium))
                    Text("Data is saved locally only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    UserDefaults.standard.set(true, forKey: "dismissedLocalStorageBanner")
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private struct SyncErrorBanner: View {
        let message: String
        let onDismiss: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(.orange)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal, 16)
        }
    }

    private func syncHealthKitHabits() async {
        let healthKitHabits = habits.filter { $0.dataSource == .healthKit }
        var syncFailed = false

        for habit in healthKitHabits {
            do {
                if let value = try await healthKitManager.syncHabitFromHealthKit(habit) {
                    await MainActor.run {
                        updateOrCreateCompletion(for: habit, value: value)
                    }
                }
            } catch let error as NSError {
                if error.domain == "com.apple.healthkit" && error.code == 11 {
                    #if DEBUG
                    print("\(habit.name): No health data available for today (this is normal)")
                    #endif
                } else {
                    syncFailed = true
                    #if DEBUG
                    print("Failed to sync \(habit.name): \(error)")
                    #endif
                }
            }
        }

        if syncFailed {
            await MainActor.run {
                syncError = "Some health data couldn't sync"
                withAnimation {
                    showingSyncError = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showingSyncError = false
                    }
                }
            }
        }
    }

    private func updateOrCreateCompletion(for habit: Habit, value: Double) {
        let calendar = Calendar.current

        if let existing = habit.completion(on: Date(), calendar: calendar) {
            existing.value = value
            existing.isAutoSynced = true
        } else {
            let completion = HabitCompletion(date: Date(), habit: habit, value: value, isAutoSynced: true)
            modelContext.insert(completion)
        }

        NotificationCenter.default.post(name: .habitsDidChange, object: nil)
    }

    private func deleteHabit(_ habit: Habit) {
        HapticManager.shared.habitDeleted()
        withAnimation {
            for completion in habit.safeCompletions {
                modelContext.delete(completion)
            }
            modelContext.delete(habit)
            habitToDelete = nil
            NotificationCenter.default.post(name: .habitsDidChange, object: nil)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var habitsPreviewSection: some View {
        VStack(spacing: 12) {
            ForEach(visibleHabits) { habit in
                HabitCard(
                    habit: habit,
                    selectedDate: selectedDate,
                    stack: getStack(for: habit),
                    stackPosition: getStackPosition(for: habit),
                    onStartFocus: {
                        habitForFocus = habit
                    }
                )
                .contextMenu {
                    if isViewingToday && habit.focusEnabled && !habit.isCompleted(on: selectedDate) {
                        Button {
                            habitForFocus = habit
                        } label: {
                            Label("Start Focus Session", systemImage: "timer")
                        }
                    }

                    Button {
                        habitToEdit = habit
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        habitToDelete = habit
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if showingWidgetPromo {
                WidgetPromoBanner {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingWidgetPromo = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }

            if visibleHabits.count >= 2 {
                stacksPreviewSection
            }

            if !suggestions.isEmpty && habits.count < 10 {
                suggestionsPreviewSection
            }
        }
        .id(refreshID)
    }

    private var stacksPreviewSection: some View {
        StacksPreviewSection(
            stacks: Array(stacks),
            habits: Array(visibleHabits),
            onShowStacks: { showingStacks = true },
            onCreateStack: { showingCreateStack = true }
        )
    }

    private var suggestionsPreviewSection: some View {
        SuggestionsPreviewSection(
            suggestions: suggestions,
            onShowSuggestions: { showingSuggestions = true },
            onSelectSuggestion: { suggestion in
                selectedSuggestion = suggestion
            }
        )
    }

    private var restDaySection: some View {
        VStack(spacing: 10) {
            Text("Rest day")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("No habits scheduled for \(selectedDateLabel.lowercased()).")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var emptyStateSection: some View {
        EmptyHabitsView()
    }

    private func deleteHabits(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }
    }

    private func refreshSuggestions() {
        suggestions = suggestionEngine.generateSuggestions(for: habits)
    }

    private func getStack(for habit: Habit) -> HabitStack? {
        guard let stackId = habit.stackId else { return nil }
        return stacks.first { $0.id == stackId }
    }

    private func getStackPosition(for habit: Habit) -> (current: Int, total: Int)? {
        guard let stack = getStack(for: habit) else { return nil }
        guard let index = stack.habitOrder.firstIndex(of: habit.id) else { return nil }
        return (current: index + 1, total: stack.habitOrder.count)
    }
}
