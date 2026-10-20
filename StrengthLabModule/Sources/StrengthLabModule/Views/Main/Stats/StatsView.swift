//
//  StatsView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(ExerciseManager.self) private var exerciseManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @State private var viewModel: ViewModel = ViewModel()
    @State private var range: TimeRange = .last30Days
    @State private var selectedExerciseName: String?
    @State private var inferredMuscleGroups: [String: [MuscleGroup]] = [:]
    @State private var isLoadingMuscleAnalysis: Bool = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    statsHeader

                    rangeSelector
                        .padding(.top, 24)

                    if filteredHistory.isEmpty {
                        emptyStateView
                            .padding(.top, 46)
                    } else {
                        figmaStatsContent
                            .padding(.top, 42)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.isMuscleAnalysisAvailable &&
                inferredMuscleGroups.isEmpty {
                isLoadingMuscleAnalysis = true
                inferredMuscleGroups =
                    await viewModel
                        .inferMuscleGroupsForHistory(
                            allHistory
                        )
                isLoadingMuscleAnalysis = false
            }
        }
        .onChange(of: allHistory.count) {
            if viewModel.isMuscleAnalysisAvailable {
                Task {
                    isLoadingMuscleAnalysis = true
                    inferredMuscleGroups =
                        await viewModel
                            .inferMuscleGroupsForHistory(
                                allHistory
                            )
                    isLoadingMuscleAnalysis = false
                }
            }
        }
        .tint(StrengthLabFigmaTheme.coral)
    }

    private var statsHeader: some View {
        HStack {
            Color.clear
                .frame(width: 56, height: 56)

            Spacer()

            Text("Stats")
                .font(
                    StrengthLabFigmaTheme.bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Spacer()

            Menu {
                ForEach(
                    TimeRange.allCases,
                    id: \.self
                ) { option in
                    Button(option.title) {
                        range = option
                    }
                }
            } label: {
                FigmaNavIcon(
                    systemName:
                        "slider.horizontal.3"
                )
            }
        }
        .frame(height: 56)
    }

    private var rangeSelector: some View {
        HStack(spacing: 3) {
            ForEach(
                TimeRange.allCases,
                id: \.self
            ) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        range = option
                    }
                } label: {
                    Text(option.title)
                        .font(
                            StrengthLabFigmaTheme
                                .bold(12)
                        )
                        .foregroundStyle(
                            range == option
                            ? StrengthLabFigmaTheme.coral
                            : StrengthLabFigmaTheme.ink
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 30)
                        .background(
                            range == option
                            ? Color.white
                            : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            StrengthLabFigmaTheme
                .coral
                .opacity(0.10),
            in: Capsule()
        )
    }

    private var figmaStatsContent: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            VStack(spacing: 3) {
                Text(
                    formattedVolume(totalVolume)
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(36)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

                Text(
                    useMetricUnits
                    ? "kg volume"
                    : "lb volume"
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.muted
                )
            }
            .frame(maxWidth: .infinity)

            Chart(dailyVolumePoints) { point in
                AreaMark(
                    x: .value(
                        "Date",
                        point.date
                    ),
                    y: .value(
                        "Volume",
                        point.volume
                    )
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            StrengthLabFigmaTheme
                                .coral
                                .opacity(0.20),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value(
                        "Date",
                        point.date
                    ),
                    y: .value(
                        "Volume",
                        point.volume
                    )
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.coral
                )
            }
            .frame(height: 175)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(
                    values: .automatic(
                        desiredCount: 7
                    )
                ) { value in
                    AxisValueLabel {
                        if let date =
                            value.as(Date.self) {
                            Text(
                                date.formatted(
                                    .dateTime
                                        .weekday(.narrow)
                                )
                            )
                            .font(
                                StrengthLabFigmaTheme
                                    .regular(11)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .muted
                            )
                        }
                    }
                }
            }
            .padding(.top, 20)

            HStack {
                Text("Training Summary")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(18)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme.ink
                    )

                Spacer()

                Text(range.title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme.ink
                    )
            }
            .padding(.top, 28)

            HStack(spacing: 0) {
                statMetric(
                    icon: "square.stack.3d.up",
                    value: "\(filteredHistory.count)",
                    label: "Sets"
                )

                statMetric(
                    icon: "calendar",
                    value: "\(activeDayCount)",
                    label: "Active days"
                )

                statMetric(
                    icon: "flame",
                    value: "\(bestStreak)",
                    label: "Best streak"
                )
            }
            .padding(.top, 28)

            if !exerciseNames.isEmpty {
                Text("Progress")
                    .font(
                        StrengthLabFigmaTheme
                            .bold(18)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme.ink
                    )
                    .padding(.top, 42)
                    .padding(.bottom, 14)

                ExercisePRCardView(
                    exerciseNames:
                        exerciseNames,
                    prs:
                        exercisePRs
                )

                let selected =
                    selectedExerciseName ??
                    exerciseNames.first

                let selectedPoints =
                    selected.flatMap {
                        exercise1RMPoints[$0]
                    } ?? []

                ExerciseDetailCardView(
                    exerciseNames:
                        exerciseNames,
                    selectedExerciseName:
                        $selectedExerciseName,
                    points:
                        selectedPoints
                )
                .padding(.top, 14)

                IntensityDistributionCard(
                    history: filteredHistory
                )
                .padding(.top, 14)
            }

            if viewModel.isMuscleAnalysisAvailable {
                if isLoadingMuscleAnalysis {
                    ProgressView()
                        .tint(
                            StrengthLabFigmaTheme.coral
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 40)
                } else if
                    !weeklyMuscleVolumes.isEmpty {
                    Text("Muscle Analysis")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(18)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme.ink
                        )
                        .padding(.top, 42)
                        .padding(.bottom, 14)

                    MuscleHeatmapCardView(
                        muscleVolumes:
                            weeklyMuscleVolumes
                    )

                    MuscleDistributionCardView(
                        muscleVolumes:
                            weeklyMuscleVolumes
                    )
                    .padding(.top, 14)

                    BalanceAnalysisCardView(
                        muscleVolumes:
                            weeklyMuscleVolumes
                    )
                    .padding(.top, 14)
                }
            }
        }
    }

    private func statMetric(
        icon: String,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Text(value)
                .font(
                    StrengthLabFigmaTheme
                        .bold(18)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Text(label)
                .font(
                    StrengthLabFigmaTheme
                        .regular(13)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedVolume(
        _ value: Double
    ) -> String {
        if value >= 1000000 {
            return String(
                format: "%.1fM",
                value / 1000000
            )
        }

        if value >= 1000 {
            return String(
                format: "%.1fk",
                value / 1000
            )
        }

        return String(
            format: "%.0f",
            value
        )
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .coral
                        .opacity(0.10)
                )
                .frame(
                    width: 84,
                    height: 84
                )
                .overlay {
                    Image(
                        systemName:
                            "chart.xyaxis.line"
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

            Text("Your Stats Await")
                .font(
                    StrengthLabFigmaTheme
                        .bold(24)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .padding(.top, 22)

            Text(
                "Complete some sets and your training trends will appear here."
            )
            .font(
                StrengthLabFigmaTheme
                    .regular(15)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.muted
            )
            .multilineTextAlignment(
                .center
            )
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .padding(.top, 9)

            VStack(spacing: 24) {
                emptyMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Volume Tracking",
                    subtitle:
                        "See how much work you're doing over time."
                )

                emptyMetric(
                    icon: "trophy",
                    title: "Personal Records",
                    subtitle:
                        "Follow your strongest lifts and estimated maxes."
                )

                emptyMetric(
                    icon: "flame",
                    title: "Workout Streaks",
                    subtitle:
                        "Watch consistency build across your training."
                )
            }
            .padding(.top, 38)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyMetric(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 24) {
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

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                Text(subtitle)
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer()
        }
    }

    var allHistory: [SetDeckSetHistory] {
        // Read changeStamp to trigger view updates when ExerciseManager saves
        let _ = exerciseManager.changeStamp
        return exerciseManager.allHistoryEntries()
    }
    var filteredHistory: [SetDeckSetHistory] {
        viewModel.filteredHistory(allHistory, range: range)
    }

    var totalVolume: Double {
        viewModel.totalVolume(filteredHistory: filteredHistory, useMetricUnits: useMetricUnits)
    }

    var activeDayCount: Int {
        viewModel.activeDayCount(filteredHistory: filteredHistory)
    }

    var bestStreak: Int {
        viewModel.bestStreak(filteredHistory: filteredHistory)
    }

    struct VolumePoint: Identifiable {
        let date: Date
        let volume: Double
        var id: Date { date }
    }

    var dailyVolumePoints: [VolumePoint] {
        viewModel.dailyVolumePoints(filteredHistory: filteredHistory, useMetricUnits: useMetricUnits)
    }

    var exerciseNames: [String] {
        viewModel.exerciseNames(filteredHistory: filteredHistory)
    }

    struct PRSummary {
        let exerciseName: String
        let bestWeight: Double
        let bestDate: Date
        let best1RM: Double
    }

    var exercisePRs: [PRSummary] {
        viewModel.exercisePRs(filteredHistory: filteredHistory)
    }

    struct OneRMPoint: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    var exercise1RMPoints: [String: [OneRMPoint]] {
        viewModel.exercise1RMPoints(filteredHistory: filteredHistory)
    }

    var weeklyMuscleVolumes: [MuscleGroup: Double] {
        viewModel.thisWeekMuscleVolumes(allHistory: allHistory, inferredMuscleGroups: inferredMuscleGroups)
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)

    // Seed routines and exercises for preview
    if (try? context.fetch(FetchDescriptor<SetDeckRoutine>()))?.isEmpty ?? true {
        for day in 0..<3 {
            let routine = SetDeckRoutine.sample(day: day)
            context.insert(routine)
            for _ in 0..<2 {
                let ex = SetDeckExercise.sample(setCount: 3)
                ex.routine = routine
                context.insert(ex)
                for set in ex.sets ?? [] {
                    context.insert(set)
                }
            }
        }
        try? context.save()
    }

    return StatsView()
        .environment(exerciseManager)
        .modelContainer(container)
}
