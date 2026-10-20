import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Environment(ExerciseManager.self)
    private var exerciseManager:
        ExerciseManager

    @Environment(AchievementManager.self)
    private var achievementManager:
        AchievementManager?

    @AppStorage(
        AppStorageKeys.useMetricUnits
    )
    private var useMetricUnits = false

    @AppStorage(
        AppStorageKeys.useDayMonthYearDates
    )
    private var useDayMonthYearDates = false

    @State
    private var viewModel = ViewModel()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    settingsHeader

                    sectionTitle("Preferences")
                        .padding(.top, 38)

                    VStack(spacing: 28) {
                        toggleRow(
                            icon: "drop",
                            title:
                                "Display Water in Liters",
                            isOn:
                                $useMetricUnits
                        )

                        toggleRow(
                            icon: "calendar",
                            title:
                                "Day–Month–Year Dates",
                            isOn:
                                $useDayMonthYearDates
                        )
                    }
                    .padding(.top, 24)

                    sectionTitle("StrengthLab")
                        .padding(.top, 46)

                    aboutCard
                        .padding(.top, 18)

                    sectionTitle("Progress")
                        .padding(.top, 42)

                    Button {
                        Haptics.lightImpact()
                        viewModel
                            .showAchievementsSheet =
                            true
                    } label: {
                        navigationRow(
                            icon: "trophy",
                            title:
                                "Achievements",
                            trailing:
                                achievementText
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 18)

                    sectionTitle("Danger Zone")
                        .padding(.top, 50)

                    VStack(spacing: 26) {
                        dangerButton(
                            icon:
                                "clock.arrow.circlepath",
                            title:
                                "Clear Set History"
                        ) {
                            viewModel
                                .showDeleteConfirmation =
                                true
                        }

                        dangerButton(
                            icon: "trash",
                            title:
                                "Delete All Workouts"
                        ) {
                            viewModel
                                .showDeleteRoutinesConfirmation =
                                true
                        }

                        dangerButton(
                            icon: "trophy",
                            title:
                                "Reset Achievements"
                        ) {
                            viewModel
                                .showResetAchievementsConfirmation =
                                true
                        }
                    }
                    .padding(.top, 22)

                    Text(
                        "These actions cannot be undone."
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                    .padding(.top, 18)

                    #if DEBUG
                    sectionTitle("Debug")
                        .padding(.top, 48)

                    Button {
                        viewModel
                            .showGenerateSampleDataConfirmation =
                            true
                    } label: {
                        navigationRow(
                            icon:
                                "wand.and.stars",
                            title:
                                "Generate Sample Data",
                            trailing: nil
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 18)
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 50)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .tint(
            StrengthLabFigmaTheme.coral
        )
        .sheet(
            isPresented:
                $viewModel
                    .showAchievementsSheet
        ) {
            NavigationStack {
                AchievementsView(
                    unlockedAchievements:
                        achievementManager?
                            .unlockedAchievements ??
                        []
                )
            }
            .preferredColorScheme(.light)
        }
        .alert(
            "Clear Set History?",
            isPresented:
                $viewModel
                    .showDeleteConfirmation
        ) {
            Button(
                "Delete History",
                role: .destructive
            ) {
                Haptics.lightImpact()
                exerciseManager
                    .clearAllHistory()
                viewModel
                    .showHistoryClearedAlert =
                    true
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }
        } message: {
            Text(
                "This permanently removes historical set data. Your workouts and exercises remain."
            )
        }
        .alert(
            "History Cleared",
            isPresented:
                $viewModel
                    .showHistoryClearedAlert
        ) {
            Button(
                "OK",
                role: .cancel
            ) { }
        }
        .alert(
            "Delete All Workouts?",
            isPresented:
                $viewModel
                    .showDeleteRoutinesConfirmation
        ) {
            Button(
                "Delete Everything",
                role: .destructive
            ) {
                Haptics.lightImpact()
                deleteAllWorkoutData()

                viewModel
                    .showRoutinesDeletedAlert =
                    true
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }
        } message: {
            Text(
                "This permanently deletes all workout templates, schedules, exercises, sets and legacy routines."
            )
        }
        .alert(
            "Workouts Deleted",
            isPresented:
                $viewModel
                    .showRoutinesDeletedAlert
        ) {
            Button(
                "OK",
                role: .cancel
            ) { }
        }
        .alert(
            "Reset Achievements?",
            isPresented:
                $viewModel
                    .showResetAchievementsConfirmation
        ) {
            Button(
                "Reset",
                role: .destructive
            ) {
                achievementManager?
                    .resetAllAchievements()

                viewModel
                    .showAchievementsResetAlert =
                    true
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }
        } message: {
            Text(
                "Achievement progress will return to zero."
            )
        }
        .alert(
            "Achievements Reset",
            isPresented:
                $viewModel
                    .showAchievementsResetAlert
        ) {
            Button(
                "OK",
                role: .cancel
            ) { }
        }
        #if DEBUG
        .alert(
            "Generate Sample Data?",
            isPresented:
                $viewModel
                    .showGenerateSampleDataConfirmation
        ) {
            Button("Generate") {
                exerciseManager
                    .generateSampleDataForLast30Days()

                viewModel
                    .showSampleDataGeneratedAlert =
                    true
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }
        }
        .alert(
            "Sample Data Generated",
            isPresented:
                $viewModel
                    .showSampleDataGeneratedAlert
        ) {
            Button(
                "OK",
                role: .cancel
            ) { }
        }
        #endif
    }

    private var settingsHeader: some View {
        HStack {
            Color.clear
                .frame(
                    width: 56,
                    height: 56
                )

            Spacer()

            Text("Settings")
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Spacer()

            Menu {
                Button {
                    viewModel
                        .showAchievementsSheet =
                        true
                } label: {
                    Label(
                        "Achievements",
                        systemImage:
                            "trophy"
                    )
                }
            } label: {
                FigmaNavIcon(
                    systemName:
                        "ellipsis"
                )
            }
        }
        .frame(height: 56)
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title)
            .font(
                StrengthLabFigmaTheme
                    .regular(18)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.ink
            )
    }

    private func toggleRow(
        icon: String,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 24) {
            iconBubble(icon)

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Spacer()

            Toggle(
                "",
                isOn: isOn
            )
            .labelsHidden()
            .tint(
                StrengthLabFigmaTheme.coral
            )
            .onChange(
                of: isOn.wrappedValue
            ) {
                Haptics.lightImpact()
            }
        }
        .frame(minHeight: 48)
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("StrengthLab")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(16)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                    Text(
                        "Version \(viewModel.appVersion)"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Spacer()

                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .blush
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .overlay {
                        Image(
                            systemName:
                                "dumbbell.fill"
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                    }
            }

            Divider()
                .padding(.vertical, 16)

            Text(
                "Built from the open-source SetDeck foundation. License and third-party notices remain bundled with the project."
            )
            .font(
                StrengthLabFigmaTheme
                    .regular(13)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.muted
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(18)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.09),
                lineWidth: 1.3
            )
        }
    }

    private var achievementText: String? {
        guard let manager =
            achievementManager
        else {
            return nil
        }

        return
            "\(manager.unlockedAchievements.count)/\(Achievement.allCases.count)"
    }

    private func navigationRow(
        icon: String,
        title: String,
        trailing: String?
    ) -> some View {
        HStack(spacing: 24) {
            iconBubble(icon)

            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(
                        StrengthLabFigmaTheme
                            .regular(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
            }

            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .system(
                    size: 14,
                    weight: .bold
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )
        }
        .frame(minHeight: 48)
    }

    private func iconBubble(
        _ icon: String
    ) -> some View {
        Circle()
            .fill(
                StrengthLabFigmaTheme
                    .blush
            )
            .frame(
                width: 48,
                height: 48
            )
            .overlay {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
            }
    }

    private func dangerButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.lightImpact()
            action()
        } label: {
            HStack(spacing: 24) {
                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .coral
                            .opacity(0.10)
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .overlay {
                        Image(
                            systemName: icon
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                    }

                Text(title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .coral
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func deleteAllWorkoutData() {
        if let schedules =
            try? modelContext.fetch(
                FetchDescriptor<
                    WorkoutSchedule
                >()
            )
        {
            for schedule in schedules {
                modelContext.delete(
                    schedule
                )
            }
        }

        if let workouts =
            try? modelContext.fetch(
                FetchDescriptor<
                    WorkoutTemplate
                >()
            )
        {
            for workout in workouts {
                modelContext.delete(
                    workout
                )
            }
        }

        exerciseManager
            .deleteAllRoutines()

        try? modelContext.save()
    }
}
