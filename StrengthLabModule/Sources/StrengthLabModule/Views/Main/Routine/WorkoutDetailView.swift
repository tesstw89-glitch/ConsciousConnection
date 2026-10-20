import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct WorkoutDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let workout: WorkoutTemplate

    @Environment(\.openURL)
    private var openURL

    @State private var coverImage: UIImage?
    @State private var showingCoverOptions = false
    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var isImportingCover = false
    @State private var showingCoverError = false
    @State private var coverErrorMessage = ""


    @State
    private var editingExercise:
        SetDeckExercise?

    @State
    private var editingWorkout = false

    @State
    private var showingCalendar = false

    @State
    private var runningWorkout = false

    private var exercises:
        [SetDeckExercise]
    {
        (workout.exercises ?? [])
            .sorted {
                $0.orderIndex <
                    $1.orderIndex
            }
    }

    private var heroExercise:
        SetDeckExercise?
    {
        exercises.first {
            $0.gifURL != nil
        } ?? exercises.first
    }

    private var setCount: Int {
        exercises.reduce(0) {
            $0 +
            ($1.sets?.count ?? 0)
        }
    }

    var body: some View {
        ZStack {
            StrengthLabContourBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                hero
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    tag(
                        "\(exercises.count) " +
                        (
                            exercises.count == 1
                            ? "exercise"
                            : "exercises"
                        )
                    )

                    tag(
                        "\(setCount) " +
                        (
                            setCount == 1
                            ? "set"
                            : "sets"
                        )
                    )
                }
                .padding(.top, 22)

                Text(workout.name)
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )
                    .padding(.top, 13)

                Text(
                    exercises.isEmpty
                    ? "Add exercises to build this workout"
                    : "Ready whenever you are"
                )
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                        .opacity(0.75)
                )
                .padding(.top, 20)

                Spacer()
                    .frame(height: 62)

                exerciseSheet
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            coverImage = StrengthLabWorkoutCoverStore.load(
                for: workout.uuid
            )
        }
        .sheet(isPresented: $showingCoverOptions) {
            coverOptionsSheet
        }
        .onChange(of: selectedCoverPhoto) { _, item in
            guard let item else { return }

            Task {
                await importCoverPhoto(item)
            }
        }
        .sheet(
            item: $editingExercise
        ) { exercise in
            WorkoutTemplateExerciseEditor(
                exercise: exercise
            )
        }
        .sheet(
            isPresented: $editingWorkout
        ) {
            WorkoutTemplateEditorView(
                workout: workout
            )
        }
        .fullScreenCover(
            isPresented: $showingCalendar
        ) {
            WorkoutScheduleSheet(
                workout: workout
            )
        }
        .fullScreenCover(
            isPresented: $runningWorkout
        ) {
            WorkoutRunView(
                workout: workout
            )
        }
    }

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

            Menu {
                Button {
                    editingWorkout = true
                } label: {
                    Label(
                        "Edit Workout",
                        systemImage: "pencil"
                    )
                }

                Button {
                    showingCalendar = true
                } label: {
                    Label(
                        "Schedule",
                        systemImage:
                            "calendar.badge.plus"
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


    // MARK: - Workout Cover

    private var hero: some View {
        Button {
            showingCoverOptions = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black)

                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())

                } else if let url = heroExercise?.gifURL {
                    ExerciseGIFView(url: url)
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())

                } else {
                    Circle()
                        .fill(
                            StrengthLabFigmaTheme.coral.opacity(0.16)
                        )
                        .overlay {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    StrengthLabFigmaTheme.coral
                                )
                        }
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        StrengthLabFigmaTheme.coral,
                        in: Circle()
                    )
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            coverImage == nil
            ? "Add workout cover photo"
            : "Change workout cover photo"
        )
    }

    private var coverOptionsSheet: some View {
        VStack(alignment: .leading, spacing: 18) {

            Text("Workout Cover")
                .font(.title2.bold())
                .foregroundStyle(.black)

            Text(
                "Create your artwork in Canva, save it to Photos, then import it here."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                launchCanvaApp()
            } label: {
                Label(
                    "Design in Canva",
                    systemImage: "paintbrush.pointed.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    Color(red: 1, green: 0.91, blue: 0.94),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .buttonStyle(.plain)

            PhotosPicker(
                selection: $selectedCoverPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    "Import from Photos",
                    systemImage: "photo.on.rectangle"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .buttonStyle(.plain)
            .disabled(isImportingCover)

            if isImportingCover {
                ProgressView("Importing cover…")
                    .frame(maxWidth: .infinity)
            }

            if coverImage != nil {
                Button(role: .destructive) {
                    removeCover()
                } label: {
                    Label(
                        "Remove Cover",
                        systemImage: "trash"
                    )
                    .frame(maxWidth: .infinity)
                }
                .disabled(isImportingCover)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .foregroundStyle(.black)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(
            "Couldn't update cover",
            isPresented: $showingCoverError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(coverErrorMessage)
        }
    }

    @MainActor
    private func importCoverPhoto(
        _ item: PhotosPickerItem
    ) async {
        isImportingCover = true

        defer {
            isImportingCover = false
            selectedCoverPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data) else {
                throw StrengthLabWorkoutCoverError.invalidImage
            }

            coverImage = try StrengthLabWorkoutCoverStore.save(
                image,
                for: workout.uuid
            )

            showingCoverOptions = false

        } catch {
            coverErrorMessage = error.localizedDescription
            showingCoverError = true
        }
    }


    // MARK: - Canva App Launcher

    @MainActor
    private func launchCanvaApp() {

        guard let appURL = URL(
            string: "canvaeditor://"
        ) else {
            return
        }

        UIApplication.shared.open(
            appURL,
            options: [:]
        ) { opened in

            guard !opened else { return }

            // Try Canva's Universal Link, but only if
            // iOS can open the actual installed app.
            // Never fall through to a browser.

            Task { @MainActor in

                guard let universalURL = URL(
                    string: "https://www.canva.com/"
                ) else {
                    return
                }

                UIApplication.shared.open(
                    universalURL,
                    options: [
                        .universalLinksOnly: true
                    ]
                ) { openedUniversal in

                    guard !openedUniversal else { return }

                    // Canva could not be launched.
                    // Open its App Store listing instead.

                    Task { @MainActor in

                        guard let storeURL = URL(
                            string:
                                "itms-apps://itunes.apple.com/app/id897446215"
                        ) else {
                            return
                        }

                        UIApplication.shared.open(
                            storeURL
                        )
                    }
                }
            }
        }
    }

    private func removeCover() {
        do {
            try StrengthLabWorkoutCoverStore.remove(
                for: workout.uuid
            )

            coverImage = nil
            showingCoverOptions = false

        } catch {
            coverErrorMessage = error.localizedDescription
            showingCoverError = true
        }
    }

    private func tag(
        _ title: String
    ) -> some View {
        Text(title)
            .font(
                StrengthLabFigmaTheme
                    .bold(14)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.ink
            )
            .padding(
                .horizontal,
                12
            )
            .frame(height: 30)
            .background(
                Color.white,
                in: RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
    }

    private var exerciseSheet: some View {
        ZStack(
            alignment: .top
        ) {
            RoundedRectangle(
                cornerRadius: 36,
                style: .continuous
            )
            .fill(Color.white)
            .ignoresSafeArea(
                edges: .bottom
            )

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    Text("Exercises")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(16)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                        .padding(.bottom, 28)

                    if exercises.isEmpty {
                        Button {
                            editingWorkout = true
                        } label: {
                            HStack(spacing: 24) {
                                Circle()
                                    .fill(
                                        StrengthLabFigmaTheme
                                            .blush
                                    )
                                    .frame(
                                        width: 48,
                                        height: 48
                                    )
                                    .overlay {
                                        Image(
                                            systemName:
                                                "plus"
                                        )
                                        .foregroundStyle(
                                            StrengthLabFigmaTheme
                                                .ink
                                        )
                                    }

                                Text(
                                    "Add Exercise"
                                )
                                .font(
                                    StrengthLabFigmaTheme
                                        .medium(14)
                                )
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .ink
                                )

                                Spacer()

                                Image(
                                    systemName:
                                        "chevron.right"
                                )
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .ink
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(
                                Array(
                                    exercises
                                        .enumerated()
                                ),
                                id:
                                    \.element.uuid
                            ) {
                                index,
                                exercise in

                                exerciseRow(
                                    exercise,
                                    index: index
                                )
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 58)
                .padding(.bottom, 32)
            }

            Button {
                runningWorkout = true
            } label: {
                Image(
                    systemName:
                        "play.fill"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    width: 65,
                    height: 65
                )
                .background(
                    StrengthLabFigmaTheme
                        .coralGradient,
                    in: Circle()
                )
                .shadow(
                    color:
                        StrengthLabFigmaTheme
                            .coral
                            .opacity(0.35),
                    radius: 14,
                    y: 7
                )
            }
            .buttonStyle(.plain)
            .disabled(exercises.isEmpty)
            .opacity(
                exercises.isEmpty
                ? 0.45
                : 1
            )
            .offset(y: -33)
        }
        .frame(
            maxHeight: .infinity
        )
    }

    private func exerciseRow(
        _ exercise: SetDeckExercise,
        index: Int
    ) -> some View {
        Button {
            editingExercise =
                exercise
        } label: {
            HStack(spacing: 24) {
                Circle()
                    .fill(
                        StrengthLabFigmaTheme
                            .blush
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .overlay {
                        Image(
                            systemName:
                                index.isMultiple(
                                    of: 2
                                )
                                ? "dumbbell.fill"
                                : "figure.strengthtraining.traditional"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )
                    }

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(exercise.name)
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .ink
                        )
                        .lineLimit(1)

                    if
                        exercise
                            .supersetGroupID
                        != nil
                    {
                        Text("SUPERSET")
                            .font(
                                StrengthLabFigmaTheme
                                    .bold(10)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )
                    }
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
            }
            .frame(height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Workout Cover Storage

private enum StrengthLabWorkoutCoverError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "The selected image couldn't be loaded."
    }
}

private enum StrengthLabWorkoutCoverStore {

    private static func fileURL(for id: UUID) throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let folder = root.appendingPathComponent(
            "WorkoutCovers",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        return folder
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("jpg")
    }

    static func load(for id: UUID) -> UIImage? {
        guard let url = try? fileURL(for: id) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
    }

    static func save(
        _ image: UIImage,
        for id: UUID
    ) throws -> UIImage {

        guard image.size.width > 0,
              image.size.height > 0 else {
            throw StrengthLabWorkoutCoverError.invalidImage
        }

        let side: CGFloat = 1024

        let scale = max(
            side / image.size.width,
            side / image.size.height
        )

        let width = image.size.width * scale
        let height = image.size.height * scale

        let drawRect = CGRect(
            x: (side - width) / 2,
            y: (side - height) / 2,
            width: width,
            height: height
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        )

        let processed = renderer.image { context in
            context.cgContext.setFillColor(
                UIColor.white.cgColor
            )

            context.cgContext.fill(
                CGRect(x: 0, y: 0, width: side, height: side)
            )

            image.draw(in: drawRect)
        }

        guard let data = processed.jpegData(
            compressionQuality: 0.85
        ) else {
            throw StrengthLabWorkoutCoverError.invalidImage
        }

        try data.write(
            to: fileURL(for: id),
            options: .atomic
        )

        return processed
    }

    static func remove(for id: UUID) throws {
        let url = try fileURL(for: id)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
