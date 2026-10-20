import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import Foundation

struct ExerciseMediaEditorWithTrim: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable
    var exercise:
        SetDeckExercise

    @State
    private var selectedPhoneVideo:
        PhotosPickerItem?

    @State
    private var showFileImporter =
        false

    @State
    private var showVideoEditor =
        false

    @State
    private var isImportingPhoneVideo =
        false

    @State
    private var phoneImportError:
        String?

    var body: some View {
        ExerciseMediaEditor(
            exercise:
                exercise
        )

        Section(
            "Exercise Demo"
        ) {
            if
                importedVideoAvailable
            {
                NavigationLink {
                    ExerciseVideoToGIFEditorView(
                        exercise:
                            exercise
                    )

                } label: {
                    HStack(
                        spacing: 14
                    ) {
                        Circle()
                            .fill(
                                StrengthLabFigmaTheme
                                    .paleBlush
                            )
                            .frame(
                                width: 42,
                                height: 42
                            )
                            .overlay {
                                Image(
                                    systemName:
                                        "wand.and.stars"
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
                                exercise.gifURL
                                == nil
                                ? "Create MP4 Demo"
                                : "Edit MP4 Demo"
                            )

                            Text(
                                exercise.gifURL
                                == nil
                                ? "Trim the source video and save a crisp MP4 loop"
                                : "Choose a different section of the source video"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
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
                            .secondary
                        )
                    }
                }

                Text(
                    "Your source video is stored on this iPhone. Save only the short section you want in the workout."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Divider()
            }

            if
                isImportingPhoneVideo
            {
                HStack(
                    spacing: 12
                ) {
                    ProgressView()

                    Text(
                        "Saving video to StrengthLab…"
                    )
                    .font(.callout)
                }
            }

            if
                let phoneImportError
            {
                Label(
                    phoneImportError,
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(
                    .red
                )
            }

            PhotosPicker(
                selection:
                    $selectedPhoneVideo,
                matching:
                    .videos
            ) {
                phoneImportRow(
                    title:
                        importedVideoAvailable
                        ? "Replace Video from Photos"
                        : "Choose Video from Photos",
                    subtitle:
                        "Pick a video already saved on your iPhone",
                    systemName:
                        "photo.on.rectangle.angled"
                )
            }
            .buttonStyle(
                .plain
            )

            Button {
                showFileImporter =
                    true

            } label: {
                phoneImportRow(
                    title:
                        importedVideoAvailable
                        ? "Replace Video from Files"
                        : "Choose Video from Files",
                    subtitle:
                        "Use a video from Files or iCloud Drive",
                    systemName:
                        "folder.fill"
                )
            }
            .buttonStyle(
                .plain
            )

            if
                exercise.gifURL
                != nil
                &&
                importedVideoAvailable
            {
                Text(
                    "Your existing GIF is kept as fallback media."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Divider()

            NavigationLink {
                ExerciseYouTubeImportView(
                    exercise:
                        exercise
                )

            } label: {
                HStack(
                    spacing: 12
                ) {
                    Image(
                        systemName:
                            "laptopcomputer.and.arrow.down"
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(
                            importedVideoAvailable
                            ? "Download Another YouTube Source"
                            : "YouTube → MP4 Demo"
                        )

                        Text(
                            "Download, trim and save a looping MP4 demo"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }
        }
        .onChange(
            of:
                selectedPhoneVideo
        ) {
            _,
            item in

            guard
                let item
            else {
                return
            }

            Task {
                await importPhotoVideo(
                    item
                )
            }
        }
        .fileImporter(
            isPresented:
                $showFileImporter,
            allowedContentTypes:
                [
                    .movie
                ],
            allowsMultipleSelection:
                false
        ) {
            result in

            Task {
                await importFileResult(
                    result
                )
            }
        }
        .sheet(
            isPresented:
                $showVideoEditor
        ) {
            NavigationStack {
                ExerciseVideoToGIFEditorView(
                    exercise:
                        exercise
                )
            }
        }


        if
            exercise.gifURL != nil
            ||
            exercise.gifSourceURL != nil
        {
            Section(
                "Legacy GIF Tools"
            ) {
                if
                    exercise
                        .importedVideoURL
                    != nil
                {
                    NavigationLink {
                        ExerciseVideoToGIFEditorView(
                            exercise:
                                exercise
                        )

                    } label: {
                        Label(
                            "Edit MP4 Demo",
                            systemImage:
                                "slider.horizontal.3"
                        )
                    }

                    Text(
                        "This now edits the local MP4 exercise demo. Your saved source link is kept separately."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                } else {
                    NavigationLink {
                        ExerciseGIFEditorView(
                            exercise:
                                exercise
                        )

                    } label: {
                        Label(
                            "Edit GIF",
                            systemImage:
                                "slider.horizontal.3"
                        )
                    }

                    Text(
                        "Trim, change frame rate and resize the existing GIF."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }


        if
            exercise.gifURL
                != nil
            ||
            directPlayableVideoURL
                != nil
        {
            Section(
                "Clip"
            ) {
                NavigationLink {
                    ExerciseMediaTrimView(
                        exercise:
                            exercise
                    )

                } label: {
                    HStack(
                        spacing: 14
                    ) {
                        Image(
                            systemName:
                                "timeline.selection"
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .coral
                        )

                        VStack(
                            alignment:
                                .leading,
                            spacing: 3
                        ) {
                            Text(
                                "Trim Demo"
                            )

                            Text(
                                trimSummary
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
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
                            .secondary
                        )
                    }
                }
            }
        }
    }


    private var importedVideoAvailable:
        Bool
    {
        guard
            let url =
                exercise
                    .importedVideoURL
        else {
            return false
        }

        if !url.isFileURL {
            return true
        }

        return
            FileManager
                .default
                .fileExists(
                    atPath:
                        url.path
                )
    }


    private func phoneImportRow(
        title: String,
        subtitle: String,
        systemName: String
    ) -> some View
    {
        HStack(
            spacing: 14
        ) {
            Circle()
                .fill(
                    StrengthLabFigmaTheme
                        .paleBlush
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .overlay {
                    Image(
                        systemName:
                            systemName
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .ink
                    )

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Spacer()
        }
    }


    @MainActor
    private func importPhotoVideo(
        _ item:
            PhotosPickerItem
    ) async
    {
        isImportingPhoneVideo =
            true

        phoneImportError =
            nil

        defer {
            selectedPhoneVideo =
                nil

            isImportingPhoneVideo =
                false
        }

        do {
            guard
                let data =
                    try await item
                        .loadTransferable(
                            type:
                                Data.self
                        )
            else {
                throw PhoneVideoImportError
                    .couldNotReadVideo
            }

            let fileExtension =
                item
                    .supportedContentTypes
                    .first(
                        where: {
                            $0.conforms(
                                to:
                                    .movie
                            )
                        }
                    )?
                    .preferredFilenameExtension
                ??
                "mov"

            let destination =
                try importedVideoDestination(
                    fileExtension:
                        fileExtension
                )

            let temporary =
                destination
                    .deletingLastPathComponent()
                    .appendingPathComponent(
                        ".incoming-\(UUID().uuidString)"
                    )
                    .appendingPathExtension(
                        fileExtension
                    )

            try await Task.detached {
                try data.write(
                    to:
                        temporary,
                    options:
                        .atomic
                )

                try replaceVideoFile(
                    temporary:
                        temporary,
                    destination:
                        destination
                )
            }
            .value

            try finishPhoneVideoImport(
                destination
            )

        } catch {
            phoneImportError =
                error.localizedDescription
        }
    }


    @MainActor
    private func importFileResult(
        _ result:
            Result<
                [URL],
                Error
            >
    ) async
    {
        isImportingPhoneVideo =
            true

        phoneImportError =
            nil

        defer {
            isImportingPhoneVideo =
                false
        }

        do {
            let urls =
                try result.get()

            guard
                let source =
                    urls.first
            else {
                throw PhoneVideoImportError
                    .couldNotReadVideo
            }

            let fileExtension =
                source
                    .pathExtension
                    .isEmpty
                ? "mov"
                : source.pathExtension

            let destination =
                try importedVideoDestination(
                    fileExtension:
                        fileExtension
                )

            let temporary =
                destination
                    .deletingLastPathComponent()
                    .appendingPathComponent(
                        ".incoming-\(UUID().uuidString)"
                    )
                    .appendingPathExtension(
                        fileExtension
                    )

            let accessed =
                source
                    .startAccessingSecurityScopedResource()

            defer {
                if accessed {
                    source
                        .stopAccessingSecurityScopedResource()
                }
            }

            try await Task.detached {
                let manager =
                    FileManager.default

                if manager.fileExists(
                    atPath:
                        temporary.path
                ) {
                    try manager.removeItem(
                        at:
                            temporary
                    )
                }

                try manager.copyItem(
                    at:
                        source,
                    to:
                        temporary
                )

                try replaceVideoFile(
                    temporary:
                        temporary,
                    destination:
                        destination
                )
            }
            .value

            try finishPhoneVideoImport(
                destination
            )

        } catch {
            phoneImportError =
                error.localizedDescription
        }
    }


    @MainActor
    private func finishPhoneVideoImport(
        _ destination:
            URL
    ) throws
    {
        let previous =
            exercise
                .importedVideoURL

        exercise.importedVideoURL =
            destination

        /*
         Deliberately preserve:
         - gifURL
         - gifSourceURL
         - GIF trim
         - FPS
         - output size

         The existing demo therefore stays intact until
         the user explicitly creates/saves a replacement.
        */

        try modelContext.save()

        // Keep the previous source. Other workouts may still reference it.
        _ = previous

        phoneImportError =
            nil

        showVideoEditor =
            true
    }


    private func importedVideoDestination(
        fileExtension:
            String
    ) throws -> URL
    {
        guard
            let base =
                FileManager
                    .default
                    .urls(
                        for:
                            .applicationSupportDirectory,
                        in:
                            .userDomainMask
                    )
                    .first
        else {
            throw PhoneVideoImportError
                .couldNotCreateMediaFolder
        }

        let folder =
            base
                .appendingPathComponent(
                    "StrengthLab",
                    isDirectory:
                        true
                )
                .appendingPathComponent(
                    "ImportedVideos",
                    isDirectory:
                        true
                )

        try FileManager
            .default
            .createDirectory(
                at:
                    folder,
                withIntermediateDirectories:
                    true
            )

        let cleanedExtension =
            fileExtension
                .lowercased()
                .filter {
                    $0.isLetter
                    ||
                    $0.isNumber
                }

        let finalExtension =
            cleanedExtension.isEmpty
            ? "mov"
            : cleanedExtension

        return
            folder
                .appendingPathComponent(
                    exercise
                        .uuid
                        .uuidString
                )
                .appendingPathExtension(
                    finalExtension
                )
    }


    private func replaceVideoFile(
        temporary:
            URL,
        destination:
            URL
    ) throws
    {
        let manager =
            FileManager.default

        if manager.fileExists(
            atPath:
                destination.path
        ) {
            try manager.removeItem(
                at:
                    destination
            )
        }

        try manager.moveItem(
            at:
                temporary,
            to:
                destination
        )
    }


    private var isYouTubeSource:
        Bool
    {
        guard
            let url =
                exercise
                    .videoURL,
            let host =
                url.host?
                    .lowercased()
        else {
            return false
        }

        return
            host
                .contains(
                    "youtube.com"
                )
            ||
            host
                .contains(
                    "youtu.be"
                )
    }


    private var trimSummary:
        String
    {
        if
            let start =
                exercise
                    .gifTrimStart,
            let end =
                exercise
                    .gifTrimEnd
        {
            return String(
                format:
                    "%.1fs → %.1fs",
                start,
                end
            )
        }

        return
            "Full length"
    }


    private var directPlayableVideoURL:
        URL?
    {
        if
            let imported =
                exercise
                    .importedVideoURL,
            (
                !imported.isFileURL
                ||
                FileManager.default
                    .fileExists(
                        atPath:
                            imported.path
                    )
            )
        {
            return imported
        }

        guard
            let url =
                exercise
                    .videoURL
        else {
            return nil
        }

        if url.isFileURL {
            return
                FileManager.default
                    .fileExists(
                        atPath:
                            url.path
                    )
                ? url
                : nil
        }

        return [
            "mp4",
            "mov",
            "m4v",
            "m3u8"
        ]
        .contains(
            url.pathExtension
                .lowercased()
        )
        ? url
        : nil
    }
}


private enum PhoneVideoImportError:
    LocalizedError
{
    case couldNotReadVideo
    case couldNotCreateMediaFolder

    var errorDescription:
        String?
    {
        switch self {

        case .couldNotReadVideo:
            return
                "StrengthLab could not read that video."

        case .couldNotCreateMediaFolder:
            return
                "StrengthLab could not create its local media folder."
        }
    }
}
