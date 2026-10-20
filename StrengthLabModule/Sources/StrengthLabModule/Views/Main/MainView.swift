//
//  MainView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData
import TipKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ExerciseManager.self) private var exerciseManager: ExerciseManager
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(AchievementManager.self) private var achievementManager: AchievementManager?

    var animateDeckEntrance: Bool = false

    @Binding var pendingDeepLink: DeepLink?

    @State private var viewModel: ViewModel = ViewModel()
    @State private var showingRoutineEditSheet: Bool = false
    @State private var workoutNow: Date = Date()
    @State private var workoutToolbarTimer: Timer? = nil

    private let editRoutineTip = EditRoutineTip()

    private var isStrengthWorkoutActive: Bool {
        healthManager.isStrengthTrainingActive
    }

    private var workoutElapsedString: String {
        healthManager.currentWorkoutStartDate?.elapsedString(to: workoutNow) ?? "00:00:00"
    }

    var body: some View {
        ZStack {
            // StrengthLab: white root background
            Color.white
                .ignoresSafeArea()

            Group {
                if isRegularWidth {
                    regularWidthView()
                } else {
                    compactWidthView()
                }
            }

            if let celebration = achievementManager?.pendingCelebration {
                AchievementCelebrationView(achievement: celebration) {
                    achievementManager?.dismissCelebration()
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .background(Color.white.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: achievementManager?.pendingCelebration != nil)
        .onAppear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                workoutNow = Date()
            }
        }
        .onDisappear {
            workoutToolbarTimer?.invalidate()
            workoutToolbarTimer = nil
        }
    }
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    // MARK: - iPAD
    @ViewBuilder
    private func regularWidthView() -> some View {
        NavigationSplitView {
            ZStack {
                NavigationStack {
                    VStack(spacing: 0) {
                        RoutineView(animateEntrance: animateDeckEntrance)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .navigationSplitViewColumnWidth(min: 360, ideal: 420, max: 520)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                editRoutineTip.invalidate(reason: .actionPerformed)
                                showingRoutineEditSheet = true
                            } label: {
                                Text("Edit Routine")
                                    .bold()
                            }
                            .tint(Color.greenStart)
                            .popoverTip(editRoutineTip, arrowEdge: .bottom)
                        }
                    }
                    .sheet(isPresented: $showingRoutineEditSheet) {
                        NavigationStack {
                            EditRoutineView()
                                .navigationTitle("Edit Routine")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .preferredColorScheme(.light)
                    }
                }
            }
        } detail: {
            NavigationStack(path: $viewModel.listPath) {
                ScrollView {
                    StatsView()
                    HealthView()
                }
                .navigationTitle("StrengthLab")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if isStrengthWorkoutActive {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(workoutElapsedString)
                                        .monospacedDigit()
                                }
                            }
                            .tint(Color.greenStart)
                            .accessibilityLabel("Strength workout running time")
                            .accessibilityValue(workoutElapsedString)
                        }
                        Button {
                            viewModel.showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettingsSheet) {
            NavigationStack {
                SettingsView()
                .interactiveDismissDisabled()
                .presentationDetents([.large])
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            viewModel.showingSettingsSheet = false
                        }
                    }
                }
            }
        }
        .onChange(of: pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onAppear {
            // Handle any pending deep link on appear
            if pendingDeepLink != nil {
                handleDeepLink(pendingDeepLink)
            }
        }
    }
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        // Reset the deep link after handling
        defer { pendingDeepLink = nil }

        switch link {
        case .routine:
            viewModel.appTab = .routine
        case .settings:
            viewModel.appTab = .settings
            viewModel.showingSettingsSheet = true
        case .stats:
            viewModel.appTab = .stats
        }
    }
    
    // MARK: - iPHONE
    
    @ViewBuilder
    private func compactWidthView() -> some View {
        TabView(
            selection:
                $viewModel.appTab
        ) {
            NavigationStack {
                WorkoutLibraryHomeView()
            }
            .tabItem {
                Label(
                    "Workouts",
                    systemImage:
                        "dumbbell.fill"
                )
            }
            .tag(AppTab.routine)

            NavigationStack {
                ExerciseLibraryHomeView()
            }
            .tabItem {
                Label(
                    "Exercises",
                    systemImage:
                        "list.bullet.rectangle.portrait"
                )
            }
            .tag(AppTab.exercises)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label(
                    "Stats",
                    systemImage:
                        "chart.xyaxis.line"
                )
            }
            .tag(AppTab.stats)

            NavigationStack {
                HealthView()
            }
            .tabItem {
                Label(
                    "Health",
                    systemImage:
                        "heart.fill"
                )
            }
            .tag(AppTab.health)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage:
                        "gearshape.fill"
                )
            }
            .tag(AppTab.settings)
        }
        .toolbar(
            .hidden,
            for: .tabBar
        )
        .preferredColorScheme(.light)
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            figmaTabBar
        }
    }

    private var figmaTabBar: some View {
        HStack(spacing: 0) {
            figmaTabButton(
                tab: .routine,
                icon:
                    "dumbbell.fill",
                title:
                    "Workouts"
            )

            figmaTabButton(
                tab: .exercises,
                icon:
                    "list.bullet.rectangle.portrait",
                title:
                    "Exercises"
            )

            figmaTabButton(
                tab: .stats,
                icon:
                    "chart.xyaxis.line",
                title:
                    "Stats"
            )

            figmaTabButton(
                tab: .health,
                icon:
                    "heart.fill",
                title:
                    "Health"
            )

            figmaTabButton(
                tab: .settings,
                icon:
                    "gearshape.fill",
                title:
                    "Settings"
            )
        }
        .frame(height: 76)
        .padding(.horizontal, 8)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.06),
                lineWidth: 1
            )
        }
        .shadow(
            color:
                Color.black.opacity(0.08),
            radius: 18,
            y: 7
        )
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color.white
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func figmaTabButton(
        tab: AppTab,
        icon: String,
        title: String
    ) -> some View {
        let selected =
            viewModel.appTab == tab

        return Button {
            Haptics.lightImpact()

            if tab == .exercises {
                print(
                    "[EXLIB DIAG] TAP Exercises | main=\(Thread.isMainThread)"
                )
            }

            withAnimation(
                .easeInOut(
                    duration: 0.18
                )
            ) {
                viewModel.appTab =
                    tab
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 20,
                            weight:
                                selected
                                ? .semibold
                                : .regular
                        )
                    )

                Text(title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(10)
                    )

                Circle()
                    .fill(
                        selected
                        ? StrengthLabFigmaTheme
                            .coral
                        : Color.clear
                    )
                    .frame(
                        width: 4,
                        height: 4
                    )
            }
            .foregroundStyle(
                selected
                ? StrengthLabFigmaTheme
                    .coral
                : StrengthLabFigmaTheme
                    .muted
            )
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 64)
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    // Seed routines with content for all days except Saturday (day 6)
    let dayIndices = [0, 1, 2, 3, 4, 5] // 0 = Sunday ... 5 = Friday
    for d in dayIndices {
        let routine = SetDeckRoutine.sample(day: d)
        context.insert(routine)
    }
    try? context.save()
    
    return MainView(pendingDeepLink: .constant(nil))
        .preferredColorScheme(.light)
        .modelContainer(container)
        .environment(ExerciseManager(context: context))
        .environment(HealthManager())

}

