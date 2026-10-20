import Foundation

struct StrengthLabExerciseDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: String
    let level: String
    let mechanic: String?
    let sourceCategory: String

    let instructions: [String]

    let directMuscles: [String]
    let indirectMuscles: [String]
    let stabilizers: [String]

    let patterns: [String]

    let volumeEligible: Bool
    let confidence: String

    let trainingTypes: [String]
    let modalities: [String]

    var browseCategory: String {
        let muscles = Set(directMuscles)

        if muscles.contains("chest") {
            return "Chest"
        }

        if !muscles.isDisjoint(
            with: [
                "lats",
                "middle_back",
                "lower_back",
                "traps"
            ]
        ) {
            return "Back"
        }

        if !muscles.isDisjoint(
            with: [
                "shoulders",
                "rotator_cuff"
            ]
        ) {
            return "Shoulders"
        }

        if !muscles.isDisjoint(
            with: [
                "biceps",
                "triceps",
                "forearms"
            ]
        ) {
            return "Arms"
        }

        if muscles.contains("abdominals") {
            return "Core"
        }

        if !muscles.isDisjoint(
            with: [
                "glutes",
                "hamstrings",
                "adductors",
                "abductors",
                "hip_flexors"
            ]
        ) {
            return "Glutes & Hamstrings"
        }

        if !muscles.isDisjoint(
            with: [
                "quadriceps",
                "calves",
                "tibialis"
            ]
        ) {
            return "Legs"
        }

        return "Full Body"
    }

    var searchableText: String {
        (
            [
                name,
                equipment,
                level,
                sourceCategory
            ]
            + directMuscles
            + indirectMuscles
            + stabilizers
            + patterns
        )
        .joined(separator: " ")
    }
}

enum StrengthLabExerciseLibrary {

    static let all: [StrengthLabExerciseDefinition] = {
        load()
    }()

    static var muscleFilters: [String] {
        let muscles =
            Set(
                all.flatMap {
                    $0.directMuscles +
                    $0.indirectMuscles
                }
            )

        return muscles.sorted {
            displayName($0)
                .localizedCaseInsensitiveCompare(
                    displayName($1)
                )
                == .orderedAscending
        }
    }

    static var equipmentFilters: [String] {
        let equipment =
            Set(
                all
                    .map(\.equipment)
                    .filter {
                        !$0.isEmpty &&
                        $0 != "Other"
                    }
            )

        return equipment.sorted {
            $0.localizedCaseInsensitiveCompare($1)
                == .orderedAscending
        }
    }

    static func displayName(
        _ raw: String
    ) -> String {
        raw
            .replacingOccurrences(
                of: "_",
                with: " "
            )
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .split(separator: " ")
            .map {
                $0.prefix(1).uppercased()
                + $0.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func load()
        -> [StrengthLabExerciseDefinition]
    {
        let possibleURLs: [URL?] = [
            Bundle.module.url(
                forResource: "free-exercise-db-plusplus",
                withExtension: "json",
                subdirectory: "ExerciseDB"
            ),
            Bundle.module.url(
                forResource: "free-exercise-db-plusplus",
                withExtension: "json"
            ),
            Bundle.main.url(
                forResource:
                    "free-exercise-db-plusplus",
                withExtension:
                    "json"
            ),

            Bundle.main.url(
                forResource:
                    "free-exercise-db-plusplus",
                withExtension:
                    "json",
                subdirectory:
                    "ExerciseDB"
            ),

            Bundle.main.url(
                forResource:
                    "free-exercise-db-plusplus",
                withExtension:
                    "json",
                subdirectory:
                    "Resources/ExerciseDB"
            )
        ]

        guard
            let url =
                possibleURLs
                    .compactMap({ $0 })
                    .first
        else {
            print(
                "[StrengthLab] DB++ resource not found in bundle."
            )
            return []
        }

        do {
            let data =
                try Data(
                    contentsOf: url
                )

            let decoded =
                try JSONDecoder()
                    .decode(
                        Database.self,
                        from: data
                    )

            return decoded.exercises.values
                .map { entry in
                    StrengthLabExerciseDefinition(
                        id:
                            entry.exerciseId,

                        name:
                            entry.source.name,

                        equipment:
                            equipmentName(
                                source:
                                    entry.source,
                                classification:
                                    entry.classification
                            ),

                        level:
                            displayName(
                                entry.source.level
                            ),

                        mechanic:
                            entry.source.mechanic
                                .map(displayName),

                        sourceCategory:
                            displayName(
                                entry.source.category
                            ),

                        instructions:
                            entry.source.instructions,

                        directMuscles:
                            entry.annotation.direct,

                        indirectMuscles:
                            entry.annotation.indirect,

                        stabilizers:
                            entry.annotation.stabilizers,

                        patterns:
                            entry.annotation.patterns,

                        volumeEligible:
                            entry.annotation.volumeEligible,

                        confidence:
                            entry.annotation.confidence,

                        trainingTypes:
                            entry.classification.trainingTypes,

                        modalities:
                            entry.classification.modalities
                    )
                }
                .sorted {
                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                        == .orderedAscending
                }

        } catch {
            print(
                "[StrengthLab] DB++ decode failed: \(error)"
            )

            return []
        }
    }

    private static func equipmentName(
        source: SourceExercise,
        classification: Classification
    ) -> String {

        if let equipment =
            source.equipment,
           !equipment.isEmpty
        {
            return displayName(
                equipment
            )
        }

        if let modality =
            classification.modalities.first
        {
            return displayName(
                modality
            )
        }

        return "Other"
    }
}

private extension StrengthLabExerciseLibrary {

    struct Database: Decodable {
        let exercises:
            [String: Entry]
    }

    struct Entry: Decodable {
        let exerciseId: String
        let classification: Classification
        let annotation: Annotation
        let source: SourceExercise
    }

    struct Annotation: Decodable {
        let patterns: [String]
        let direct: [String]
        let indirect: [String]
        let stabilizers: [String]
        let volumeEligible: Bool
        let confidence: String
    }

    struct Classification: Decodable {
        let trainingTypes: [String]
        let modalities: [String]
    }

    struct SourceExercise: Decodable {
        let name: String
        let level: String
        let mechanic: String?
        let equipment: String?
        let instructions: [String]
        let category: String
    }
}
