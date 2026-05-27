import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject private var workoutStore: WorkoutStore

    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        ZStack {
            WorkoutScreenBackground()

            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Button {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.32))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.32))
                                .clipShape(Circle())
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(weekdaySymbols, id: \.self) { day in
                            Text(day)
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.85))
                        }

                        ForEach(monthGridDates(), id: \.self) { date in
                            if let date {
                                dayCell(for: date)
                            } else {
                                Color.clear
                                    .frame(height: 46)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected day")
                            .font(.headline.bold())
                            .foregroundColor(.white)

                        Text(selectedDate.formatted(date: .complete, time: .omitted))
                            .foregroundColor(.white.opacity(0.88))

                        let workouts = workoutStore.workouts(on: selectedDate)

                        if workouts.isEmpty {
                            Text("No workouts logged for this day.")
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            ForEach(workouts) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.displayTitle)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)

                                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))

                                    Text("Completed \(entry.completedSetCount) • Skipped \(entry.skippedSetCount)")
                                        .foregroundColor(.white.opacity(0.86))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.28))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(20)
                .padding(.top, 44)
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let hasWorkout = workoutStore.hasWorkout(on: date)

        Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Circle()
                    .fill(hasWorkout ? Color.green : Color.clear)
                    .frame(width: 7, height: 7)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(isSelected ? Color.blue.opacity(0.75) : Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(WorkoutPressStyle())
    }

    private func monthGridDates() -> [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday >= 0
            ? firstWeekday - calendar.firstWeekday
            : firstWeekday - calendar.firstWeekday + 7

        var dates: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }

        while dates.count % 7 != 0 {
            dates.append(nil)
        }

        return dates
    }
}
