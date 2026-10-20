import SwiftUI
import SwiftData
import AVKit
import AVFoundation
import Combine


struct ExerciseVideoToGIFEditorView:
    View
{
    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @Bindable
    var exercise:
        SetDeckExercise

    @State
    private var player =
        AVPlayer()

    @State
    private var duration =
        0.0

    @State
    private var startTime =
        0.0

    @State
    private var endTime =
        1.0

    @State
    private var isLoading =
        true

    @State
    private var isSaving =
        false

    @State
    private var errorMessage:
        String?

    @State
    private var savedMessage:
        String?


    private var sourceURL:
        URL?
    {
        guard
            let url =
                exercise
                    .importedVideoURL
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

        return url
    }


    private var safeDuration:
        Double
    {
        guard
            duration.isFinite,
            duration > 0.2
        else {
            return 0.2
        }

        return duration
    }


    private var startSliderRange:
        ClosedRange<Double>
    {
        let upper =
            max(
                0,
                min(
                    endTime - 0.2,
                    safeDuration - 0.2
                )
            )

        return
            0...max(
                0.01,
                upper
            )
    }


    private var endSliderRange:
        ClosedRange<Double>
    {
        let lower =
            min(
                safeDuration,
                max(
                    0.2,
                    startTime + 0.2
                )
            )

        return
            lower...safeDuration
    }


    var body: some View {
        ScrollView {
            VStack(
                alignment:
                    .leading,
                spacing: 22
            ) {
                intro

                videoPreview

                if isLoading {
                    ProgressView(
                        "Reading video…"
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding(30)

                } else if
                    duration.isFinite,
                    duration > 0.2
                {
                    clipControls

                    saveButton
                }

                if
                    let savedMessage
                {
                    Label(
                        savedMessage,
                        systemImage:
                            "checkmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(
                        .green
                    )
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

                if
                    exercise.gifURL
                    != nil
                {
                    Text(
                        "Your existing GIF is being kept as fallback media. Saving this demo does not delete it."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }
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
            "Exercise Demo"
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
        .task {
            await prepareVideo()
        }
        .onReceive(
            Timer
                .publish(
                    every: 0.05,
                    on: .main,
                    in: .common
                )
                .autoconnect()
        ) { _ in
            loopPreviewIfNeeded()
        }
        .onDisappear {
            player.pause()
        }
    }


    private var intro:
        some View
    {
        VStack(
            alignment:
                .leading,
            spacing: 7
        ) {
            Text(
                "LOOPING MP4 DEMO"
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
                "Choose the short section you want to see during the workout."
            )
            .font(
                StrengthLabFigmaTheme
                    .medium(17)
            )

            Text(
                "StrengthLab saves only that section as a full-colour MP4 and loops it silently."
            )
            .font(.caption)
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .muted
            )
        }
    }


    private var videoPreview:
        some View
    {
        VideoPlayer(
            player:
                player
        )
        .frame(
            height: 300
        )
        .background(
            Color.black
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26,
                style:
                    .continuous
            )
        )
    }


    private var clipControls:
        some View
    {
        VStack(
            alignment:
                .leading,
            spacing: 18
        ) {
            HStack {
                VStack(
                    alignment:
                        .leading,
                    spacing: 3
                ) {
                    Text("START")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(11)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )

                    Text(
                        formatted(
                            startTime
                        )
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(22)
                    )
                    .monospacedDigit()
                }

                Spacer()

                VStack(
                    alignment:
                        .trailing,
                    spacing: 3
                ) {
                    Text("FINISH")
                        .font(
                            StrengthLabFigmaTheme
                                .bold(11)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )

                    Text(
                        formatted(
                            endTime
                        )
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(22)
                    )
                    .monospacedDigit()
                }
            }

            VStack(
                alignment:
                    .leading,
                spacing: 6
            ) {
                Text("Start")
                    .font(
                        .caption
                            .weight(
                                .semibold
                            )
                    )

                Slider(
                    value:
                        $startTime,
                    in:
                        startSliderRange
                )
                .onChange(
                    of:
                        startTime
                ) {
                    seekToStart()
                }
            }

            VStack(
                alignment:
                    .leading,
                spacing: 6
            ) {
                Text("Finish")
                    .font(
                        .caption
                            .weight(
                                .semibold
                            )
                    )

                Slider(
                    value:
                        $endTime,
                    in:
                        endSliderRange
                )
                .onChange(
                    of:
                        endTime
                ) {
                    seekToStart()
                }
            }

            HStack {
                Label(
                    String(
                        format:
                            "%.1f sec",
                        max(
                            0,
                            endTime -
                            startTime
                        )
                    ),
                    systemImage:
                        "scissors"
                )

                Spacer()

                Button(
                    player.timeControlStatus
                    ==
                    .playing
                    ? "Pause"
                    : "Preview Loop"
                ) {
                    if
                        player
                            .timeControlStatus
                        ==
                        .playing
                    {
                        player.pause()

                    } else {
                        seekToStart()

                        player.play()
                    }
                }
                .font(
                    .caption
                        .weight(
                            .semibold
                        )
                )
            }
            .font(.caption)
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .muted
            )

            Text(
                "The original YouTube/source link remains saved separately, so you can download it again later if you want a different section."
            )
            .font(.caption)
            .foregroundStyle(
                StrengthLabFigmaTheme
                    .muted
            )
        }
        .padding(18)
        .background(
            StrengthLabFigmaTheme
                .paleBlush,
            in:
                RoundedRectangle(
                    cornerRadius: 22
                )
        )
    }


    private var saveButton:
        some View
    {
        Button {
            Task {
                await saveMP4Demo()
            }

        } label: {
            HStack(
                spacing: 10
            ) {
                if isSaving {
                    ProgressView()
                        .tint(.white)

                } else {
                    Image(
                        systemName:
                            "film.stack.fill"
                    )
                }

                Text(
                    isSaving
                    ? "Saving MP4…"
                    : "Save Exercise Demo"
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
            isSaving
            ||
            endTime <= startTime
        )
    }


    @MainActor
    private func prepareVideo()
        async
    {
        guard
            let sourceURL
        else {
            isLoading =
                false

            errorMessage =
                "The source video is no longer available."

            return
        }

        let asset =
            AVURLAsset(
                url:
                    sourceURL
            )

        do {
            let assetDuration =
                try await asset
                    .load(
                        .duration
                    )

            let seconds =
                CMTimeGetSeconds(
                    assetDuration
                )

            guard
                seconds.isFinite,
                seconds > 0.2
            else {
                throw DemoError
                    .invalidVideo
            }

            duration =
                seconds

            /*
             Reuse old timing where possible.

             Old GIF conversion stored the original
             video start/end times, which makes
             conversion to MP4 much less painful.
            */
            let oldStart =
                exercise
                    .videoTrimStart
                ??
                exercise
                    .gifTrimStart
                ??
                0

            startTime =
                min(
                    max(
                        oldStart,
                        0
                    ),
                    max(
                        0,
                        seconds - 0.2
                    )
                )

            let oldEnd =
                exercise
                    .videoTrimEnd
                ??
                exercise
                    .gifTrimEnd

            endTime =
                min(
                    max(
                        oldEnd
                        ??
                        min(
                            seconds,
                            startTime + 6
                        ),
                        startTime + 0.2
                    ),
                    seconds
                )

            player.replaceCurrentItem(
                with:
                    AVPlayerItem(
                        asset:
                            asset
                    )
            )

            player.isMuted =
                true

            seekToStart()

            player.play()

            isLoading =
                false

        } catch {
            isLoading =
                false

            errorMessage =
                error.localizedDescription
        }
    }


    @MainActor
    private func saveMP4Demo()
        async
    {
        guard
            let sourceURL
        else {
            return
        }

        guard
            startTime.isFinite,
            endTime.isFinite,
            startTime >= 0,
            endTime > startTime
        else {
            errorMessage =
                "The selected video range is invalid."

            return
        }

        isSaving =
            true

        errorMessage =
            nil

        savedMessage =
            nil

        player.pause()

        do {
            let previousSource =
                exercise
                    .importedVideoURL

            let destination =
                try await StrengthLabMP4DemoExporter
                    .export(
                        sourceURL:
                            sourceURL,
                        exerciseID:
                            exercise.uuid,
                        start:
                            startTime,
                        end:
                            endTime
                    )

            /*
             IMPORTANT:
             videoURL is deliberately untouched.

             For a YouTube exercise it continues to
             contain the YouTube URL.
            */
            exercise.importedVideoURL =
                destination

            /*
             The new MP4 file is physically trimmed,
             so it no longer needs playback trim
             metadata.
            */
            exercise.videoTrimStart =
                nil

            exercise.videoTrimEnd =
                nil

            /*
             Do NOT clear:
             - videoURL
             - gifURL
             - gifSourceURL
             - GIF editing metadata

             Existing media remains recoverable.
            */

            try modelContext.save()

            // Keep the original downloaded source: other exercises may share
            // this URL through the global exercise-media library.
            _ = previousSource

            savedMessage =
                "MP4 exercise demo saved."

            Haptics.lightImpact()

            dismiss()

        } catch {
            errorMessage =
                error.localizedDescription
        }

        isSaving =
            false
    }


    private func seekToStart()
    {
        guard
            startTime.isFinite,
            startTime >= 0
        else {
            return
        }

        player.seek(
            to:
                CMTime(
                    seconds:
                        startTime,
                    preferredTimescale:
                        600
                ),
            toleranceBefore:
                .zero,
            toleranceAfter:
                .zero
        )
    }


    private func loopPreviewIfNeeded()
    {
        guard
            endTime.isFinite,
            endTime > startTime
        else {
            return
        }

        let current =
            player
                .currentTime()
                .seconds

        guard
            current.isFinite,
            current >= endTime - 0.03
        else {
            return
        }

        seekToStart()

        player.play()
    }


    private func formatted(
        _ seconds:
            Double
    ) -> String
    {
        let safe =
            seconds.isFinite
            ? max(
                0,
                seconds
            )
            : 0

        let minutes =
            Int(safe) / 60

        let remainder =
            safe
            -
            Double(
                minutes * 60
            )

        return String(
            format:
                "%02d:%04.1f",
            minutes,
            remainder
        )
    }


    private enum DemoError:
        LocalizedError
    {
        case invalidVideo

        var errorDescription:
            String?
        {
            "StrengthLab could not read that video."
        }
    }
}


// MARK: - Short MP4 Export

private enum StrengthLabMP4DemoExporter
{
    enum ExportError:
        LocalizedError
    {
        case invalidRange
        case noVideoTrack
        case cannotCreateTrack
        case cannotCreateExporter
        case mp4Unsupported
        case exportFailed

        var errorDescription:
            String?
        {
            switch self {

            case .invalidRange:
                return
                    "The selected clip range is invalid."

            case .noVideoTrack:
                return
                    "StrengthLab could not find a video track."

            case .cannotCreateTrack:
                return
                    "StrengthLab could not create the trimmed video."

            case .cannotCreateExporter:
                return
                    "StrengthLab could not create the MP4 exporter."

            case .mp4Unsupported:
                return
                    "This source cannot be exported as MP4."

            case .exportFailed:
                return
                    "StrengthLab could not finish saving the MP4 demo."
            }
        }
    }


    static func export(
        sourceURL:
            URL,
        exerciseID:
            UUID,
        start:
            Double,
        end:
            Double
    ) async throws -> URL
    {
        guard
            start.isFinite,
            end.isFinite,
            start >= 0,
            end > start
        else {
            throw ExportError
                .invalidRange
        }

        let asset =
            AVURLAsset(
                url:
                    sourceURL
            )

        let duration =
            try await asset
                .load(
                    .duration
                )

        let fullDuration =
            CMTimeGetSeconds(
                duration
            )

        guard
            fullDuration.isFinite,
            fullDuration > 0
        else {
            throw ExportError
                .invalidRange
        }

        let safeStart =
            min(
                max(
                    0,
                    start
                ),
                max(
                    0,
                    fullDuration - 0.05
                )
            )

        let safeEnd =
            min(
                max(
                    end,
                    safeStart + 0.05
                ),
                fullDuration
            )

        guard
            safeEnd > safeStart
        else {
            throw ExportError
                .invalidRange
        }

        let sourceTracks =
            try await asset
                .loadTracks(
                    withMediaType:
                        .video
                )

        guard
            let sourceVideo =
                sourceTracks.first
        else {
            throw ExportError
                .noVideoTrack
        }

        /*
         Build a VIDEO-ONLY composition.

         We do not copy the source audio track.
        */
        let composition =
            AVMutableComposition()

        guard
            let targetVideo =
                composition
                    .addMutableTrack(
                        withMediaType:
                            .video,
                        preferredTrackID:
                            kCMPersistentTrackID_Invalid
                    )
        else {
            throw ExportError
                .cannotCreateTrack
        }

        let sourceRange =
            CMTimeRange(
                start:
                    CMTime(
                        seconds:
                            safeStart,
                        preferredTimescale:
                            600
                    ),
                end:
                    CMTime(
                        seconds:
                            safeEnd,
                        preferredTimescale:
                            600
                    )
            )

        try targetVideo
            .insertTimeRange(
                sourceRange,
                of:
                    sourceVideo,
                at:
                    .zero
            )

        if
            let transform =
                try?
                    await sourceVideo
                        .load(
                            .preferredTransform
                        )
        {
            targetVideo
                .preferredTransform =
                transform
        }

        let destination =
            try destinationURL(
                exerciseID:
                    exerciseID
            )

        let incoming =
            destination
                .deletingLastPathComponent()
                .appendingPathComponent(
                    ".incoming-\(UUID().uuidString)"
                )
                .appendingPathExtension(
                    "mp4"
                )

        let manager =
            FileManager.default

        try?
            manager.removeItem(
                at:
                    incoming
            )

        guard
            let exporter =
                AVAssetExportSession(
                    asset:
                        composition,
                    presetName:
                        AVAssetExportPresetHighestQuality
                )
        else {
            throw ExportError
                .cannotCreateExporter
        }

        guard
            exporter
                .supportedFileTypes
                .contains(
                    .mp4
                )
        else {
            throw ExportError
                .mp4Unsupported
        }

        exporter.outputURL =
            incoming

        exporter.outputFileType =
            .mp4

        exporter.shouldOptimizeForNetworkUse =
            true

        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<
                        Void,
                        Error
                    >
            ) in

            exporter
                .exportAsynchronously {
                    switch exporter.status {

                    case .completed:
                        continuation
                            .resume()

                    case .failed,
                         .cancelled:
                        continuation
                            .resume(
                                throwing:
                                    exporter.error
                                    ??
                                    ExportError
                                        .exportFailed
                            )

                    default:
                        continuation
                            .resume(
                                throwing:
                                    ExportError
                                        .exportFailed
                            )
                    }
                }
        }

        /*
         Replace the old short demo ONLY AFTER
         the new export has completed successfully.
        */
        if
            manager.fileExists(
                atPath:
                    destination.path
            )
        {
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

        return destination
    }


    private static func destinationURL(
        exerciseID:
            UUID
    ) throws -> URL
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
            throw ExportError
                .exportFailed
        }

        let folder =
            base
                .appendingPathComponent(
                    "StrengthLab",
                    isDirectory:
                        true
                )
                .appendingPathComponent(
                    "ExerciseDemos",
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
                    exerciseID
                        .uuidString
                )
                .appendingPathExtension(
                    "mp4"
                )
    }
}
