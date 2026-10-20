import SwiftUI
import SwiftData

struct ExerciseLibraryPicker: View {
    @Query
    private var savedExercises: [SetDeckExercise]

    let onSelect: (ExerciseCatalogItem) -> Void
    let onCreateCustom: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var sourceExercises: [ExerciseCatalogItem] {
        let imported =
            StrengthLabExerciseLibrary.all

        let existingGIFs =
            Dictionary(
                ExerciseCatalog.all.map {
                    (
                        $0.name.lowercased(),
                        $0.gifURL
                    )
                },
                uniquingKeysWith: {
                    first,
                    _ in first
                }
            )

        var items:
            [ExerciseCatalogItem] =
                imported.map { item in

                    ExerciseCatalogItem(
                        name:
                            item.name,

                        category:
                            item.browseCategory,

                        equipment:
                            item.equipment,

                        gifURL:
                            existingGIFs[
                                item.name
                                    .lowercased()
                            ] ?? nil
                    )
                }

        let appNames =
            Set(
                items.map {
                    $0.name
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .lowercased()
                }
            )

        var customByName:
            [String: SetDeckExercise] =
                [:]

        for exercise in savedExercises {
            let name =
                exercise.name
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !name.isEmpty,
                name != "New Exercise"
            else {
                continue
            }

            let key =
                name.lowercased()

            guard
                !StrengthLabExerciseCanonicalizer
                    .isAppExercise(
                        name
                    )
            else {
                continue
            }

            if customByName[key] == nil {
                customByName[key] =
                    exercise
            }
        }

        let customItems =
            customByName.values
                .map { exercise in

                    ExerciseCatalogItem(
                        name:
                            exercise.name,

                        category:
                            exercise
                                .muscleGroups
                                .first?
                                .displayName
                            ??
                            "Custom",

                        equipment:
                            exercise.equipment
                            ??
                            "Other",

                        gifURL:
                            exercise.gifURL
                    )
                }

        items.append(
            contentsOf:
                customItems
        )

        return items.sorted {
            $0.name
                .localizedCaseInsensitiveCompare(
                    $1.name
                )
            ==
            .orderedAscending
        }
    }

    private var filteredExercises: [ExerciseCatalogItem] {
        guard !searchText.isEmpty else {
            return ExerciseCatalog.all
        }

        return sourceExercises.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.category.localizedCaseInsensitiveContains(searchText) ||
            item.equipment.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                List(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {

                            Image(systemName: iconName(for: exercise.category))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)

                                HStack(spacing: 6) {
                                    Text(exercise.category)

                                    Text("·")

                                    Text(exercise.equipment)

                                    if exercise.gifURL != nil {
                                        Text("·")

                                        Label(
                                            "Demo",
                                            systemImage: "play.rectangle.fill"
                                        )
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.tint)
                        }
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)

                Divider()

                Button {
                    onCreateCustom()
                    dismiss()
                } label: {
                    Label(
                        "Create Custom Exercise",
                        systemImage: "plus.square"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search exercises, muscles or equipment"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Chest":
            return "figure.strengthtraining.traditional"
        case "Back":
            return "figure.strengthtraining.functional"
        case "Shoulders":
            return "dumbbell.fill"
        case "Legs":
            return "figure.run"
        case "Glutes & Hamstrings":
            return "figure.walk"
        case "Arms":
            return "dumbbell"
        case "Core":
            return "figure.core.training"
        case "Calves":
            return "figure.stairs"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
}
