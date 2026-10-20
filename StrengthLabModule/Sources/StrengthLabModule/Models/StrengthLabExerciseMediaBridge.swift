import Foundation
import SwiftData

enum StrengthLabExerciseMediaBridge {

    private static let markerPrefix =
        "__StrengthLabLibraryMedia__:"

    static func marker(
        for exerciseID: String
    ) -> String {
        markerPrefix + exerciseID
    }


    static func isMediaCarrier(
        _ exercise: SetDeckExercise
    ) -> Bool {
        exercise.note?
            .hasPrefix(markerPrefix)
        == true
    }


    static func hasMedia(
        _ exercise: SetDeckExercise
    ) -> Bool {
        exercise.gifURL != nil
        ||
        exercise.gifSourceURL != nil
        ||
        exercise.videoURL != nil
        ||
        exercise.importedVideoURL != nil
    }


    static func carrier(
        for definition:
            StrengthLabExerciseDefinition,
        in context:
            ModelContext
    ) -> SetDeckExercise? {

        let wanted =
            marker(
                for: definition.id
            )

        let all =
            (
                try?
                context.fetch(
                    FetchDescriptor<
                        SetDeckExercise
                    >()
                )
            )
            ?? []

        return all.first {
            $0.note == wanted
        }
    }


    @discardableResult
    static func ensureCarrier(
        for definition:
            StrengthLabExerciseDefinition,
        fallbackGIF:
            URL?,
        in context:
            ModelContext
    ) -> SetDeckExercise {

        if let existing =
            carrier(
                for: definition,
                in: context
            )
        {
            return existing
        }

        let all =
            (
                try?
                context.fetch(
                    FetchDescriptor<
                        SetDeckExercise
                    >()
                )
            )
            ?? []

        let wantedKey =
            key(definition.name)

        let existingWorkoutMedia =
            all.first {
                !isMediaCarrier($0)
                &&
                key($0.name)
                    == wantedKey
                &&
                hasMedia($0)
            }

        let newCarrier =
            SetDeckExercise(
                name: definition.name,
                note:
                    marker(
                        for:
                            definition.id
                    ),
                gifURL:
                    fallbackGIF,
                muscleGroups:
                    localMuscles(
                        from:
                            definition
                                .directMuscles
                    ),
                equipment:
                    definition.equipment,
                orderIndex: -999
            )

        if let existingWorkoutMedia {
            copyMedia(
                from:
                    existingWorkoutMedia,
                to:
                    newCarrier
            )
        }

        context.insert(
            newCarrier
        )

        try? context.save()

        return newCarrier
    }


    static func propagateAppMedia(
        from source:
            SetDeckExercise,
        definition:
            StrengthLabExerciseDefinition,
        in context:
            ModelContext
    ) {

        let all =
            (
                try?
                context.fetch(
                    FetchDescriptor<
                        SetDeckExercise
                    >()
                )
            )
            ?? []

        let wanted =
            key(definition.name)

        for target in all {

            guard
                target.uuid
                    != source.uuid,
                !isMediaCarrier(target)
            else {
                continue
            }

            let exact =
                key(target.name)
                == wanted

            let sameCanonicalExercise =
                !exact
                &&
                StrengthLabExerciseCanonicalizer
                    .definition(
                        matching:
                            target.name
                    )?
                    .id
                ==
                definition.id

            guard
                exact
                ||
                sameCanonicalExercise
            else {
                continue
            }

            copyMedia(
                from:
                    source,
                to:
                    target
            )
        }

        try? context.save()
    }


    static func propagateCustomMedia(
        from source:
            SetDeckExercise,
        in context:
            ModelContext
    ) {

        let all =
            (
                try?
                context.fetch(
                    FetchDescriptor<
                        SetDeckExercise
                    >()
                )
            )
            ?? []

        let wanted =
            key(source.name)

        for target in all {

            guard
                target.uuid
                    != source.uuid,
                !isMediaCarrier(target),
                key(target.name)
                    == wanted
            else {
                continue
            }

            copyMedia(
                from:
                    source,
                to:
                    target
            )
        }

        try? context.save()
    }


    static func applyLibraryMedia(
        to target:
            SetDeckExercise,
        in context:
            ModelContext
    ) {

        if let definition =
            exactBankDefinition(
                for:
                    target.name
            )
            ??
            StrengthLabExerciseCanonicalizer
                .definition(
                    matching:
                        target.name
                )
        {
            if let source =
                carrier(
                    for:
                        definition,
                    in:
                        context
                )
            {
                copyMedia(
                    from:
                        source,
                    to:
                        target
                )
            }

            return
        }

        let all =
            (
                try?
                context.fetch(
                    FetchDescriptor<
                        SetDeckExercise
                    >()
                )
            )
            ?? []

        let wanted =
            key(target.name)

        if let source =
            all.first(
                where: {
                    $0.uuid
                        != target.uuid
                    &&
                    !isMediaCarrier($0)
                    &&
                    key($0.name)
                        == wanted
                    &&
                    hasMedia($0)
                }
            )
        {
            copyMedia(
                from:
                    source,
                to:
                    target
            )
        }
    }


    static func exactBankDefinition(
        for name: String
    ) -> StrengthLabExerciseDefinition? {

        let wanted =
            key(name)

        return
            StrengthLabExerciseLibrary
                .all
                .first {
                    key($0.name)
                    == wanted
                }
    }


    private static func copyMedia(
        from source:
            SetDeckExercise,
        to target:
            SetDeckExercise
    ) {

        target.videoURL =
            source.videoURL

        target.importedVideoURL =
            source.importedVideoURL

        target.gifURL =
            source.gifURL

        target.gifSourceURL =
            source.gifSourceURL

        target.gifEditedFPS =
            source.gifEditedFPS

        target.gifEditedMaxWidth =
            source.gifEditedMaxWidth

        target.gifTrimStart =
            source.gifTrimStart

        target.gifTrimEnd =
            source.gifTrimEnd

        target.videoTrimStart =
            source.videoTrimStart

        target.videoTrimEnd =
            source.videoTrimEnd
    }


    private static func key(
        _ value: String
    ) -> String {

        value
            .lowercased()
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .replacingOccurrences(
                of: "–",
                with: " "
            )
            .split(
                whereSeparator:
                    \.isWhitespace
            )
            .joined(
                separator: " "
            )
    }


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
