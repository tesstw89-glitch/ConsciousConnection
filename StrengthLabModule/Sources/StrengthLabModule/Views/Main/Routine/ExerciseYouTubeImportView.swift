import SwiftUI
import Foundation
import SwiftData
import YouTubeKit


struct ExerciseYouTubeImportView:
    View
{
    @Environment(\.modelContext)
    private var modelContext

    @Bindable
    var exercise:
        SetDeckExercise

    @State
    private var sourceText =
        ""

    @State
    private var isImporting =
        false

    @State
    private var status =
        ""

    @State
    private var errorMessage:
        String?

    @State
    private var showEditor =
        false


    var body: some View {
        ScrollView {
            VStack(
                alignment:
                    .leading,
                spacing: 22
            ) {
                introCard

                sourceCard

                if isImporting {
                    progressCard
                }

                if
                    let errorMessage
                {
                    Label(
                        errorMessage,
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(
                        .red
                    )
                }

                if importedVideoAvailable {
                    existingSourceCard
                }

                importButton
            }
            .padding(24)
            .padding(
                .bottom,
                40
            )
        }
        .background(
            Color.white
                .ignoresSafeArea()
        )
        .navigationTitle(
            "YouTube → Exercise Demo"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .preferredColorScheme(
            .light
        )
        .tint(
            StrengthLabFigmaTheme
                .coral
        )
        .onAppear {
            sourceText =
                exercise
                    .videoURL?
                    .absoluteString
                ??
                ""
        }
        .sheet(
            isPresented:
                $showEditor
        ) {
            NavigationStack {
                ExerciseVideoToGIFEditorView(
                    exercise:
                        exercise
                )
            }
        }
    }


    private var introCard:
        some View
    {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(
                "YOUTUBE → LOOPING MP4"
            )
            .font(
                StrengthLabFigmaTheme
                    .bold(11)
            )
            .tracking(1.4)
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .coral
            )

            Text(
                "Paste a YouTube link. StrengthLab downloads a high-quality video directly on this iPhone, then you choose the short section that will loop during your workout."
            )
            .font(
                StrengthLabFigmaTheme
                    .medium(17)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .ink
            )

            Text(
                "No Mac or local server is required. Use media you have permission to reuse."
            )
            .font(.caption)
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .muted
            )
        }
    }


    private var sourceCard:
        some View
    {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Label(
                "YouTube source",
                systemImage:
                    "play.rectangle.fill"
            )
            .font(
                StrengthLabFigmaTheme
                    .bold(15)
            )

            TextField(
                "https://youtu.be/…",
                text:
                    $sourceText
            )
            .textInputAutocapitalization(
                .never
            )
            .autocorrectionDisabled()
            .keyboardType(
                .URL
            )
            .padding(12)
            .background(
                Color.black
                    .opacity(0.05),
                in:
                    RoundedRectangle(
                        cornerRadius: 12
                    )
            )
        }
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


    private var progressCard:
        some View
    {
        HStack(
            spacing: 14
        ) {
            ProgressView()

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    "Working on iPhone…"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(15)
                )

                Text(
                    status.isEmpty
                    ? "Finding a suitable YouTube video stream…"
                    : status
                )
                .font(.caption)
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
            }
        }
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
                    cornerRadius: 22
                )
        )
    }


    private var existingSourceCard:
        some View
    {
        Button {
            showEditor =
                true

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
                        width: 44,
                        height: 44
                    )
                    .overlay {
                        Image(
                            systemName:
                                "slider.horizontal.3"
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
                    Text(
                        exercise.gifURL == nil
                        ? "Create MP4 Demo"
                        : "Edit MP4 Demo"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )

                    Text(
                        "The source video is ready to trim on this iPhone."
                    )
                    .font(.caption)
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
        }
        .buttonStyle(.plain)
    }


    private var importButton:
        some View
    {
        Button {
            Task {
                await importVideo()
            }

        } label: {
            HStack(
                spacing: 10
            ) {
                if isImporting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(
                        systemName:
                            "arrow.down.circle.fill"
                    )
                }

                Text(
                    isImporting
                    ? "Downloading…"
                    : (
                        importedVideoAvailable
                        ? "Re-download YouTube Source"
                        : "Download & Create Demo"
                    )
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
            }
            .foregroundStyle(
                .white
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 56
            )
            .background(
                StrengthLabFigmaTheme
                    .coralGradient,
                in:
                    RoundedRectangle(
                        cornerRadius: 17
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(
            isImporting
            ||
            sourceText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        )
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

        guard url.isFileURL
        else {
            return true
        }

        return
            FileManager.default
                .fileExists(
                    atPath:
                        url.path
                )
    }


    @MainActor
    private func importVideo()
        async
    {
        let source =
            cleanedYouTubeURL(
                sourceText
            )

        sourceText =
            source

        guard
            let sourceURL =
                URL(
                    string:
                        source
                ),
            isYouTubeURL(
                sourceURL
            )
        else {
            errorMessage =
                "That does not look like a valid YouTube URL."
            return
        }

        isImporting =
            true

        errorMessage =
            nil

        status =
            "Reading the YouTube page…"

        defer {
            isImporting =
                false
        }

        do {
            /*
             Explicitly local extraction:
             no Mac and no YouTubeKit remote fallback.
            */
            let video =
                YouTube(
                    url:
                        sourceURL,
                    methods:
                        [.local]
                )

            let streams =
                try await video
                    .streams

            status =
                "Choosing the highest-quality exercise video…"

            let mp4Streams =
                streams.filter {
                    stream in

                    guard
                        stream
                            .includesVideoTrack,
                        stream
                            .isNativelyPlayable,
                        stream
                            .fileExtension
                            ==
                            .mp4,
                        let resolution =
                            stream
                                .videoResolution,
                        resolution > 0
                    else {
                        return false
                    }

                    return true
                }

            /*
             Workout demos are viewed large on a Retina display.

             The old implementation deliberately preferred <= 480p,
             which made even the preserved master look soft when shown
             full-screen.

             Prefer the highest usable MP4 up to 1080p. If YouTube only
             exposes something larger, use the best available stream.
             Audio is not required because exercise demos are silent.
            */
            let preferred =
                mp4Streams.filter {
                    (
                        $0.videoResolution
                        ??
                        Int.max
                    )
                    <= 1080
                }

            let candidates =
                !preferred.isEmpty
                ? preferred
                : mp4Streams

            guard
                let stream =
                    candidates.max(
                        by: {
                            (
                                $0.videoResolution
                                ??
                                0
                            )
                            <
                            (
                                $1.videoResolution
                                ??
                                0
                            )
                        }
                    )
            else {
                throw ImportError
                    .noUsableStream
            }

            status =
                "Downloading \\\(stream.videoResolution ?? 0)p video directly to this iPhone…"

            var request =
                URLRequest(
                    url:
                        stream.url
                )

            request.timeoutInterval =
                300

            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148",
                forHTTPHeaderField:
                    "User-Agent"
            )

            request.setValue(
                "https://www.youtube.com/",
                forHTTPHeaderField:
                    "Referer"
            )

            let (
                temporaryURL,
                response
            ) =
                try await URLSession
                    .shared
                    .download(
                        for:
                            request
                    )

            guard
                let http =
                    response
                        as?
                        HTTPURLResponse,
                (200...299)
                    .contains(
                        http.statusCode
                    )
            else {
                throw ImportError
                    .downloadFailed
            }

            status =
                "Saving source video…"

            let destination =
                try importedVideoURL()

            let incoming =
                destination
                    .deletingLastPathComponent()
                    .appendingPathComponent(
                        ".incoming-\\\(UUID().uuidString).mp4"
                    )

            let manager =
                FileManager.default

            try?
                manager.removeItem(
                    at:
                        incoming
                )

            try manager.copyItem(
                at:
                    temporaryURL,
                to:
                    incoming
            )

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
                    incoming,
                to:
                    destination
            )

            exercise.videoURL =
                sourceURL

            exercise.importedVideoURL =
                destination

            /*
             Deliberately DO NOT modify gifURL here.

             The currently saved GIF remains visible until
             the user explicitly creates a replacement GIF.
            */

            try modelContext.save()

            status =
                "Source ready. Trim and save your demo."

            showEditor =
                true

        } catch {
            errorMessage =
                """
                StrengthLab could not extract/download that YouTube video on this iPhone.

                \\\(error.localizedDescription)

                YouTube changes its stream system occasionally, so YouTubeKit may need updating when that happens.
                """
        }
    }


    private func cleanedYouTubeURL(
        _ input: String
    ) -> String
    {
        var value =
            input.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        if
            value.hasPrefix("["),
            value.hasSuffix(")"),
            let separator =
                value.range(
                    of:
                        "]("
                )
        {
            let end =
                value.index(
                    before:
                        value.endIndex
                )

            value =
                String(
                    value[
                        separator.upperBound..<end
                    ]
                )
        }

        if
            value.hasPrefix("<"),
            value.hasSuffix(">")
        {
            value.removeFirst()
            value.removeLast()
        }

        return value
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    private func isYouTubeURL(
        _ url: URL
    ) -> Bool
    {
        guard
            let host =
                url.host?
                    .lowercased()
        else {
            return false
        }

        return
            host == "youtu.be"
            ||
            host.hasSuffix(
                ".youtube.com"
            )
            ||
            host == "youtube.com"
    }


    private func importedVideoURL()
        throws -> URL
    {
        guard
            let base =
                FileManager.default
                    .urls(
                        for:
                            .applicationSupportDirectory,
                        in:
                            .userDomainMask
                    )
                    .first
        else {
            throw ImportError
                .cannotCreateFile
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

        try FileManager.default
            .createDirectory(
                at:
                    folder,
                withIntermediateDirectories:
                    true
            )

        return
            folder
                .appendingPathComponent(
                    "\\(exercise.uuid.uuidString).mp4"
                )
    }


    enum ImportError:
        LocalizedError
    {
        case noUsableStream
        case downloadFailed
        case cannotCreateFile

        var errorDescription:
            String?
        {
            switch self {

            case .noUsableStream:
                return
                    "No compatible MP4 video stream was available."

            case .downloadFailed:
                return
                    "YouTube returned an error while downloading the video."

            case .cannotCreateFile:
                return
                    "StrengthLab could not create its local media folder."
            }
        }
    }
}
