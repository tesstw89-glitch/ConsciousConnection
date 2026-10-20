import SwiftUI
import SwiftData

struct RoutineDayDeckView: View {
    let routine: SetDeckRoutine
    var animateEntrance: Bool = false

    @State private var appeared = false

    private let accent = Color(
        red: 0.78,
        green: 0.95,
        blue: 0.25
    )

    private var exercises: [SetDeckExercise] {
        (routine.exercises ?? [])
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if exercises.isEmpty {
                    emptyState
                } else {
                    planHeader

                    ForEach(
                        Array(exercises.indices),
                        id: \.self
                    ) { index in
                        ExerciseCardView(
                            index: index + 1,
                            exercise: exercises[index]
                        )
                        .opacity(
                            appeared ? 1 : 0
                        )
                        .offset(
                            y: appeared
                                ? 0
                                : 24
                        )
                        .animation(
                            .spring(
                                response: 0.45,
                                dampingFraction: 0.86
                            )
                            .delay(
                                Double(index) * 0.045
                            ),
                            value: appeared
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if animateEntrance {
                withAnimation {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }

    private var planHeader: some View {
        HStack(spacing: 12) {
            RoundedRectangle(
                cornerRadius: 3,
                style: .continuous
            )
            .fill(accent)
            .frame(width: 5, height: 38)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("TODAY'S SESSION")
                    .font(.caption2.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Text(
                    "\(exercises.count) exercise" +
                    (exercises.count == 1 ? "" : "s")
                )
                .font(.headline)
            }

            Spacer()

            Image(systemName: "bolt.fill")
                .foregroundStyle(.black)
                .frame(width: 34, height: 34)
                .background(
                    accent,
                    in: Circle()
                )
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.rest")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)

            Text("Rest day")
                .font(
                    .system(
                        size: 26,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text(
                "Nothing scheduled today. Enjoy it."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
        .padding(.horizontal, 24)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}
