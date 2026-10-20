import SwiftUI
import SwiftData

struct DayPickerView: View {
    @Binding var selectedDay: Int

    @Environment(ExerciseManager.self)
    private var exerciseManager

    private let accent = Color(
        red: 0.78,
        green: 0.95,
        blue: 0.25
    )

    private let days = [
        "S", "M", "T", "W", "T", "F", "S"
    ]

    private var todayIndex: Int {
        let weekday =
            Calendar.current.component(
                .weekday,
                from: Date()
            )

        return (weekday - 1 + 7) % 7
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<7, id: \.self) { index in
                let selected =
                    selectedDay == index

                Button {
                    withAnimation(
                        .snappy(duration: 0.25)
                    ) {
                        selectedDay = index
                    }

                    Haptics.lightImpact()
                } label: {
                    VStack(spacing: 5) {
                        Text(days[index])
                            .font(
                                .subheadline
                                    .weight(.bold)
                            )

                        Circle()
                            .fill(
                                index == todayIndex
                                    ? (
                                        selected
                                            ? Color.black
                                            : accent
                                    )
                                    : Color.clear
                            )
                            .frame(width: 4, height: 4)
                    }
                    .foregroundStyle(
                        selected
                            ? .black
                            : .primary
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 48
                    )
                    .background(
                        selected
                            ? AnyShapeStyle(accent)
                            : AnyShapeStyle(
                                Color(
                                    .secondarySystemGroupedBackground
                                )
                            )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                        .stroke(
                            Color.primary.opacity(
                                selected ? 0 : 0.06
                            ),
                            lineWidth: 1
                        )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if ProcessInfo.processInfo
                .environment[
                    "XCODE_RUNNING_FOR_PREVIEWS"
                ] != "1"
            {
                DispatchQueue.main.async {
                    for i in 0..<7 {
                        _ = exerciseManager.routine(
                            for: i
                        )
                    }
                }
            }
        }
    }
}
