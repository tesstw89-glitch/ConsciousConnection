import SwiftUI
import SwiftData


private enum ExerciseLibrarySourceFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all =
        "All"

    case app =
        "App Exercises"

    case custom =
        "Custom Exercises"

    case workout =
        "Workout Exercises"

    var id: String {
        rawValue
    }
}


private struct CustomLibraryExercise {
    let exercise:
        SetDeckExercise

    var id: UUID {
        exercise.uuid
    }

    var name: String {
        exercise.name
    }

    var equipment: String {
        let value =
            exercise
                .equipment?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        return value.isEmpty
            ? "Other"
            : value
    }

    var muscleNames:
        [String]
    {
        exercise
            .muscleGroups
            .map(
                \.displayName
            )
    }

    var searchableText:
        String
    {
        (
            [
                name,
                equipment,
                exercise.note ?? ""
            ]
            +
            muscleNames
        )
        .joined(
            separator: " "
        )
    }
}


private enum ExerciseLibraryDisplayItem:
    Identifiable
{
    case app(
        StrengthLabExerciseDefinition,
        inWorkout: Bool
    )

    case custom(
        CustomLibraryExercise
    )


    var id: String {
        switch self {

        case .app(
            let exercise,
            _
        ):
            return
                "app:\(exercise.id)"

        case .custom(
            let exercise
        ):
            return
                "custom:\(exercise.id.uuidString)"
        }
    }


    var name: String {
        switch self {

        case .app(
            let exercise,
            _
        ):
            return exercise.name

        case .custom(
            let exercise
        ):
            return exercise.name
        }
    }


    var equipment: String {
        switch self {

        case .app(
            let exercise,
            _
        ):
            return exercise.equipment

        case .custom(
            let exercise
        ):
            return exercise.equipment
        }
    }


    var muscleNames:
        [String]
    {
        switch self {

        case .app(
            let exercise,
            _
        ):
            return
                (
                    exercise
                        .directMuscles
                    +
                    exercise
                        .indirectMuscles
                )
                .map {
                    StrengthLabExerciseLibrary
                        .displayName(
                            $0
                        )
                }

        case .custom(
            let exercise
        ):
            return
                exercise
                    .muscleNames
        }
    }


    var searchableText:
        String
    {
        switch self {

        case .app(
            let exercise,
            _
        ):
            return exercise.searchableText

        case .custom(
            let exercise
        ):
            return exercise.searchableText
        }
    }


    var inWorkout:
        Bool
    {
        switch self {

        case .app(
            _,
            let inWorkout
        ):
            return inWorkout

        case .custom:
            return true
        }
    }


    var sourceBadge:
        String
    {
        switch self {

        case .app:
            return "APP"

        case .custom:
            return "CUSTOM"
        }
    }
}


struct ExerciseLibraryHomeView:
    View
{
    @Query
    private var workoutTemplates:
        [WorkoutTemplate]

    @State
    private var searchText =
        ""

    @State
    private var selectedMuscle:
        String?

    @State
    private var selectedEquipment:
        String?

    @State
    private var selectedSource:
        ExerciseLibrarySourceFilter =
            .all

    @State
    private var cachedItems:
        [ExerciseLibraryDisplayItem] =
            []

    @State
    private var cachedMuscleFilters:
        [String] =
            []

    @State
    private var cachedEquipmentFilters:
        [String] =
            []


    private var bankExercises:
        [StrengthLabExerciseDefinition]
    {
        StrengthLabExerciseLibrary
            .all
    }


    private var bankByKey:
        [String:
            StrengthLabExerciseDefinition]
    {
        Dictionary(
            bankExercises.map {
                (
                    exerciseKey(
                        $0.name
                    ),
                    $0
                )
            },
            uniquingKeysWith: {
                first,
                _ in first
            }
        )
    }


    private var workoutExercises:
        [SetDeckExercise]
    {
        var result:
            [String:
                SetDeckExercise] =
                [:]

        let all =
            workoutTemplates
                .flatMap {
                    $0.exercises
                        ?? []
                }

        for exercise in all {

            let name =
                exercise.name
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !name.isEmpty,
                name !=
                    "New Exercise",
                !StrengthLabExerciseCanonicalizer
                    .shouldHideFromExerciseLibrary(
                        name
                    )
            else {
                continue
            }

            let key =
                exerciseKey(
                    name
                )

            if let existing =
                result[key]
            {
                if
                    metadataScore(
                        exercise
                    )
                    >
                    metadataScore(
                        existing
                    )
                {
                    result[key] =
                        exercise
                }
            } else {
                result[key] =
                    exercise
            }
        }

        return result.values
            .sorted {
                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    )
                ==
                .orderedAscending
            }
    }


    private var workoutKeys:
        Set<String>
    {
        Set(
            workoutExercises.map {
                exerciseKey(
                    $0.name
                )
            }
        )
    }


    private var appItems:
        [ExerciseLibraryDisplayItem]
    {
        let keys =
            workoutKeys

        return bankExercises.map {
            definition in

            .app(
                definition,
                inWorkout:
                    keys.contains(
                        exerciseKey(
                            definition.name
                        )
                    )
            )
        }
    }


    private var customItems:
        [ExerciseLibraryDisplayItem]
    {
        let bank =
            bankByKey

        let workouts =
            workoutExercises

        return workouts
            .filter {
                bank[
                    exerciseKey(
                        $0.name
                    )
                ]
                ==
                nil
            }
            .map {
                .custom(
                    CustomLibraryExercise(
                        exercise:
                            $0
                    )
                )
            }
    }


    private var sourceItems:
        [ExerciseLibraryDisplayItem]
    {
        switch selectedSource {

        case .all:
            return
                cachedItems

        case .app:
            return
                cachedItems.filter {
                    item in

                    if case
                        .app(_, _) = item
                    {
                        return true
                    }

                    return false
                }

        case .custom:
            return
                cachedItems.filter {
                    item in

                    if case
                        .custom(_) = item
                    {
                        return true
                    }

                    return false
                }

        case .workout:
            return
                cachedItems
                    .filter {
                        $0.inWorkout
                    }
                    .sorted {
                        $0.name
                            .localizedCaseInsensitiveCompare(
                                $1.name
                            )
                        ==
                        .orderedAscending
                    }
        }
    }


    private var filteredItems:
        [ExerciseLibraryDisplayItem]
    {
        sourceItems
            .filter {
                item in

                let matchesSearch =
                    searchText.isEmpty
                    ||
                    item
                        .searchableText
                        .localizedCaseInsensitiveContains(
                            searchText
                        )

                let matchesMuscle =
                    selectedMuscle
                        == nil
                    ||
                    item
                        .muscleNames
                        .contains(
                            selectedMuscle!
                        )

                let matchesEquipment =
                    selectedEquipment
                        == nil
                    ||
                    item.equipment
                        ==
                        selectedEquipment

                return
                    matchesSearch
                    &&
                    matchesMuscle
                    &&
                    matchesEquipment
            }
            .sorted {
                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    )
                ==
                .orderedAscending
            }
    }


    private var muscleFilters:
        [String]
    {
        cachedMuscleFilters
    }


    private var equipmentFilters:
        [String]
    {
        cachedEquipmentFilters
    }


    var body: some View {
        let visibleItems =
            filteredItems

        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(
                    alignment:
                        .leading,
                    spacing: 16
                ) {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 7
                    ) {
                        Text(
                            "EXERCISES"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(12)
                        )
                        .tracking(1.6)
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )

                        Text(
                            "Your complete StrengthLab exercise library."
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .medium(17)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )
                    }

                    filterSection(
                        title:
                            "Muscle"
                    ) {
                        filterChip(
                            "All",
                            selected:
                                selectedMuscle
                                == nil
                        ) {
                            selectedMuscle =
                                nil
                        }

                        ForEach(
                            muscleFilters,
                            id: \.self
                        ) { muscle in

                            filterChip(
                                muscle,
                                selected:
                                    selectedMuscle
                                    == muscle
                            ) {
                                selectedMuscle =
                                    selectedMuscle
                                    == muscle
                                    ? nil
                                    : muscle
                            }
                        }
                    }

                    filterSection(
                        title:
                            "Equipment"
                    ) {
                        filterChip(
                            "All",
                            selected:
                                selectedEquipment
                                == nil
                        ) {
                            selectedEquipment =
                                nil
                        }

                        ForEach(
                            equipmentFilters,
                            id: \.self
                        ) { equipment in

                            filterChip(
                                equipment,
                                selected:
                                    selectedEquipment
                                    == equipment
                            ) {
                                selectedEquipment =
                                    selectedEquipment
                                    == equipment
                                    ? nil
                                    : equipment
                            }
                        }
                    }

                    filterSection(
                        title:
                            "Source"
                    ) {
                        ForEach(
                            ExerciseLibrarySourceFilter
                                .allCases
                        ) { source in

                            filterChip(
                                source.rawValue,
                                selected:
                                    selectedSource
                                    == source
                            ) {
                                selectedSource =
                                    source
                            }
                        }
                    }

                    HStack {
                        Text(
                            "\(visibleItems.count) exercises"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )

                        Spacer()

                        if
                            selectedSource
                                != .all
                            ||
                            selectedMuscle
                                != nil
                            ||
                            selectedEquipment
                                != nil
                        {
                            Button(
                                "Clear"
                            ) {
                                selectedSource =
                                    .all

                                selectedMuscle =
                                    nil

                                selectedEquipment =
                                    nil
                            }
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(14)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )
                        }
                    }

                    if visibleItems.isEmpty {
                        Text(
                            "No exercises match those filters."
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .medium(15)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                        .padding(
                            .vertical,
                            40
                        )
                    }

                    ForEach(
                        visibleItems
                    ) { item in

                        NavigationLink {
                            destination(
                                for:
                                    item
                            )
                        } label: {
                            exerciseRow(
                                item
                            )
                        }
                        .buttonStyle(
                            .plain
                        )
                    }
                }
                .padding(
                    .horizontal,
                    24
                )
                .padding(
                    .top,
                    12
                )
                .padding(
                    .bottom,
                    120
                )
            }
            .scrollIndicators(
                .hidden
            )
        }
        .navigationTitle(
            "Exercise Library"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .searchable(
            text:
                $searchText,
            placement:
                .navigationBarDrawer(
                    displayMode:
                        .always
                ),
            prompt:
                "Search exercises"
        )
        .preferredColorScheme(
            .light
        )
        .onAppear {
            rebuildLibrarySnapshot()
        }
    }


    private func rebuildLibrarySnapshot()
    {
        let bank =
            StrengthLabExerciseLibrary
                .all

        let bankByKey =
            Dictionary(
                bank.map {
                    (
                        exerciseKey(
                            $0.name
                        ),
                        $0
                    )
                },
                uniquingKeysWith: {
                    first,
                    _ in first
                }
            )

        var workoutByKey:
            [String:
                SetDeckExercise] =
                [:]

        for workout in workoutTemplates {
            for exercise in
                workout.exercises
                ?? []
            {
                let name =
                    exercise.name
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )

                guard
                    !name.isEmpty,
                    name !=
                        "New Exercise",
                    !StrengthLabExerciseCanonicalizer
                        .shouldHideFromExerciseLibrary(
                            name
                        )
                else {
                    continue
                }

                let key =
                    exerciseKey(
                        name
                    )

                if let existing =
                    workoutByKey[
                        key
                    ]
                {
                    if
                        metadataScore(
                            exercise
                        )
                        >
                        metadataScore(
                            existing
                        )
                    {
                        workoutByKey[
                            key
                        ] =
                            exercise
                    }
                } else {
                    workoutByKey[
                        key
                    ] =
                        exercise
                }
            }
        }

        let workoutKeys =
            Set(
                workoutByKey.keys
            )

        let appItems:
            [ExerciseLibraryDisplayItem] =
                bank.map {
                    definition in

                    .app(
                        definition,
                        inWorkout:
                            workoutKeys
                                .contains(
                                    exerciseKey(
                                        definition.name
                                    )
                                )
                    )
                }

        let customItems:
            [ExerciseLibraryDisplayItem] =
                workoutByKey
                    .values
                    .filter {
                        bankByKey[
                            exerciseKey(
                                $0.name
                            )
                        ]
                        ==
                        nil
                    }
                    .map {
                        .custom(
                            CustomLibraryExercise(
                                exercise:
                                    $0
                            )
                        )
                    }

        let combined =
            appItems
            +
            customItems

        cachedItems =
            combined

        cachedMuscleFilters =
            Array(
                Set(
                    combined
                        .flatMap {
                            $0.muscleNames
                        }
                )
            )
            .sorted()

        cachedEquipmentFilters =
            Array(
                Set(
                    combined
                        .map {
                            $0.equipment
                        }
                        .filter {
                            !$0.isEmpty
                            &&
                            $0 !=
                                "Other"
                        }
                )
            )
            .sorted()
    }


    @ViewBuilder
    private func destination(
        for item:
            ExerciseLibraryDisplayItem
    ) -> some View {

        switch item {

        case .app(
            let exercise,
            _
        ):
            AppExerciseLibraryDetailView(
                exercise:
                    exercise
            )

        case .custom(
            let exercise
        ):
            CustomExerciseLibraryDetailView(
                exercise:
                    exercise
            )
        }
    }


    @ViewBuilder
    private func filterSection<
        Content: View
    >(
        title: String,
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing: 9
        ) {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .bold(13)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )

            ScrollView(
                .horizontal,
                showsIndicators:
                    false
            ) {
                HStack(
                    spacing: 8
                ) {
                    content()
                }
            }
        }
    }


    private func filterChip(
        _ title: String,
        selected: Bool,
        action:
            @escaping () -> Void
    ) -> some View {

        Button(
            action:
                action
        ) {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .medium(13)
                )
                .foregroundStyle(
                    selected
                    ? Color.white
                    : StrengthLabFigmaTheme
                        .ink
                )
                .padding(
                    .horizontal,
                    14
                )
                .frame(
                    height: 36
                )
                .background(
                    selected
                    ? AnyShapeStyle(
                        StrengthLabFigmaTheme
                            .coralGradient
                    )
                    : AnyShapeStyle(
                        StrengthLabFigmaTheme
                            .paleBlush
                    ),
                    in:
                        Capsule()
                )
        }
        .buttonStyle(
            .plain
        )
    }


    private func exerciseRow(
        _ item:
            ExerciseLibraryDisplayItem
    ) -> some View {

        HStack(
            spacing: 14
        ) {
            RoundedRectangle(
                cornerRadius: 16,
                style:
                    .continuous
            )
            .fill(
                StrengthLabFigmaTheme
                    .blush
            )
            .frame(
                width: 54,
                height: 54
            )
            .overlay {
                Image(
                    systemName:
                        "dumbbell.fill"
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .coral
                )
            }

            VStack(
                alignment:
                    .leading,
                spacing: 5
            ) {
                Text(
                    item.name
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
                .multilineTextAlignment(
                    .leading
                )

                let muscleText =
                    item
                        .muscleNames
                        .prefix(2)
                        .joined(
                            separator: ", "
                        )

                Text(
                    muscleText.isEmpty
                    ? item.equipment
                    : "\(item.equipment) · \(muscleText)"
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(13)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

                HStack(
                    spacing: 7
                ) {
                    Text(
                        item.sourceBadge
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(9)
                    )
                    .tracking(1)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                    if item.inWorkout {
                        Text(
                            "IN WORKOUTS"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(9)
                        )
                        .tracking(0.8)
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                    }
                }
            }

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .muted
            )
        }
        .padding(16)
        .background(
            Color.white,
            in:
                RoundedRectangle(
                    cornerRadius: 22,
                    style:
                        .continuous
                )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style:
                    .continuous
            )
            .stroke(
                Color.black
                    .opacity(0.07),
                lineWidth: 1
            )
        }
    }


    private func exerciseKey(
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


    private func metadataScore(
        _ exercise:
            SetDeckExercise
    ) -> Int {

        var score = 0

        if exercise.equipment
            != nil
        {
            score += 1
        }

        if
            !exercise
                .muscleGroups
                .isEmpty
        {
            score += 1
        }

        if exercise.note
            != nil
        {
            score += 1
        }

        if exercise.gifURL
            != nil
        {
            score += 2
        }

        if exercise.videoURL
            != nil
        {
            score += 2
        }

        if exercise.importedVideoURL
            != nil
        {
            score += 2
        }

        return score
    }
}



private struct AppExerciseLibraryDetailView:
    View
{
    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var savedExercises:
        [SetDeckExercise]

    let exercise:
        StrengthLabExerciseDefinition

    @State
    private var editingMedia:
        SetDeckExercise?


    private var catalogGIF:
        URL?
    {
        ExerciseCatalog
            .all
            .first {
                $0.name
                    .caseInsensitiveCompare(
                        exercise.name
                    )
                ==
                .orderedSame
            }?
            .gifURL
    }


    private var mediaCarrier:
        SetDeckExercise?
    {
        let wanted =
            StrengthLabExerciseMediaBridge
                .marker(
                    for:
                        exercise.id
                )

        return
            savedExercises
                .first {
                    $0.note
                        == wanted
                }
    }


    private var existingWorkoutMedia:
        SetDeckExercise?
    {
        let wanted =
            exerciseKey(
                exercise.name
            )

        return
            savedExercises
                .first {
                    !StrengthLabExerciseMediaBridge
                        .isMediaCarrier(
                            $0
                        )
                    &&
                    exerciseKey(
                        $0.name
                    )
                    ==
                    wanted
                    &&
                    StrengthLabExerciseMediaBridge
                        .hasMedia(
                            $0
                        )
                }
    }


    private var mediaSource:
        SetDeckExercise?
    {
        mediaCarrier
        ??
        existingWorkoutMedia
    }


    var body: some View {
        ScrollView {
            VStack(
                alignment:
                    .leading,
                spacing: 22
            ) {
                if let source =
                    mediaSource
                {
                    ExerciseMediaPlaybackView(
                        exercise:
                            source
                    )
                    .frame(
                        height: 240
                    )
                    .background(
                        Color.black
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style:
                                .continuous
                        )
                    )
                } else if
                    let catalogGIF
                {
                    ExerciseGIFView(
                        url:
                            catalogGIF
                    )
                    .frame(
                        height: 240
                    )
                    .background(
                        Color.black
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style:
                                .continuous
                        )
                    )
                }

                VStack(
                    alignment:
                        .leading,
                    spacing: 8
                ) {
                    Text(
                        exercise
                            .browseCategory
                            .uppercased()
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(12)
                    )
                    .tracking(1.5)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                    Text(
                        exercise.name
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(28)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                    Text(
                        "\(exercise.equipment) · \(exercise.level)"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .medium(15)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                mediaButton

                detailCard(
                    title:
                        "Muscles"
                ) {
                    roleRow(
                        title:
                            "Direct",
                        values:
                            exercise
                                .directMuscles
                    )

                    roleRow(
                        title:
                            "Indirect",
                        values:
                            exercise
                                .indirectMuscles
                    )

                    roleRow(
                        title:
                            "Stabilisers",
                        values:
                            exercise
                                .stabilizers
                    )
                }

                if
                    !exercise
                        .patterns
                        .isEmpty
                {
                    detailCard(
                        title:
                            "Movement"
                    ) {
                        Text(
                            exercise
                                .patterns
                                .map {
                                    StrengthLabExerciseLibrary
                                        .displayName(
                                            $0
                                        )
                                }
                                .joined(
                                    separator:
                                        ", "
                                )
                        )
                    }
                }

                if
                    !exercise
                        .instructions
                        .isEmpty
                {
                    detailCard(
                        title:
                            "How to do it"
                    ) {
                        ForEach(
                            Array(
                                exercise
                                    .instructions
                                    .enumerated()
                            ),
                            id:
                                \.offset
                        ) {
                            index,
                            instruction
                            in

                            HStack(
                                alignment:
                                    .top,
                                spacing: 12
                            ) {
                                Text(
                                    "\(index + 1)"
                                )
                                .font(
                                    StrengthLabFigmaTheme
                                        .bold(13)
                                )
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .coral
                                )

                                Text(
                                    instruction
                                )
                                .font(
                                    StrengthLabFigmaTheme
                                        .regular(15)
                                )
                            }
                        }
                    }
                }
            }
            .padding(
                .horizontal,
                24
            )
            .padding(
                .bottom,
                40
            )
        }
        .background(
            Color.white
                .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            isPresented:
                Binding(
                    get: {
                        editingMedia
                            != nil
                    },
                    set: {
                        if !$0 {
                            editingMedia =
                                nil
                        }
                    }
                ),
            onDismiss: {
                saveMediaEverywhere()
            }
        ) {
            if let editingMedia {
                LibraryExerciseMediaSheet(
                    exercise:
                        editingMedia
                ) {
                    saveMediaEverywhere()
                    self.editingMedia =
                        nil
                }
            }
        }
    }


    private var mediaButton:
        some View
    {
        Button {
            editingMedia =
                StrengthLabExerciseMediaBridge
                    .ensureCarrier(
                        for:
                            exercise,
                        fallbackGIF:
                            catalogGIF,
                        in:
                            modelContext
                    )

        } label: {
            HStack(
                spacing: 14
            ) {
                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .blush
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )
                    .overlay {
                        Image(
                            systemName:
                                "photo.on.rectangle.angled"
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )
                    }

                VStack(
                    alignment:
                        .leading,
                    spacing: 3
                ) {
                    Text(
                        mediaSource != nil
                        ||
                        catalogGIF != nil
                        ? "Edit Media"
                        : "Add Media"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )

                    Text(
                        "Video, GIF and demo trimming"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .regular(13)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
            }
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )
            .padding(16)
            .background(
                StrengthLabFigmaTheme
                    .paleBlush,
                in:
                    RoundedRectangle(
                        cornerRadius: 22,
                        style:
                            .continuous
                    )
            )
        }
        .buttonStyle(
            .plain
        )
    }


    private func saveMediaEverywhere() {
        guard
            let source =
                mediaCarrier
                ??
                editingMedia
        else {
            return
        }

        StrengthLabExerciseMediaBridge
            .propagateAppMedia(
                from:
                    source,
                definition:
                    exercise,
                in:
                    modelContext
            )
    }


    @ViewBuilder
    private func detailCard<
        Content: View
    >(
        title: String,
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing: 14
        ) {
            Text(title)
                .font(
                    StrengthLabFigmaTheme
                        .bold(17)
                )

            content()
        }
        .foregroundStyle(
            StrengthLabFigmaTheme
                .ink
        )
        .padding(18)
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
        .background(
            StrengthLabFigmaTheme
                .paleBlush,
            in:
                RoundedRectangle(
                    cornerRadius: 22,
                    style:
                        .continuous
                )
        )
    }


    @ViewBuilder
    private func roleRow(
        title: String,
        values: [String]
    ) -> some View {

        if !values.isEmpty {
            VStack(
                alignment:
                    .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(12)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                Text(
                    values
                        .map {
                            StrengthLabExerciseLibrary
                                .displayName(
                                    $0
                                )
                        }
                        .joined(
                            separator:
                                ", "
                        )
                )
                .font(
                    StrengthLabFigmaTheme
                        .regular(15)
                )
            }
        }
    }


    private func exerciseKey(
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
}



private struct CustomExerciseLibraryDetailView:
    View
{
    @Environment(\.modelContext)
    private var modelContext

    let exercise:
        CustomLibraryExercise

    @State
    private var showingMedia =
        false


    var body: some View {
        ScrollView {
            VStack(
                alignment:
                    .leading,
                spacing: 22
            ) {
                if
                    StrengthLabExerciseMediaBridge
                        .hasMedia(
                            exercise.exercise
                        )
                {
                    ExerciseMediaPlaybackView(
                        exercise:
                            exercise.exercise
                    )
                    .frame(
                        height: 240
                    )
                    .background(
                        Color.black
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style:
                                .continuous
                        )
                    )
                }

                VStack(
                    alignment:
                        .leading,
                    spacing: 8
                ) {
                    Text(
                        "CUSTOM EXERCISE"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(12)
                    )
                    .tracking(1.5)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                    Text(
                        exercise.name
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(28)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                    Text(
                        exercise.equipment
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .medium(15)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }

                Button {
                    showingMedia =
                        true

                } label: {
                    HStack(
                        spacing: 14
                    ) {
                        Circle()
                            .fill(
                                StrengthLabFigmaTheme
                                    .blush
                            )
                            .frame(
                                width: 46,
                                height: 46
                            )
                            .overlay {
                                Image(
                                    systemName:
                                        "photo.on.rectangle.angled"
                                )
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .coral
                                )
                            }

                        VStack(
                            alignment:
                                .leading,
                            spacing: 3
                        ) {
                            Text(
                                StrengthLabExerciseMediaBridge
                                    .hasMedia(
                                        exercise
                                            .exercise
                                    )
                                ? "Edit Media"
                                : "Add Media"
                            )
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(16)
                            )

                            Text(
                                "Video, GIF and demo trimming"
                            )
                            .font(
                                StrengthLabFigmaTheme
                                    .regular(13)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .muted
                            )
                        }

                        Spacer()

                        Image(
                            systemName:
                                "chevron.right"
                        )
                    }
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .padding(16)
                    .background(
                        StrengthLabFigmaTheme
                            .paleBlush,
                        in:
                            RoundedRectangle(
                                cornerRadius: 22,
                                style:
                                    .continuous
                            )
                    )
                }
                .buttonStyle(
                    .plain
                )

                if
                    !exercise
                        .muscleNames
                        .isEmpty
                {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 8
                    ) {
                        Text(
                            "Muscles"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(17)
                        )

                        Text(
                            exercise
                                .muscleNames
                                .joined(
                                    separator:
                                        ", "
                                )
                        )
                    }
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .padding(18)
                    .frame(
                        maxWidth:
                            .infinity,
                        alignment:
                            .leading
                    )
                    .background(
                        StrengthLabFigmaTheme
                            .paleBlush,
                        in:
                            RoundedRectangle(
                                cornerRadius: 22,
                                style:
                                    .continuous
                            )
                    )
                }

                if
                    let note =
                        exercise
                            .exercise
                            .note,
                    !note.isEmpty
                {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 8
                    ) {
                        Text(
                            "Notes"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(17)
                        )

                        Text(note)
                    }
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .padding(18)
                    .background(
                        StrengthLabFigmaTheme
                            .paleBlush,
                        in:
                            RoundedRectangle(
                                cornerRadius: 22,
                                style:
                                    .continuous
                            )
                    )
                }
            }
            .padding(
                .horizontal,
                24
            )
            .padding(
                .bottom,
                40
            )
        }
        .background(
            Color.white
                .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            isPresented:
                $showingMedia,
            onDismiss: {
                saveMediaEverywhere()
            }
        ) {
            LibraryExerciseMediaSheet(
                exercise:
                    exercise.exercise
            ) {
                saveMediaEverywhere()

                showingMedia =
                    false
            }
        }
    }


    private func saveMediaEverywhere() {
        StrengthLabExerciseMediaBridge
            .propagateCustomMedia(
                from:
                    exercise.exercise,
                in:
                    modelContext
            )
    }
}



private struct LibraryExerciseMediaSheet:
    View
{
    let exercise:
        SetDeckExercise

    let onDone:
        () -> Void

    var body: some View {
        NavigationStack {
            Form {
                ExerciseMediaEditorWithTrim(
                    exercise:
                        exercise
                )
            }
            .navigationTitle(
                "Exercise Media"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button(
                        "Done"
                    ) {
                        onDone()
                    }
                }
            }
        }
        .preferredColorScheme(
            .light
        )
    }
}
