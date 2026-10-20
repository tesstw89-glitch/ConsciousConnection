import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    @Environment(ExerciseManager.self)
    private var exerciseManager

    @State private var expandedSetID: UUID?
    @State private var showMediaEditor = false

    let index: Int
    let exercise: SetDeckExercise

    private let accent = Color(
        red: 0.78,
        green: 0.95,
        blue: 0.25
    )

    private var orderedSets: [SetDeckSet] {
        let fetched =
            exerciseManager.sets(for: exercise)

        if !fetched.isEmpty {
            return fetched
        }

        return (exercise.sets ?? [])
            .sorted {
                $0.orderIndex < $1.orderIndex
            }
    }

    private var supersetText: String? {
        guard
            let groupID = exercise.supersetGroupID
        else {
            return nil
        }

        let members =
            (exercise.routine?.exercises ?? [])
            .filter {
                $0.supersetGroupID == groupID
            }
            .sorted {
                $0.orderIndex < $1.orderIndex
            }

        guard members.count > 1 else {
            return "SUPERSET"
        }

        guard
            let position =
                members.firstIndex(
                    where: {
                        $0.uuid == exercise.uuid
                    }
                )
        else {
            return "SUPERSET"
        }

        return
            "SUPERSET \(position + 1) OF \(members.count)"
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            header

            if let gifURL = exercise.gifURL {
                ExerciseMediaPlaybackView(exercise: exercise)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color.black)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .accessibilityLabel(
                        "Animated demonstration for \(exercise.name)"
                    )
            }

            if
                let note = exercise.note,
                !note.isEmpty
            {
                HStack(
                    alignment: .top,
                    spacing: 9
                ) {
                    Image(systemName: "quote.opening")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .opacity(0.45)

            setsHeader

            if orderedSets.isEmpty {
                Text("No sets yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 9) {
                    ForEach(
                        orderedSets,
                        id: \.uuid
                    ) { set in
                        let isExpanded =
                            Binding<Bool>(
                                get: {
                                    expandedSetID ==
                                        set.uuid
                                },
                                set: { value in
                                    withAnimation(
                                        .snappy(
                                            duration: 0.25
                                        )
                                    ) {
                                        expandedSetID =
                                            value
                                            ? set.uuid
                                            : nil
                                    }
                                }
                            )

                        SetRowView(
                            isEditing: isExpanded,
                            set: set
                        )
                    }
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(
                Color(
                    .secondarySystemGroupedBackground
                )
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.055),
                lineWidth: 1
            )
        }
        .overlay(
            alignment: .leading
        ) {
            if supersetText != nil {
                RoundedRectangle(
                    cornerRadius: 4
                )
                .fill(accent)
                .frame(width: 5)
                .padding(.vertical, 20)
            }
        }
        .shadow(
            color: .black.opacity(0.045),
            radius: 12,
            x: 0,
            y: 5
        )
        .sheet(
            isPresented: $showMediaEditor
        ) {
            NavigationStack {
                Form {
                    ExerciseMediaEditorWithTrim(
                        exercise: exercise
                    )
                }
                .navigationTitle("Exercise Media")
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    ToolbarItem(
                        placement:
                            .confirmationAction
                    ) {
                        Button("Done") {
                            showMediaEditor = false
                        }
                    }
                }
            }
            .presentationDetents([
                .medium,
                .large
            ])
        }
    }

    private var header: some View {
        HStack(
            alignment: .top,
            spacing: 13
        ) {
            Text("\(index)")
                .font(.headline.weight(.black))
                .foregroundStyle(.black)
                .frame(width: 38, height: 38)
                .background(
                    accent,
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text(
                    exercise.name.isEmpty
                        ? "Exercise"
                        : exercise.name
                )
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .tracking(-0.4)
                .lineLimit(2)

                FlowLayoutCompat(
                    spacing: 6
                ) {
                    if
                        let equipment =
                            exercise.equipment,
                        !equipment.isEmpty
                    {
                        chip(
                            equipment,
                            icon: "dumbbell.fill"
                        )
                    }

                    if exercise.isWarmup {
                        chip(
                            "Warm-up",
                            icon: "flame.fill"
                        )
                    }

                    if let supersetText {
                        chip(
                            supersetText,
                            icon: "link",
                            highlighted: true
                        )
                    }

                    if exercise.gifURL != nil {
                        chip(
                            "DEMO",
                            icon:
                                "play.rectangle.fill"
                        )
                    }

                    if
                        let url =
                            exercise.videoURL,
                        !url.absoluteString.isEmpty
                    {
                        Link(destination: url) {
                            chip(
                                "VIDEO",
                                icon: "play.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 4)

            Button {
                showMediaEditor = true
            } label: {
                Image(
                    systemName:
                        "ellipsis"
                )
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(
                    Color(
                        .tertiarySystemGroupedBackground
                    ),
                    in: Circle()
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Exercise options"
            )
        }
    }

    private var setsHeader: some View {
        HStack {
            Text("SETS")
                .font(.caption2.weight(.black))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(orderedSets.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private func chip(
        _ title: String,
        icon: String? = nil,
        highlighted: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
            }

            Text(title)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(
            highlighted
                ? Color.black
                : Color.secondary
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            highlighted
                ? accent
                : Color(
                    .tertiarySystemGroupedBackground
                ),
            in: Capsule()
        )
    }
}


/// Tiny wrapping layout for metadata chips.
/// Keeps the exercise header neat on smaller iPhones.
struct FlowLayoutCompat<
    Content: View
>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content

    init(
        spacing: CGFloat = 6,
        @ViewBuilder content:
            () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: spacing
        ) {
            content
        }
    }
}
