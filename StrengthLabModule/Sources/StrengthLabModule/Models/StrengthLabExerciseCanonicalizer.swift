import Foundation
import SwiftData

enum StrengthLabExerciseCanonicalizer {

    // MARK: - Cached DB++ index

    private struct IndexedExercise {
        let exercise:
            StrengthLabExerciseDefinition

        let normalizedKey:
            String

        let tokens:
            Set<String>

        let equipment:
            String?
    }


    /*
     Build these once.

     The old matcher rebuilt token sets for
     hundreds of DB++ exercises EVERY TIME
     it attempted a match.
     */
    private static let indexedLibrary:
        [IndexedExercise] =
    {
        StrengthLabExerciseLibrary
            .all
            .map { exercise in

                IndexedExercise(
                    exercise:
                        exercise,

                    normalizedKey:
                        normalizedKey(
                            exercise.name
                        ),

                    tokens:
                        canonicalTokens(
                            exercise.name
                        ),

                    equipment:
                        equipmentFamily(
                            exercise.equipment
                        )
                )
            }
    }()


    private static let exactIndex:
        [String:
            StrengthLabExerciseDefinition] =
    {
        Dictionary(
            indexedLibrary.map {
                (
                    $0.normalizedKey,
                    $0.exercise
                )
            },
            uniquingKeysWith: {
                first,
                _ in first
            }
        )
    }()


    /*
     Token → candidate indices.

     A fuzzy lookup now only scores exercises
     sharing at least one meaningful token
     instead of blindly rescanning all 927.
     */
    private static let tokenIndex:
        [String: Set<Int>] =
    {
        var result:
            [String: Set<Int>] =
                [:]

        for (
            index,
            item
        ) in indexedLibrary.enumerated() {

            for token in item.tokens {
                result[
                    token,
                    default: []
                ]
                .insert(index)
            }
        }

        return result
    }()


    // MARK: - Public lookup

    static func definition(
        matching rawName: String
    ) -> StrengthLabExerciseDefinition? {

        let name =
            rawName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !name.isEmpty else {
            return nil
        }

        let wantedKey =
            normalizedKey(
                name
            )

        // Fast exact/normalised lookup.
        if let exact =
            exactIndex[wantedKey]
        {
            return exact
        }

        // Known StrengthLab wording aliases.
        if let aliases =
            knownAliases[
                wantedKey
            ]
        {
            for alias in aliases {

                if let match =
                    exactIndex[
                        normalizedKey(
                            alias
                        )
                    ]
                {
                    return match
                }
            }
        }

        let wantedTokens =
            canonicalTokens(
                name
            )

        guard
            wantedTokens.count >= 2
        else {
            return nil
        }

        let wantedEquipment =
            equipmentFamily(
                name
            )

        // Only inspect candidates sharing tokens.
        var candidateIndices:
            Set<Int> = []

        for token in wantedTokens {
            candidateIndices
                .formUnion(
                    tokenIndex[token]
                    ?? []
                )
        }

        guard
            !candidateIndices.isEmpty
        else {
            return nil
        }

        var scored:
            [
                (
                    exercise:
                        StrengthLabExerciseDefinition,
                    score:
                        Double
                )
            ] = []

        for index in candidateIndices {

            let candidate =
                indexedLibrary[index]

            if
                let wantedEquipment,
                let candidateEquipment =
                    candidate.equipment,
                wantedEquipment
                    != candidateEquipment
            {
                continue
            }

            let intersection =
                wantedTokens
                    .intersection(
                        candidate.tokens
                    )
                    .count

            guard intersection > 0 else {
                continue
            }

            let dice =
                (
                    2.0
                    *
                    Double(
                        intersection
                    )
                )
                /
                Double(
                    wantedTokens.count
                    +
                    candidate
                        .tokens
                        .count
                )

            let containment =
                Double(
                    intersection
                )
                /
                Double(
                    min(
                        wantedTokens.count,
                        candidate
                            .tokens
                            .count
                    )
                )

            let score =
                (
                    dice * 0.65
                )
                +
                (
                    containment * 0.35
                )

            scored.append(
                (
                    exercise:
                        candidate
                            .exercise,

                    score:
                        score
                )
            )
        }

        scored.sort {
            $0.score > $1.score
        }

        guard
            let best =
                scored.first,
            best.score >= 0.90
        else {
            return nil
        }

        /*
         Don't invent a match when two bank
         exercises are almost equally plausible.
         */
        if
            scored.count > 1,
            scored[1].score
                >= best.score - 0.06
        {
            return nil
        }

        return best.exercise
    }


    static func canonicalName(
        for rawName: String
    ) -> String? {

        definition(
            matching:
                rawName
        )?
        .name
    }


    static func isAppExercise(
        _ rawName: String
    ) -> Bool {

        definition(
            matching:
                rawName
        )
        != nil
    }


    static func shouldHideFromExerciseLibrary(
        _ rawName: String
    ) -> Bool {

        excludedContainerNames
            .contains(
                normalizedKey(
                    rawName
                )
            )
    }


    // MARK: - Existing stored exercises

    @discardableResult
    static func reconcileSavedExercises(
        in context: ModelContext
    ) -> Int {

        let descriptor =
            FetchDescriptor<
                SetDeckExercise
            >()

        guard
            let exercises =
                try? context.fetch(
                    descriptor
                )
        else {
            return 0
        }

        var renamedCount =
            0

        var changed =
            false

        for exercise in exercises {

            let original =
                exercise.name
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !original.isEmpty,
                !shouldHideFromExerciseLibrary(
                    original
                )
            else {
                continue
            }

            guard
                let canonical =
                    definition(
                        matching:
                            original
                    )
            else {
                continue
            }

            if
                exercise.name
                != canonical.name
            {
                print(
                    "[StrengthLab] Canonical exercise: '\(exercise.name)' → '\(canonical.name)'"
                )

                exercise.name =
                    canonical.name

                renamedCount += 1
                changed = true
            }

            let existingEquipment =
                exercise.equipment?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                ?? ""

            if existingEquipment.isEmpty {
                exercise.equipment =
                    canonical.equipment

                changed = true
            }

            if
                exercise
                    .muscleGroups
                    .isEmpty
            {
                let mapped =
                    localMuscles(
                        from:
                            canonical
                                .directMuscles
                    )

                if !mapped.isEmpty {
                    exercise.muscleGroups =
                        mapped

                    changed = true
                }
            }
        }

        if changed {
            do {
                try context.save()
            } catch {
                print(
                    "[StrengthLab] Exercise canonicalisation save failed: \(error)"
                )
            }
        }

        return renamedCount
    }


    // MARK: - Name normalisation

    private static func normalizedKey(
        _ value: String
    ) -> String {

        canonicalTokens(
            value
        )
        .sorted()
        .joined(
            separator: " "
        )
    }


    private static func canonicalTokens(
        _ value: String
    ) -> Set<String> {

        var cleaned =
            value.lowercased()

        cleaned =
            cleaned.replacingOccurrences(
                of: "&",
                with: " and "
            )

        let allowed =
            CharacterSet
                .alphanumerics
                .union(
                    .whitespaces
                )

        cleaned =
            String(
                cleaned
                    .unicodeScalars
                    .map {
                        allowed.contains($0)
                        ? Character(
                            String($0)
                        )
                        : " "
                    }
            )

        let ignored:
            Set<String> =
        [
            "a",
            "an",
            "the",
            "with",
            "using",
            "version"
        ]

        var result:
            Set<String> = []

        for raw in
            cleaned.split(
                whereSeparator:
                    \.isWhitespace
            )
        {
            var token =
                String(raw)

            switch token {

            case "single":
                token = "one"

            case "dumbbells":
                token = "dumbbell"

            case "bands":
                token = "band"

            case "barbells":
                token = "barbell"

            case "kettlebells":
                token = "kettlebell"

            case "rows":
                token = "row"

            case "raises":
                token = "raise"

            case "extensions":
                token = "extension"

            case "curls":
                token = "curl"

            case "twists":
                token = "twist"

            case "bugs":
                token = "bug"

            case "flies",
                 "flyes":
                token = "fly"

            case "presses":
                token = "press"

            case "triceps":
                token = "tricep"

            case "situps":
                token = "situp"

            case "steps":
                token = "step"

            default:

                if
                    token.count > 4,
                    token.hasSuffix(
                        "s"
                    ),
                    !token.hasSuffix(
                        "ss"
                    )
                {
                    token.removeLast()
                }
            }

            if
                !ignored.contains(
                    token
                ),
                !token.isEmpty
            {
                result.insert(
                    token
                )
            }
        }

        return result
    }


    private static func equipmentFamily(
        _ value: String
    ) -> String? {

        let tokens =
            canonicalTokens(
                value
            )

        let equipment = [
            "dumbbell",
            "barbell",
            "cable",
            "band",
            "machine",
            "bodyweight",
            "kettlebell",
            "plate",
            "smith",
            "sled"
        ]

        return equipment.first {
            tokens.contains(
                $0
            )
        }
    }


    // MARK: - Known safe aliases

    private static let knownAliases:
        [String: [String]] =
    {
        var aliases:
            [String: [String]] =
                [:]

        func add(
            _ ours: String,
            _ bank: [String]
        ) {
            aliases[
                normalizedKey(
                    ours
                )
            ] = bank
        }

        add(
            "Dumbbell Overhead Press",
            [
                "Dumbbell Shoulder Press"
            ]
        )

        add(
            "Dumbbell Lateral Raise",
            [
                "Side Lateral Raise"
            ]
        )

        add(
            "Single-Dumbbell Overhead Triceps Extension",
            [
                "Standing Dumbbell Triceps Extension"
            ]
        )

        add(
            "One-Arm Supported Dumbbell Row",
            [
                "One-Arm Dumbbell Row"
            ]
        )

        add(
            "Two-Dumbbell Bent-Over Row",
            [
                "Bent Over Two-Dumbbell Row"
            ]
        )

        add(
            "Dumbbell Pullover",
            [
                "Straight-Arm Dumbbell Pullover"
            ]
        )

        add(
            "Bent-Over Reverse Fly",
            [
                "Reverse Flyes"
            ]
        )

        add(
            "Lying Dumbbell Triceps Extension",
            [
                "Lying Dumbbell Tricep Extension"
            ]
        )

        add(
            "Dead Bugs",
            [
                "Dead Bug"
            ]
        )

        add(
            "Russian Twists",
            [
                "Russian Twist"
            ]
        )

        add(
            "Toe Touches",
            [
                "Toe Touchers"
            ]
        )

        add(
            "Banded Hip Extensions",
            [
                "Hip Extension with Bands"
            ]
        )

        return aliases
    }()


    private static let excludedContainerNames:
        Set<String> =
    [
        normalizedKey(
            "Warm-Up & Programme Guide"
        ),

        normalizedKey(
            "Plate Core"
        ),

        normalizedKey(
            "Plate Core Workout"
        )
    ]


    // MARK: - DB++ muscle bridge

    private static func localMuscles(
        from values: [String]
    ) -> [MuscleGroup] {

        var result:
            [MuscleGroup] = []

        for raw in values {

            let muscle:
                MuscleGroup?

            switch raw {

            case "chest":
                muscle = .chest

            case "shoulders":
                muscle = .shoulders

            case "triceps":
                muscle = .triceps

            case "biceps":
                muscle = .biceps

            case "forearms":
                muscle = .forearms

            case "lats":
                muscle = .lats

            case "traps":
                muscle = .traps

            case "middle_back":
                muscle = .back

            case "lower_back":
                muscle = .lowerBack

            case "quadriceps":
                muscle = .quads

            case "hamstrings":
                muscle = .hamstrings

            case "glutes":
                muscle = .glutes

            case "calves":
                muscle = .calves

            case "abdominals":
                muscle = .abs

            case "rotator_cuff":
                muscle = .rotatorCuff

            case "neck":
                muscle = .neck

            default:
                muscle = nil
            }

            if
                let muscle,
                !result.contains(
                    where: {
                        $0.rawValue
                        ==
                        muscle.rawValue
                    }
                )
            {
                result.append(
                    muscle
                )
            }
        }

        return result
    }
}
