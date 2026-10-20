//
//  HealthView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI
import Charts
import TipKit

struct HealthView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false
    
    // MARK: - Local input state
    @State private var newWaterIntakeOZ: Double = 8 // fluid ounces
    @State private var newCalorieIntake: Double = 300 // kcal (Calories)
    @State private var newCalorieBurn: Double = 200 // kcal

    @State private var isWaterExpanded: Bool = true
    @State private var isCaloriesExpanded: Bool = true

    @State private var didAddWater: Bool = false
    @State private var didAddFood: Bool = false

    // MARK: - Workout state
    @State private var workoutTimer: Timer? = nil
    @State private var now: Date = Date()
    @State private var isPulsing: Bool = false

    // TipKit
    private let recordWorkoutTip = RecordWorkoutTip()

    private var isStrengthWorkoutActive: Bool {
        healthManager.isStrengthTrainingActive
    }

    private var workoutStartDate: Date? {
        healthManager.currentWorkoutStartDate
    }

    private var workoutElapsedString: String {
        workoutStartDate?.elapsedString(to: now) ?? "00:00:00"
    }

    // MARK: - Unit & Date helpers
    private var waterUnitLabel: String { useMetricUnits ? "L" : "fl oz" }
    private var waterDisplayMax: Double { useMetricUnits ? 4.0 : 200 }
    private var waterStep: Double { useMetricUnits ? 0.1 : 4 }
    private var waterInputBinding: Binding<Double> {
        Binding(
            get: {
                // Under the hood we store ounces, but when metric is enabled we show liters.
                useMetricUnits ? (newWaterIntakeOZ * 29.5735) / 1000.0 : newWaterIntakeOZ
            },
            set: { newValue in
                if useMetricUnits {
                    // Convert liters back to ounces for storage.
                    newWaterIntakeOZ = (newValue * 1000.0) / 29.5735
                } else {
                    newWaterIntakeOZ = newValue
                }
            }
        )
    }
    private func axisDateString(_ date: Date) -> String {
        if useDayMonthYearDates {
            let df = DateFormatter()
            df.locale = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        }
    }

    private let energyUnitLabel: String = "cal"
    private let energyDisplayMax: Double = 5000
    private let energyStep: Double = 50
    private var energyInputBinding: Binding<Double> { Binding(get: { newCalorieIntake }, set: { newCalorieIntake = $0 }) }
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    healthHeader

                    recordWorkoutCard
                        .padding(.top, 30)

                    sectionHeading(
                        "Today's Information"
                    )
                    .padding(.top, 34)

                    todayCards
                        .padding(.top, 18)

                    sectionHeading("Hydration")
                        .padding(.top, 38)

                    hydrationCard
                        .padding(.top, 16)

                    sectionHeading("Energy")
                        .padding(.top, 38)

                    energyCard
                        .padding(.top, 16)

                    sectionHeading(
                        "Workout History"
                    )
                    .padding(.top, 38)

                    WorkoutHistorySectionView()
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await refreshHealthData()
        }
        .onAppear {
            workoutTimer?.invalidate()

            workoutTimer =
                Timer.scheduledTimer(
                    withTimeInterval: 1,
                    repeats: true
                ) { _ in
                    now = Date()
                }

            isPulsing =
                isStrengthWorkoutActive
        }
        .onDisappear {
            workoutTimer?.invalidate()
            workoutTimer = nil
            isPulsing = false
        }
        .tint(
            StrengthLabFigmaTheme.coral
        )
    }

    private var healthHeader: some View {
        HStack {
            Color.clear
                .frame(width: 56, height: 56)

            Spacer()

            Text("Health")
                .font(
                    StrengthLabFigmaTheme.bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

            Spacer()

            Button {
                Task {
                    await refreshHealthData()
                }
            } label: {
                FigmaNavIcon(
                    systemName:
                        "arrow.clockwise"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Refresh health data"
            )
        }
        .frame(height: 56)
    }

    private var recordWorkoutCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .blush
                )
                .frame(
                    width: 56,
                    height: 56
                )
                .overlay {
                    Image(
                        systemName:
                            "figure.strengthtraining.traditional"
                    )
                    .font(
                        .system(
                            size: 21,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .scaleEffect(
                        isStrengthWorkoutActive &&
                        isPulsing
                        ? 1.12
                        : 1
                    )
                }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    isStrengthWorkoutActive
                    ? "Workout Recording"
                    : "Record Workout"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

                if isStrengthWorkoutActive {
                    Text(workoutElapsedString)
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .monospacedDigit()
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                } else {
                    Text("Save to Apple Health")
                        .font(
                            StrengthLabFigmaTheme
                                .regular(13)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                }
            }

            Spacer()

            if isStrengthWorkoutActive {
                Button {
                    Task {
                        await healthManager
                            .stopStrengthTrainingWorkoutIfSupported()
                    }
                } label: {
                    Text("Stop")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(14)
                        )
                        .foregroundStyle(.white)
                        .padding(
                            .horizontal,
                            18
                        )
                        .frame(height: 45)
                        .background(
                            StrengthLabFigmaTheme
                                .coral,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    recordWorkoutTip
                        .invalidate(
                            reason:
                                .actionPerformed
                        )

                    Task {
                        await healthManager
                            .startStrengthTrainingWorkoutIfSupported()
                    }
                } label: {
                    Image(
                        systemName:
                            "play.fill"
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .coralGradient,
                        in: Circle()
                    )
                }
                .buttonStyle(.plain)
                .popoverTip(
                    recordWorkoutTip,
                    arrowEdge: .bottom
                )
            }
        }
        .padding(16)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.09),
                lineWidth: 1.5
            )
        }
    }

    private func sectionHeading(
        _ title: String
    ) -> some View {
        Text(title)
            .font(
                StrengthLabFigmaTheme
                    .bold(18)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.ink
            )
    }

    private var todayCards: some View {
        HStack(spacing: 14) {
            todayCard(
                title: "Water",
                value: todayWaterText,
                unit: waterUnitLabel,
                icon: "drop"
            )

            todayCard(
                title: "Energy",
                value:
                    "\(Int(todayCaloriesIn))",
                unit: "cal",
                icon: "fork.knife"
            )

            todayCard(
                title: "Burned",
                value:
                    "\(Int(todayCaloriesBurned))",
                unit: "cal",
                icon: "flame"
            )
        }
    }

    private func todayCard(
        title: String,
        value: String,
        unit: String,
        icon: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 13
        ) {
            HStack {
                Text(title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                Spacer()

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
            }

            Text(value)
                .font(
                    StrengthLabFigmaTheme
                        .bold(18)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(unit)
                .font(
                    StrengthLabFigmaTheme
                        .regular(11)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .frame(minHeight: 118)
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

    private var hydrationCard: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack {
                Label(
                    "Add Water",
                    systemImage: "drop.fill"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(15)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme.ink
                )

                Spacer()

                Text(waterInputText)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
            }

            Slider(
                value: waterInputBinding,
                in: 0...waterDisplayMax,
                step: waterStep
            )
            .tint(
                StrengthLabFigmaTheme.coral
            )

            Button {
                Task {
                    await addWaterIntake(
                        amountML:
                            newWaterIntakeOZ *
                            29.5735,
                        date: Date()
                    )

                    didAddWater.toggle()

                    await refreshHealthData()
                }
            } label: {
                Text("Add Water")
                    .font(
                        StrengthLabFigmaTheme
                            .medium(15)
                    )
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 50)
                    .background(
                        StrengthLabFigmaTheme
                            .coralGradient,
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)

            if !waterData.isEmpty {
                waterChart
                    .padding(.top, 4)
            }
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

    private var energyCard: some View {
        VStack(
            alignment: .leading,
            spacing: 22
        ) {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                HStack {
                    Text("Calories Consumed")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(15)
                        )

                    Spacer()

                    Text(
                        "\(Int(newCalorieIntake)) cal"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

                Slider(
                    value: energyInputBinding,
                    in: 0...energyDisplayMax,
                    step: energyStep
                )
                .tint(
                    StrengthLabFigmaTheme
                        .coral
                )

                Button {
                    Task {
                        await addCalorieIntake(
                            amount:
                                newCalorieIntake,
                            date: Date()
                        )

                        didAddFood.toggle()

                        await refreshHealthData()
                    }
                } label: {
                    Text("Add Food")
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                HStack {
                    Text("Calories Burned")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(15)
                        )

                    Spacer()

                    Text(
                        "\(Int(newCalorieBurn)) cal"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

                Slider(
                    value:
                        $newCalorieBurn,
                    in: 0...energyDisplayMax,
                    step: energyStep
                )
                .tint(
                    StrengthLabFigmaTheme
                        .coral
                )

                Button {
                    Task {
                        await addCalorieBurn(
                            amount:
                                newCalorieBurn,
                            date: Date()
                        )

                        await refreshHealthData()
                    }
                } label: {
                    Text("Add Burn")
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                }
                .buttonStyle(.plain)
            }

            if !intakeData.isEmpty {
                caloriesConsumedChart
            }

            if !burnData.isEmpty {
                caloriesBurnedChart
            }
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

    private var todayWaterML: Double {
        healthManager
            .waterIntakeSeries
            .filter {
                Calendar.current
                    .isDateInToday(
                        $0.date
                    )
            }
            .reduce(0) {
                $0 + $1.amount
            }
    }

    private var todayCaloriesIn: Double {
        healthManager
            .calorieIntakeSeries
            .filter {
                Calendar.current
                    .isDateInToday(
                        $0.date
                    )
            }
            .reduce(0) {
                $0 + $1.amount
            }
    }

    private var todayCaloriesBurned: Double {
        healthManager
            .calorieBurnSeries
            .filter {
                Calendar.current
                    .isDateInToday(
                        $0.date
                    )
            }
            .reduce(0) {
                $0 + $1.amount
            }
    }

    private var todayWaterText: String {
        if useMetricUnits {
            return String(
                format: "%.1f",
                todayWaterML / 1000
            )
        }

        return String(
            format: "%.0f",
            todayWaterML / 29.5735
        )
    }

    private var waterInputText: String {
        if useMetricUnits {
            return String(
                format: "%.1f L",
                waterInputBinding
                    .wrappedValue
            )
        }

        return
            "\(Int(waterInputBinding.wrappedValue)) fl oz"
    }

    private var waterData: [SeriesItem] { last7Days(waterSeries()) }
    private var intakeData: [SeriesItem] { last7Days(calorieIntakeSeries()) }
    private var burnData: [SeriesItem] { last7Days(calorieBurnSeries()) }
    
    private func last7Days(_ data: [SeriesItem]) -> [SeriesItem] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) else { return data }
        return data.filter { item in
            let day = cal.startOfDay(for: item.date)
            return day >= start
        }
        .sorted { $0.date < $1.date }
    }

    private var waterChart: some View {
        Chart(waterData) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value(waterUnitLabel, useMetricUnits ? item.amount / 1000.0 : item.amount / 29.5735)
            )
            .foregroundStyle(StrengthLabFigmaTheme.coral)
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text(
                        "\(useMetricUnits ? String(format: "%.1f", item.amount / 1000.0) : String(Int(item.amount / 29.5735))) \(waterUnitLabel)"
                    )
                    .font(.caption2).bold()
                }
            }
        }
        .frame(height: 160)
        .chartYAxisLabel(waterUnitLabel, position: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(axisDateString(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [StrengthLabFigmaTheme.coral.opacity(0.15), StrengthLabFigmaTheme.blush.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .chartForegroundStyleScale([waterUnitLabel: StrengthLabFigmaTheme.coral])
        .chartLegend(.hidden)
    }

    private var caloriesConsumedChart: some View {
        let intake: [SeriesItem] = self.intakeData

        return Chart {
            intakeArea(intake)
            intakeLine(intake)
        }
        .frame(height: 200)
        .chartYAxisLabel(energyUnitLabel, position: .leading)
        .chartXAxisLabel("Date")
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(axisDateString(date))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [StrengthLabFigmaTheme.coral.opacity(0.16), StrengthLabFigmaTheme.blush.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var caloriesBurnedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Calories Burned", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.red)

            let burn: [SeriesItem] = self.burnData

            Chart {
                burnLine(burn)
                burnArea(burn)
            }
            .frame(height: 200)
            .chartYAxisLabel(energyUnitLabel, position: .leading)
            .chartXAxisLabel("Date")
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(axisDateString(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.25), Color.red.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    @ChartContentBuilder
    private func intakeLine(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(Circle())
            .symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(StrengthLabFigmaTheme.coralGradient)
            .zIndex(1)
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(item.amount)) \(energyUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func intakeArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Intake", item.amount)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(LinearGradient(colors: [StrengthLabFigmaTheme.coral.opacity(0.20), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    @ChartContentBuilder
    private func burnLine(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            LineMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Burn", item.amount)
            )
            .interpolationMethod(.linear)
            .symbol(.square)
            .symbolSize(40)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(StrengthLabFigmaTheme.coralGradient)
            .annotation(position: .top) {
                if Calendar.current.isDateInToday(item.date) {
                    Text("\(Int(item.amount)) \(energyUnitLabel)")
                        .font(.caption2).bold()
                }
            }
        }
    }

    @ChartContentBuilder
    private func burnArea(_ data: [SeriesItem]) -> some ChartContent {
        ForEach(data) { item in
            AreaMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Burn", item.amount)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(LinearGradient(colors: [StrengthLabFigmaTheme.coral.opacity(0.20), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: - Data helpers & placeholders

    private struct SeriesItem: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }

    private func waterSeries() -> [SeriesItem] {
        let samples = healthManager.waterIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        // Fallback demo data
        return []
    }

    private func calorieIntakeSeries() -> [SeriesItem] {
        let samples = healthManager.calorieIntakeSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return []
    }

    private func calorieBurnSeries() -> [SeriesItem] {
        let samples = healthManager.calorieBurnSeries
        if !samples.isEmpty { return samples.map { SeriesItem(date: $0.date, amount: $0.amount) } }
        return []
    }

    private func demoSeries(days: Int, base: Double, variance: Double) -> [SeriesItem] {
        (0..<days).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let jitter = Double.random(in: -variance...variance)
            return SeriesItem(date: date, amount: max(0, base + jitter))
        }.sorted { $0.date < $1.date }
    }
    
    private func systemIconForWorkout(title: String, subtitle: String) -> String {
        let t = (title + " " + subtitle).lowercased()
        if t.contains("run") || t.contains("jog") { return "figure.run" }
        if t.contains("walk") || t.contains("hike") { return "figure.walk" }
        if t.contains("cycle") || t.contains("bike") { return "bicycle" }
        if t.contains("swim") { return "figure.pool.swim" }
        if t.contains("row") { return "figure.rower" }
        if t.contains("yoga") || t.contains("stretch") { return "figure.yoga" }
        if t.contains("strength") || t.contains("weights") || t.contains("lift") { return "figure.strengthtraining.traditional" }
        if t.contains("hiit") || t.contains("interval") { return "flame.fill" }
        if t.contains("pilates") { return "figure.mind.and.body" }
        if t.contains("stair") { return "figure.stairs" }
        if t.contains("ski") { return "figure.skiing.downhill" }
        if t.contains("elliptical") { return "figure.elliptical" }
        if t.contains("dance") { return "figure.dance" }
        return "figure.run"
    }

    private func addWaterIntake(amountML: Double, date: Date) async {
        await healthManager.addWaterIntakeIfSupported(amountML: amountML, date: date)
    }

    private func refreshHealthData() async {
        await healthManager.refreshIfSupported()
    }

    private func addCalorieIntake(amount: Double, date: Date) async {
        await healthManager.addCalorieIntakeIfSupported(amount: amount, date: date)
    }

    private func addCalorieBurn(amount: Double, date: Date) async {
        await healthManager.addCalorieBurnIfSupported(amount: amount, date: date)
    }
}

#Preview {
    HealthView()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

