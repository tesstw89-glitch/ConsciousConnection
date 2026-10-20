import SwiftUI
import SwiftData

struct WorkoutScheduleSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \WorkoutTemplate.updatedAt,
        order: .reverse
    )
    private var workouts:
        [WorkoutTemplate]

    @Query
    private var schedules:
        [WorkoutSchedule]

    @Query private var completedSetHistory: [SetDeckSetHistory]

    private struct CompletedSession: Identifiable {
        let id: String
        let name: String
        let finishedAt: Date
    }

    private func completedSessions(on date: Date) -> [CompletedSession] {
        var seen = Set<String>()
        return completedSetHistory.compactMap { record -> CompletedSession? in
            guard Calendar.current.isDate(record.completedDate, inSameDayAs: date),
                  let note = record.note,
                  note.hasPrefix("Workout · ") else { return nil }

            // Every set of one finished workout uses the same completedAt.
            // Group its sets, but allow another session later that day.
            let name = String(note.dropFirst("Workout · ".count))
            let key = "\(record.completedDate.timeIntervalSince1970)|\(name)"
            guard seen.insert(key).inserted else { return nil }
            return CompletedSession(id: key, name: name, finishedAt: record.completedDate)
        }
        .sorted { $0.finishedAt < $1.finishedAt }
    }

    @State private var programStore = StrengthLabProgramStore.shared
    @State private var scheduleError = ""
    @State private var showingScheduleError = false

    private var activeWorkouts: [WorkoutTemplate] {
        guard programStore.activeProgram != nil else { return workouts }
        return workouts.filter { programStore.containsWorkout($0.uuid) }
    }

    private var activeSchedules: [WorkoutSchedule] {
        guard programStore.activeProgram != nil else { return schedules }
        return schedules.filter { programStore.containsSchedule($0.uuid) }
    }

    let workout:
        WorkoutTemplate?

    @State
    private var selectedDate =
        Date()

    @State
    private var repeatsWeekly =
        false

    init(
        workout:
            WorkoutTemplate? = nil
    ) {
        self.workout = workout
    }

    private var calendar:
        Calendar
    {
        Calendar.current
    }

    var body: some View {
        ZStack {
            StrengthLabContourBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Text(headerDate)
                    .font(
                        StrengthLabFigmaTheme
                            .medium(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .padding(.top, 40)

                calendarGrid
                    .padding(.horizontal, 24)
                    .padding(.top, 30)

                Spacer(minLength: 20)

                schedulePanel
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            do { try programStore.prepare(workouts: workouts, schedules: schedules) }
            catch { reportScheduleError(error) }
        }
        .alert("Schedule Error", isPresented: $showingScheduleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(scheduleError)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                FigmaNavIcon(
                    systemName:
                        "chevron.left"
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Calendar")
                .font(
                    StrengthLabFigmaTheme
                        .bold(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

            Spacer()

            Menu {
                Button {
                    repeatsWeekly
                        .toggle()
                } label: {
                    Label(
                        repeatsWeekly
                        ? "Use one-time schedule"
                        : "Repeat every week",
                        systemImage:
                            repeatsWeekly
                            ? "calendar"
                            : "repeat"
                    )
                }
            } label: {
                FigmaNavIcon(
                    systemName:
                        "ellipsis"
                )
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
    }

    // MARK: Calendar

    private var calendarGrid:
        some View
    {
        VStack(spacing: 17) {
            LazyVGrid(
                columns:
                    Array(
                        repeating:
                            GridItem(
                                .flexible()
                            ),
                        count: 7
                    ),
                spacing: 17
            ) {
                ForEach(
                    weekdayItems,
                    id: \.0
                ) {
                    weekday,
                    title in

                    Text(title)
                        .font(
                            StrengthLabFigmaTheme
                                .regular(14)
                        )
                        .foregroundStyle(
                            weekday ==
                            calendar.component(
                                .weekday,
                                from:
                                    selectedDate
                            )
                            ? StrengthLabFigmaTheme
                                .ink
                            : StrengthLabFigmaTheme
                                .coral
                        )
                        .frame(height: 24)
                }

                ForEach(
                    monthGrid.indices,
                    id: \.self
                ) { index in
                    if
                        let date =
                            monthGrid[index]
                    {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(
                                height: 36
                            )
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(
                minimumDistance: 30
            )
            .onEnded { value in
                if
                    value.translation.width
                    < -40
                {
                    shiftMonth(1)
                } else if
                    value.translation.width
                    > 40
                {
                    shiftMonth(-1)
                }
            }
        )
    }

    private func dayCell(
        _ date: Date
    ) -> some View {
        let selected =
            calendar.isDate(
                date,
                inSameDayAs:
                    selectedDate
            )

        let scheduled =
            activeSchedules.contains {
                $0.matches(date)
            }
        let completed = !completedSessions(on: date).isEmpty

        return Button {
            selectedDate = date
        } label: {
            ZStack(
                alignment: .bottom
            ) {
                if selected {
                    Circle()
                        .fill(
                            StrengthLabFigmaTheme
                                .coral
                        )
                        .frame(
                            width: 40,
                            height: 40
                        )
                }

                Text(
                    "\(calendar.component(.day, from: date))"
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(14)
                )
                .foregroundStyle(
                    selected
                    ? Color.white
                    : StrengthLabFigmaTheme
                        .ink
                )
                .frame(
                    width: 40,
                    height: 36
                )

                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selected ? Color.white : Color.green)
                        .offset(y: 8)
                } else if scheduled && !selected {
                    Capsule()
                        .fill(StrengthLabFigmaTheme.coral)
                        .frame(width: 22, height: 2)
                        .offset(y: 5)
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }

    // MARK: Bottom sheet

    private var schedulePanel:
        some View
    {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HStack(
                alignment: .top
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(panelTitle)
                        .font(
                            StrengthLabFigmaTheme
                                .bold(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )

                    Text(
                        repeatsWeekly
                        ? "Repeats every \(selectedDate.formatted(.dateTime.weekday(.wide)))"
                        : "One-time schedule"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(14)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Spacer()

                Button {
                    repeatsWeekly
                        .toggle()
                } label: {
                    Text(
                        repeatsWeekly
                        ? "Weekly"
                        : "Once"
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
                .buttonStyle(.plain)
            }

            scheduleAction
                .padding(.top, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    if !completedSessions(on: selectedDate).isEmpty {
                        Text("COMPLETED")
                            .font(StrengthLabFigmaTheme.bold(11))
                            .foregroundStyle(Color.green)
                            .padding(.top, 20)
                        ForEach(completedSessions(on: selectedDate)) { session in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.green)
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(session.name)
                                        .font(StrengthLabFigmaTheme.medium(14))
                                        .foregroundStyle(StrengthLabFigmaTheme.ink)
                                    Text("Completed · \(session.finishedAt.formatted(date: .omitted, time: .shortened))")
                                        .font(StrengthLabFigmaTheme.medium(12))
                                        .foregroundStyle(StrengthLabFigmaTheme.muted)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
                        }
                    }
                    Text("SCHEDULED")
                        .font(StrengthLabFigmaTheme.bold(11))
                        .foregroundStyle(StrengthLabFigmaTheme.coral)
                        .padding(.top, 20)
                    if panelSchedules.isEmpty {
                        Text("Nothing scheduled here yet.")
                            .font(StrengthLabFigmaTheme.medium(14))
                            .foregroundStyle(StrengthLabFigmaTheme.muted)
                    } else {
                        ForEach(panelSchedules, id: \.uuid) { schedule in
                            scheduleRow(schedule)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: 0)
        }
        .padding(
            .horizontal,
            24
        )
        .padding(.top, 38)
        .frame(
            maxWidth: .infinity,
            minHeight: 324,
            alignment: .top
        )
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 36,
                style: .continuous
            )
        )
        .ignoresSafeArea(
            edges: .bottom
        )
    }

    @ViewBuilder
    private var scheduleAction:
        some View
    {
        if let workout {
            Button {
                addSchedule(
                    for: workout
                )
            } label: {
                HStack {
                    Image(
                        systemName:
                            "calendar.badge.plus"
                    )

                    Text(
                        "Schedule \(workout.name)"
                    )
                        .lineLimit(1)
                }
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
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
        } else {
            Menu {
                ForEach(activeWorkouts) {
                    workout in

                    Button(workout.name) {
                        addSchedule(
                            for: workout
                        )
                    }
                }
            } label: {
                HStack {
                    Image(
                        systemName:
                            "calendar.badge.plus"
                    )

                    Text("Schedule Workout")

                    Spacer()

                    Image(
                        systemName:
                            "chevron.down"
                    )
                }
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    18
                )
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
            .disabled(activeWorkouts.isEmpty)
        }
    }

    private func scheduleRow(
        _ schedule:
            WorkoutSchedule
    ) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .coralGradient
                )
                .frame(
                    width: 56,
                    height: 56
                )
                .overlay {
                    Image(
                        systemName:
                            "dumbbell.fill"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    schedule.workout?
                        .name ??
                    "Workout"
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

                Text(
                    schedule.repeatsWeekly
                    ? "Every \(schedule.scheduledDate.formatted(.dateTime.weekday(.wide)))"
                    : schedule
                        .scheduledDate
                        .formatted(
                            date:
                                .abbreviated,
                            time:
                                .omitted
                        )
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
            }

            Spacer()

            Image(
                systemName:
                    schedule.repeatsWeekly
                    ? "repeat"
                    : "calendar"
            )
            .font(
                .system(
                    size: 16,
                    weight: .medium
                )
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )
        }
        .padding(.horizontal, 8)
        .frame(height: 72)
        .overlay {
            RoundedRectangle(
                cornerRadius: 36,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.08),
                lineWidth: 1.5
            )
        }
        .contextMenu {
            Button(
                role: .destructive
            ) {
                deleteSchedule(
                    schedule
                )
            } label: {
                Label(
                    "Remove Schedule",
                    systemImage:
                        "trash"
                )
            }
        }
    }

    // MARK: Calendar data

    private var monthGrid:
        [Date?]
    {
        guard
            let monthStart =
                calendar.date(
                    from:
                        calendar
                            .dateComponents(
                                [
                                    .year,
                                    .month
                                ],
                                from:
                                    selectedDate
                            )
                ),
            let dayRange =
                calendar.range(
                    of: .day,
                    in: .month,
                    for: monthStart
                )
        else {
            return []
        }

        let firstWeekday =
            calendar.component(
                .weekday,
                from: monthStart
            )

        let leading =
            (
                firstWeekday -
                calendar.firstWeekday +
                7
            ) % 7

        var values:
            [Date?] =
            Array(
                repeating: nil,
                count: leading
            )

        for day in dayRange {
            if
                let date =
                    calendar.date(
                        byAdding:
                            .day,
                        value:
                            day - 1,
                        to:
                            monthStart
                    )
            {
                values.append(date)
            }
        }

        while
            !values.isEmpty &&
            values.count % 7 != 0
        {
            values.append(nil)
        }

        return values
    }

    private var weekdayItems:
        [(Int, String)]
    {
        let symbols =
            calendar
                .shortWeekdaySymbols

        return (0..<7).map {
            offset in

            let weekday =
                (
                    calendar
                        .firstWeekday -
                    1 +
                    offset
                ) % 7 + 1

            return (
                weekday,
                String(
                    symbols[
                        weekday - 1
                    ]
                    .prefix(3)
                )
            )
        }
    }

    private var headerDate:
        String
    {
        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "EEEE, dd MMMM"

        return formatter.string(
            from: selectedDate
        )
    }

    private var panelTitle:
        String
    {
        if let workout {
            let count =
                activeSchedules.filter {
                    $0.workout?.uuid ==
                        workout.uuid
                }.count

            return
                "\(count) " +
                (
                    count == 1
                    ? "Schedule"
                    : "Schedules"
                )
        }

        let count =
            panelSchedules.count

        return
            "\(count) " +
            (
                count == 1
                ? "Workout"
                : "Workouts"
            )
    }

    private var panelSchedules:
        [WorkoutSchedule]
    {
        if let workout {
            return activeSchedules
                .filter {
                    $0.workout?.uuid ==
                        workout.uuid
                }
                .sorted {
                    $0.scheduledDate <
                        $1.scheduledDate
                }
        }

        return activeSchedules
            .filter {
                $0.matches(
                    selectedDate
                )
            }
            .sorted {
                (
                    $0.workout?.name ??
                    ""
                ) <
                (
                    $1.workout?.name ??
                    ""
                )
            }
    }

    private func shiftMonth(
        _ amount: Int
    ) {
        if
            let newDate =
                calendar.date(
                    byAdding:
                        .month,
                    value:
                        amount,
                    to:
                        selectedDate
                )
        {
            withAnimation(
                .easeInOut(
                    duration: 0.22
                )
            ) {
                selectedDate =
                    newDate
            }
        }
    }

    // MARK: Schedule actions

    private func addSchedule(
        for workout:
            WorkoutTemplate
    ) {
        let normalized =
            calendar.startOfDay(
                for: selectedDate
            )

        let duplicate =
            activeSchedules.contains {
                schedule in

                guard
                    schedule.workout?
                        .uuid ==
                        workout.uuid,
                    schedule
                        .repeatsWeekly ==
                        repeatsWeekly
                else {
                    return false
                }

                if repeatsWeekly {
                    return
                        calendar.component(
                            .weekday,
                            from:
                                schedule
                                    .scheduledDate
                        ) ==
                        calendar.component(
                            .weekday,
                            from:
                                normalized
                        )
                }

                return
                    calendar.isDate(
                        schedule
                            .scheduledDate,
                        inSameDayAs:
                            normalized
                    )
            }

        guard !duplicate
        else {
            return
        }

        let schedule =
            WorkoutSchedule(
                scheduledDate:
                    normalized,
                repeatsWeekly:
                    repeatsWeekly,
                workout:
                    workout
            )

        modelContext.insert(
            schedule
        )

        var current =
            workout.schedules ?? []

        current.append(
            schedule
        )

        workout.schedules =
            current

        workout.updatedAt =
            Date()

        do {
            try modelContext.save()
            try programStore.addSchedule(schedule.uuid)
        } catch {
            // Only undo the newly-added schedule if programme registration fails.
            // Existing workout/exercise data and imported files remain untouched.
            modelContext.delete(schedule)
            try? modelContext.save()
            reportScheduleError(error)
        }
    }

    private func deleteSchedule(_ schedule: WorkoutSchedule) {
        do {
            try programStore.removeSchedule(schedule.uuid)
            if !programStore.scheduleIsReferenced(schedule.uuid) {
                modelContext.delete(schedule)
                try modelContext.save()
            }
        } catch {
            reportScheduleError(error)
        }
    }

    private func reportScheduleError(_ error: Error) {
        scheduleError = error.localizedDescription
        showingScheduleError = true
    }

}
