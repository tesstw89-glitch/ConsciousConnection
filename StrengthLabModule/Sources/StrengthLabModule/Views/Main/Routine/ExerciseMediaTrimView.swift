import SwiftUI
import Combine
import SwiftData
import AVKit
import AVFoundation
import ImageIO
import UIKit

private enum ExerciseClipSource: String, CaseIterable, Identifiable {
    case gif = "GIF"
    case video = "Video"

    var id: String { rawValue }
}


// MARK: - Main Trimmer

struct ExerciseMediaTrimView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Bindable
    var exercise: SetDeckExercise

    @StateObject
    private var gifLoader = StrengthLabGIFLoader()

    @State
    private var source: ExerciseClipSource = .gif

    @State
    private var startTime: Double = 0

    @State
    private var endTime: Double = 1

    @State
    private var videoDuration: Double = 0

    @State
    private var isLoadingVideo = false

    private var duration: Double {
        let raw: Double

        switch source {
        case .gif:
            raw = gifLoader.duration

        case .video:
            raw = videoDuration
        }

        guard
            raw.isFinite,
            raw > 0
        else {
            return 0
        }

        return raw
    }

    private var availableSources: [ExerciseClipSource] {
        var result: [ExerciseClipSource] = []

        if exercise.gifURL != nil {
            result.append(.gif)
        }

        if directVideoURL != nil {
            result.append(.video)
        }

        return result
    }

    private var directVideoURL: URL? {
        if
            let imported =
                exercise.importedVideoURL,
            imported.isFileURL,
            FileManager.default.fileExists(
                atPath: imported.path
            )
        {
            return imported
        }

        guard
            let url =
                exercise.videoURL
        else {
            return nil
        }

        if url.isFileURL {
            return
                FileManager.default.fileExists(
                    atPath: url.path
                )
                ? url
                : nil
        }

        let ext =
            url.pathExtension
                .lowercased()

        let supported = [
            "mp4",
            "mov",
            "m4v",
            "m3u8"
        ]

        return supported.contains(ext)
            ? url
            : nil
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 28
                ) {
                    preview

                    if availableSources.count > 1 {
                        Picker(
                            "Media",
                            selection: $source
                        ) {
                            ForEach(
                                availableSources
                            ) { source in
                                Text(source.rawValue)
                                    .tag(source)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {
                        HStack {
                            VStack(
                                alignment: .leading,
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
                                    clipTime(
                                        startTime
                                    )
                                )
                                .font(
                                    StrengthLabFigmaTheme
                                        .bold(22)
                                )
                                .monospacedDigit()
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .ink
                                )
                            }

                            Spacer()

                            VStack(
                                alignment: .trailing,
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
                                    clipTime(
                                        endTime
                                    )
                                )
                                .font(
                                    StrengthLabFigmaTheme
                                        .bold(22)
                                )
                                .monospacedDigit()
                                .foregroundStyle(
                                    StrengthLabFigmaTheme
                                        .ink
                                )
                            }
                        }

                        TrimRangeSlider(
                            start: $startTime,
                            end: $endTime,
                            duration:
                                max(
                                    duration,
                                    0.01
                                )
                        )

                        HStack {
                            Text("Selected clip")

                            Spacer()

                            Text(
                                clipDurationText
                            )
                            .monospacedDigit()
                        }
                        .font(
                            StrengthLabFigmaTheme
                                .medium(14)
                        )
                        .foregroundStyle(
                            StrengthLabFigmaTheme
                                .muted
                        )
                    }
                    .padding(20)
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 24,
                            style: .continuous
                        )
                        .stroke(
                            Color.black.opacity(
                                0.08
                            ),
                            lineWidth: 1.3
                        )
                    }

                    VStack(spacing: 12) {
                        Button {
                            saveTrim()
                        } label: {
                            Text("Use Clip")
                                .font(
                                    StrengthLabFigmaTheme
                                        .medium(16)
                                )
                                .foregroundStyle(
                                    .white
                                )
                                .frame(
                                    maxWidth:
                                        .infinity
                                )
                                .frame(height: 56)
                                .background(
                                    StrengthLabFigmaTheme
                                        .coralGradient,
                                    in:
                                        RoundedRectangle(
                                            cornerRadius:
                                                17,
                                            style:
                                                .continuous
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            duration <= 0
                        )

                        Button {
                            resetTrim()
                        } label: {
                            Text(
                                "Use Full Length"
                            )
                            .font(
                                StrengthLabFigmaTheme
                                    .medium(15)
                            )
                            .foregroundStyle(
                                StrengthLabFigmaTheme
                                    .coral
                            )
                            .frame(
                                maxWidth:
                                    .infinity
                            )
                            .frame(height: 48)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Trim Demo")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .tint(
            StrengthLabFigmaTheme.coral
        )
        .task {
            configureInitialSource()
            await loadSelectedSource()
        }
        .onChange(of: source) {
            Task {
                await loadSelectedSource()
            }
        }
        .onChange(of: gifLoader.duration) {
            guard source == .gif
            else {
                return
            }

            configureRange(
                for: gifLoader.duration
            )
        }
        .onChange(of: videoDuration) {
            guard source == .video
            else {
                return
            }

            configureRange(
                for: videoDuration
            )
        }
    }

    // MARK: Preview

    @ViewBuilder
    private var preview: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .fill(Color.black)

                switch source {
                case .gif:
                    if gifLoader.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if
                        gifLoader.isReady
                    {
                        TrimmedGIFPlayer(
                            loader:
                                gifLoader,
                            start:
                                startTime,
                            end:
                                max(
                                    startTime +
                                    0.05,
                                    endTime
                                )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 28,
                                style: .continuous
                            )
                        )
                    } else {
                        unavailablePreview
                    }

                case .video:
                    if isLoadingVideo {
                        ProgressView()
                            .tint(.white)
                    } else if
                        let url =
                            directVideoURL
                    {
                        TrimmedVideoPlayer(
                            url: url,
                            start:
                                startTime,
                            end:
                                max(
                                    startTime +
                                    0.05,
                                    endTime
                                )
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 28,
                                style: .continuous
                            )
                        )
                    } else {
                        unavailablePreview
                    }
                }
            }
            .frame(height: 330)

            Text(
                "The preview loops only the selected section."
            )
            .font(
                StrengthLabFigmaTheme
                    .regular(13)
            )
            .foregroundStyle(
                StrengthLabFigmaTheme.muted
            )
        }
    }

    private var unavailablePreview:
        some View
    {
        VStack(spacing: 10) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(.title2)

            Text("Preview unavailable")
                .font(
                    StrengthLabFigmaTheme
                        .medium(14)
                )
        }
        .foregroundStyle(.white)
    }

    // MARK: Loading

    private func configureInitialSource() {
        if exercise.gifURL != nil {
            source = .gif
        } else if directVideoURL != nil {
            source = .video
        }
    }

    @MainActor
    private func loadSelectedSource() async {
        switch source {
        case .gif:
            guard
                let url =
                    exercise.gifURL
            else {
                return
            }

            await gifLoader.load(
                url: url
            )

        case .video:
            guard
                let url =
                    directVideoURL
            else {
                return
            }

            isLoadingVideo = true

            let asset =
                AVURLAsset(url: url)

            do {
                let value =
                    try await asset.load(
                        .duration
                    )

                let seconds =
                    CMTimeGetSeconds(
                        value
                    )

                guard
                    seconds.isFinite,
                    seconds > 0
                else {
                    videoDuration = 0
                    isLoadingVideo = false
                    return
                }

                videoDuration =
                    seconds
            } catch {
                videoDuration = 0
            }

            isLoadingVideo = false
        }
    }

    private func configureRange(
        for duration: Double
    ) {
        guard
            duration.isFinite,
            duration > 0
        else {
            startTime = 0
            endTime = 1
            return
        }

        switch source {
        case .gif:
            startTime =
                min(
                    max(
                        exercise
                            .gifTrimStart ??
                        0,
                        0
                    ),
                    duration
                )

            endTime =
                min(
                    max(
                        exercise
                            .gifTrimEnd ??
                        duration,
                        startTime +
                        0.05
                    ),
                    duration
                )

        case .video:
            startTime =
                min(
                    max(
                        exercise
                            .videoTrimStart ??
                        0,
                        0
                    ),
                    duration
                )

            endTime =
                min(
                    max(
                        exercise
                            .videoTrimEnd ??
                        duration,
                        startTime +
                        0.05
                    ),
                    duration
                )
        }
    }

    // MARK: Actions

    private func saveTrim() {
        let full =
            duration

        guard full > 0
        else {
            return
        }

        switch source {
        case .gif:
            exercise.gifTrimStart =
                startTime <= 0.02
                ? nil
                : startTime

            exercise.gifTrimEnd =
                endTime >=
                full - 0.02
                ? nil
                : endTime

        case .video:
            exercise.videoTrimStart =
                startTime <= 0.02
                ? nil
                : startTime

            exercise.videoTrimEnd =
                endTime >=
                full - 0.02
                ? nil
                : endTime
        }

        Haptics.lightImpact()
        dismiss()
    }

    private func resetTrim() {
        switch source {
        case .gif:
            exercise.gifTrimStart = nil
            exercise.gifTrimEnd = nil

        case .video:
            exercise.videoTrimStart = nil
            exercise.videoTrimEnd = nil
        }

        startTime = 0
        endTime = duration

        Haptics.lightImpact()
    }

    // MARK: Formatting

    private var clipDurationText:
        String
    {
        String(
            format:
                "%.1f sec",
            max(
                0,
                endTime -
                startTime
            )
        )
    }

    private func clipTime(
        _ seconds: Double
    ) -> String {
        let safe =
            seconds.isFinite
            ? max(0, seconds)
            : 0

        let minutes =
            Int(safe) / 60

        let secs =
            safe -
            Double(
                minutes * 60
            )

        return String(
            format:
                "%02d:%04.1f",
            minutes,
            secs
        )
    }
}


// MARK: - Two-handle Timeline

private struct TrimRangeSlider: View {
    @Binding var start: Double
    @Binding var end: Double

    let duration: Double

    private let handleSize:
        CGFloat = 32

    private let minimumClip:
        Double = 0.20

    private var safeDuration:
        Double
    {
        guard
            duration.isFinite,
            duration > 0.001
        else {
            return 0.01
        }

        return duration
    }

    var body: some View {
        GeometryReader { proxy in
            let width =
                max(
                    1,
                    proxy.size.width
                )

            let startX =
                CGFloat(
                    start /
                    safeDuration
                ) * width

            let endX =
                CGFloat(
                    end /
                    safeDuration
                ) * width

            ZStack(
                alignment: .leading
            ) {
                Capsule()
                    .fill(
                        StrengthLabFigmaTheme
                            .blush
                    )
                    .frame(height: 12)

                Capsule()
                    .fill(
                        StrengthLabFigmaTheme
                            .coral
                    )
                    .frame(
                        width:
                            max(
                                0,
                                endX -
                                startX
                            ),
                        height: 12
                    )
                    .offset(x: startX)

                trimHandle(
                    systemName:
                        "chevron.right.2"
                )
                .position(
                    x:
                        clampHandleX(
                            startX,
                            width:
                                width
                        ),
                    y:
                        proxy.size
                            .height / 2
                )
                .gesture(
                    DragGesture(
                        minimumDistance: 0
                    )
                    .onChanged {
                        value in

                        let fraction =
                            min(
                                max(
                                    value
                                        .location
                                        .x /
                                    width,
                                    0
                                ),
                                1
                            )

                        start =
                            min(
                                fraction *
                                safeDuration,
                                end -
                                minimumClip
                            )

                        start =
                            max(
                                0,
                                start
                            )
                    }
                )

                trimHandle(
                    systemName:
                        "chevron.left.2"
                )
                .position(
                    x:
                        clampHandleX(
                            endX,
                            width:
                                width
                        ),
                    y:
                        proxy.size
                            .height / 2
                )
                .gesture(
                    DragGesture(
                        minimumDistance: 0
                    )
                    .onChanged {
                        value in

                        let fraction =
                            min(
                                max(
                                    value
                                        .location
                                        .x /
                                    width,
                                    0
                                ),
                                1
                            )

                        end =
                            max(
                                fraction *
                                safeDuration,
                                start +
                                minimumClip
                            )

                        end =
                            min(
                                safeDuration,
                                end
                            )
                    }
                )
            }
        }
        .frame(height: 54)
    }

    private func trimHandle(
        systemName: String
    ) -> some View {
        Circle()
            .fill(Color.white)
            .frame(
                width: handleSize,
                height: handleSize
            )
            .overlay {
                Image(
                    systemName:
                        systemName
                )
                .font(
                    .system(
                        size: 9,
                        weight: .black
                    )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .coral
                )
            }
            .overlay {
                Circle()
                    .stroke(
                        StrengthLabFigmaTheme
                            .coral,
                        lineWidth: 3
                    )
            }
            .shadow(
                color:
                    Color.black
                        .opacity(0.12),
                radius: 5,
                y: 2
            )
    }

    private func clampHandleX(
        _ value: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        min(
            max(
                value,
                handleSize / 2
            ),
            width -
            handleSize / 2
        )
    }
}


// MARK: - GIF Loader

@MainActor
final class StrengthLabGIFLoader:
    ObservableObject
{
    @Published
    private(set)
    var duration: Double = 0

    @Published
    private(set)
    var isLoading = false

    @Published
    private(set)
    var isReady = false

    private var source:
        CGImageSource?

    private var frameStarts:
        [Double] = []

    private var frameDurations:
        [Double] = []

    private let cache =
        NSCache<
            NSNumber,
            UIImage
        >()

    private var loadedURL:
        URL?

    init() {
        cache.countLimit = 28
    }

    func load(
        url: URL
    ) async {
        if
            loadedURL == url,
            isReady
        {
            return
        }

        isLoading = true
        isReady = false

        do {
            let data: Data

            if url.isFileURL {
                data =
                    try Data(
                        contentsOf: url
                    )
            } else {
                let result =
                    try await URLSession
                        .shared
                        .data(
                            from: url
                        )

                data = result.0
            }

            guard
                let source =
                    CGImageSourceCreateWithData(
                        data as CFData,
                        nil
                    )
            else {
                isLoading = false
                return
            }

            var starts:
                [Double] = []

            var durations:
                [Double] = []

            let count =
                CGImageSourceGetCount(
                    source
                )

            var cursor: Double = 0

            for index in 0..<count {
                starts.append(cursor)

                let delay =
                    Self.frameDelay(
                        source:
                            source,
                        index:
                            index
                    )

                durations.append(delay)
                cursor += delay
            }

            self.source = source
            self.frameStarts = starts
            self.frameDurations =
                durations
            self.duration = cursor
            self.loadedURL = url
            self.isReady =
                count > 0 &&
                cursor > 0

        } catch {
            duration = 0
            isReady = false
        }

        isLoading = false
    }

    func image(
        at sourceTime: Double
    ) -> UIImage? {
        guard
            let source,
            !frameStarts.isEmpty
        else {
            return nil
        }

        let index =
            frameIndex(
                at: sourceTime
            )

        let key =
            NSNumber(
                value: index
            )

        if
            let cached =
                cache.object(
                    forKey: key
                )
        {
            return cached
        }

        guard
            let cgImage =
                CGImageSourceCreateImageAtIndex(
                    source,
                    index,
                    nil
                )
        else {
            return nil
        }

        let image =
            UIImage(
                cgImage: cgImage
            )

        cache.setObject(
            image,
            forKey: key
        )

        return image
    }

    private func frameIndex(
        at time: Double
    ) -> Int {
        guard
            frameStarts.count > 1
        else {
            return 0
        }

        let clamped =
            min(
                max(
                    time,
                    0
                ),
                max(
                    duration -
                    0.0001,
                    0
                )
            )

        var low = 0
        var high =
            frameStarts.count - 1

        while low <= high {
            let mid =
                (low + high) / 2

            let start =
                frameStarts[mid]

            let end =
                start +
                frameDurations[mid]

            if clamped < start {
                high = mid - 1
            } else if
                clamped >= end
            {
                low = mid + 1
            } else {
                return mid
            }
        }

        return min(
            max(low, 0),
            frameStarts.count - 1
        )
    }

    private static func frameDelay(
        source: CGImageSource,
        index: Int
    ) -> Double {
        guard
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    index,
                    nil
                ) as? [CFString: Any],
            let gif =
                properties[
                    kCGImagePropertyGIFDictionary
                ] as? [CFString: Any]
        else {
            return 1.0 / 12.0
        }

        if
            let unclamped =
                gif[
                    kCGImagePropertyGIFUnclampedDelayTime
                ] as? Double,
            unclamped > 0.01
        {
            return unclamped
        }

        if
            let delay =
                gif[
                    kCGImagePropertyGIFDelayTime
                ] as? Double,
            delay > 0.01
        {
            return delay
        }

        return 1.0 / 12.0
    }
}


// MARK: - Trimmed GIF Playback

private struct TrimmedGIFPlayer:
    View
{
    @ObservedObject
    var loader:
        StrengthLabGIFLoader

    let start: Double
    let end: Double

    @State
    private var epoch = Date()

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval:
                    1.0 / 12.0
            )
        ) { context in
            let clipDuration =
                max(
                    0.05,
                    end - start
                )

            let elapsed =
                context.date
                    .timeIntervalSince(
                        epoch
                    )

            let local =
                elapsed
                    .truncatingRemainder(
                        dividingBy:
                            clipDuration
                    )

            let sourceTime =
                start + local

            if
                let image =
                    loader.image(
                        at: sourceTime
                    )
            {
                Image(
                    uiImage: image
                )
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth:
                        .infinity,
                    maxHeight:
                        .infinity
                )
                .background(
                    Color.black
                )
            } else {
                Color.black
            }
        }
        .onChange(of: start) {
            epoch = Date()
        }
        .onChange(of: end) {
            epoch = Date()
        }
        .onAppear {
            epoch = Date()
        }
    }
}


// MARK: - Trimmed Video Playback

private struct TrimmedVideoPlayer:
    View
{
    let url: URL
    let start: Double
    let end: Double
    // STRENGTHLAB_SILENT_DEMO_V1
    var muteForWorkout = false

    @State
    private var player =
        AVPlayer()

    private let timer =
        Timer.publish(
            every: 0.05,
            on: .main,
            in: .common
        )
        .autoconnect()

    var body: some View {
        VideoPlayer(
            player: player
        )
        .onAppear {
            configure()
        }
        .onDisappear {
            player.pause()
        }
        .onChange(of: url) {
            configure()
        }
        .onChange(of: start) {
            seekToStart()
        }
        .onChange(of: end) {
            seekToStart()
        }
        .onReceive(timer) { _ in
            let current =
                player.currentTime()
                    .seconds

            if
                current.isFinite,
                current >= end - 0.03
            {
                seekToStart()
            }
        }
    }

    private func configure() {
        player.isMuted = muteForWorkout
        let item =
            AVPlayerItem(
                url: url
            )

        player.replaceCurrentItem(
            with: item
        )

        seekToStart()
    }

    private func seekToStart() {
        guard start.isFinite
        else {
            return
        }

        let time =
            CMTime(
                seconds: max(0, start),
                preferredTimescale: 600
            )

        player.seek(
            to: time,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { _ in
            player.play()
        }
    }
}



private struct LoopingExerciseVideoPlayer:
    View
{
    let url:
        URL

    @State
    private var player =
        AVQueuePlayer()

    @State
    private var looper:
        AVPlayerLooper?


    var body: some View {
        VideoPlayer(
            player:
                player
        )
        .allowsHitTesting(false)
        .onAppear {
            configure()
        }
        .onChange(
            of:
                url
        ) {
            configure()
        }
        .onDisappear {
            player.pause()

            looper =
                nil

            player.removeAllItems()
        }
    }


    private func configure()
    {
        player.pause()

        looper =
            nil

        player.removeAllItems()

        player.isMuted =
            true

        player
            .automaticallyWaitsToMinimizeStalling =
            true

        let item =
            AVPlayerItem(
                url:
                    url
            )

        looper =
            AVPlayerLooper(
                player:
                    player,
                templateItem:
                    item
            )

        player.play()
    }
}



// MARK: - Playback Used Around StrengthLab

struct ExerciseMediaPlaybackView:
    View
{
    let exercise:
        SetDeckExercise

    @StateObject
    private var gifLoader =
        StrengthLabGIFLoader()


    var body: some View {
        Group {

            /*
             New StrengthLab exercise-demo format.

             The file itself contains only the desired
             short clip, so AVPlayerLooper can repeat
             it directly with no timer/seeking.
            */
            if
                let demoURL =
                    savedMP4DemoURL
            {
                LoopingExerciseVideoPlayer(
                    url:
                        demoURL
                )

            /*
             Existing GIF media remains available
             as fallback.
            */
            } else if
                let gifURL =
                    StrengthLabMediaPaths.available(exercise.gifURL)
            {
                if
                    exercise
                        .gifTrimStart
                    ==
                    nil
                    &&
                    exercise
                        .gifTrimEnd
                    ==
                    nil
                {
                    ExerciseGIFView(
                        url:
                            gifURL
                    )

                } else {
                    ZStack {
                        Color.black

                        if gifLoader.isReady {
                            TrimmedGIFPlayer(
                                loader:
                                    gifLoader,
                                start:
                                    exercise
                                        .gifTrimStart
                                    ??
                                    0,
                                end:
                                    exercise
                                        .gifTrimEnd
                                    ??
                                    gifLoader
                                        .duration
                            )

                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .task(
                        id:
                            gifURL
                    ) {
                        await gifLoader.load(
                            url:
                                gifURL
                        )
                    }
                }

            /*
             Legacy video path stays intact.
            */
            } else if
                let videoURL =
                    directPlayableVideoURL
            {
                TrimmedVideoPlayer(
                    url:
                        videoURL,
                    start:
                        exercise
                            .videoTrimStart
                    ??
                    0,
                    end:
                        exercise
                            .videoTrimEnd
                    ??
                    999999,
                    muteForWorkout: true
                )

            } else {
                Color.black
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.title)
                            Text(exercise.importedVideoURL != nil || exercise.gifURL != nil
                                 ? "Saved demo is unavailable. Open Exercise Media to re-import it."
                                 : "No demo added yet")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(24)
                    }
            }
        }
    }


    private var savedMP4DemoURL:
        URL?
    {
        guard
            let imported = StrengthLabMediaPaths.available(exercise.importedVideoURL),
            imported.isFileURL,
            imported.deletingLastPathComponent().lastPathComponent == "ExerciseDemos",
            FileManager.default.fileExists(atPath: imported.path)
        else {
            return nil
        }

        return imported
    }


    private var directPlayableVideoURL:
        URL?
    {
        if
            let imported = StrengthLabMediaPaths.available(exercise.importedVideoURL),
            imported.isFileURL,
            FileManager.default.fileExists(atPath: imported.path)
        {
            return imported
        }

        guard
            let url = StrengthLabMediaPaths.available(exercise.videoURL)
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

        let supported = [
            "mp4",
            "mov",
            "m4v",
            "m3u8"
        ]

        return
            supported.contains(
                url.pathExtension
                    .lowercased()
            )
            ? url
            : nil
    }
}
