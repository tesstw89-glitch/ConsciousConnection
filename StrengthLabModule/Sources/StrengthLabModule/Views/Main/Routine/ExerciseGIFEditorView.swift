import SwiftUI
import SwiftData
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics


struct ExerciseGIFEditorView:
    View
{
    @Environment(\.modelContext)
    private var modelContext

    @Bindable
    var exercise:
        SetDeckExercise

    @State
    private var info:
        StrengthLabGIFEditInfo?

    @State
    private var targetFPS:
        Int = 12

    @State
    private var outputWidth:
        Int = 0

    @State
    private var isLoading =
        false

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
        exercise.gifSourceURL
        ??
        exercise.gifURL
    }


    private var previewURL:
        URL?
    {
        exercise.gifURL
        ??
        sourceURL
    }


    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    preview

                    if isLoading {
                        ProgressView(
                            "Reading GIF…"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                        .padding(
                            .vertical,
                            30
                        )

                    } else if
                        let info
                    {
                        sourceInfo(
                            info
                        )

                        controls(
                            info
                        )

                        actions
                    }

                    if
                        let errorMessage
                    {
                        Label(
                            errorMessage,
                            systemImage:
                                "exclamationmark.triangle.fill"
                        )
                        .font(
                            .footnote
                        )
                        .foregroundStyle(
                            .red
                        )
                    }

                    if
                        let savedMessage
                    {
                        Label(
                            savedMessage,
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .font(
                            .footnote
                        )
                        .foregroundStyle(
                            .green
                        )
                    }
                }
                .padding(24)
                .padding(
                    .bottom,
                    40
                )
            }
            .scrollIndicators(
                .hidden
            )
        }
        .navigationTitle(
            "Edit GIF"
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
            await loadInformation()
        }
    }


    @ViewBuilder
    private var preview:
        some View
    {
        if
            let previewURL
        {
            ExerciseGIFView(
                url:
                    previewURL
            )
            .id(
                previewURL
            )
            .frame(
                height: 260
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
    }


    private func sourceInfo(
        _ info:
            StrengthLabGIFEditInfo
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(
                "GIF INFO"
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

            HStack {
                infoValue(
                    title:
                        "Frames",
                    value:
                        "\(info.frameCount)"
                )

                Spacer()

                infoValue(
                    title:
                        "Source FPS",
                    value:
                        String(
                            format:
                                "%.1f",
                            info.averageFPS
                        )
                )

                Spacer()

                infoValue(
                    title:
                        "Duration",
                    value:
                        String(
                            format:
                                "%.1fs",
                            info.duration
                        )
                )
            }

            Text(
                "\(info.width) × \(info.height)"
            )
            .font(
                StrengthLabFigmaTheme
                    .medium(14)
            )
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
                    cornerRadius: 22,
                    style:
                        .continuous
                )
        )
    }


    private func controls(
        _ info:
            StrengthLabGIFEditInfo
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 22
        ) {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                HStack {
                    Text(
                        "Frame rate"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(16)
                    )

                    Spacer()

                    Text(
                        "\(targetFPS) FPS"
                    )
                    .font(
                        StrengthLabFigmaTheme
                            .bold(15)
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .coral
                    )
                }

                Slider(
                    value:
                        Binding(
                            get: {
                                Double(
                                    targetFPS
                                )
                            },
                            set: {
                                targetFPS =
                                    Int(
                                        $0.rounded()
                                    )
                            }
                        ),
                    in:
                        3...30,
                    step:
                        1
                )

                HStack {
                    Text("3")
                    Spacer()
                    Text("12")
                    Spacer()
                    Text("20")
                    Spacer()
                    Text("30")
                }
                .font(
                    .caption2
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text(
                    "Output size"
                )
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )

                Picker(
                    "Output size",
                    selection:
                        $outputWidth
                ) {
                    Text(
                        "Original"
                    )
                    .tag(0)

                    Text(
                        "480 px"
                    )
                    .tag(480)

                    Text(
                        "360 px"
                    )
                    .tag(360)

                    Text(
                        "240 px"
                    )
                    .tag(240)
                }
                .pickerStyle(
                    .segmented
                )

                if outputWidth > 0 {
                    Text(
                        "Aspect ratio is preserved. StrengthLab will never upscale a smaller GIF."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        StrengthLabFigmaTheme
                            .muted
                    )
                }
            }

            Divider()

            NavigationLink {
                ExerciseMediaTrimView(
                    exercise:
                        exercise
                )
            } label: {
                HStack {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 3
                    ) {
                        Text(
                            "Trim playback"
                        )
                        .font(
                            StrengthLabFigmaTheme
                                .bold(16)
                        )

                        Text(
                            trimSummary
                        )
                        .font(
                            .caption
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
            }
        }
        .padding(18)
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
                    .opacity(
                        0.08
                    ),
                lineWidth: 1
            )
        }
    }


    private var actions:
        some View
    {
        VStack(
            spacing: 12
        ) {
            Button {
                Task {
                    await saveEditedGIF()
                }
            } label: {
                HStack(
                    spacing: 10
                ) {
                    if isSaving {
                        ProgressView()
                            .tint(
                                .white
                            )
                    }

                    Text(
                        isSaving
                        ? "Creating GIF…"
                        : "Save Edited GIF"
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
                            cornerRadius: 17,
                            style:
                                .continuous
                        )
                )
            }
            .buttonStyle(
                .plain
            )
            .disabled(
                isSaving
                ||
                sourceURL == nil
            )

            if
                exercise
                    .gifSourceURL
                    != nil
                &&
                exercise.gifURL
                    != exercise
                        .gifSourceURL
            {
                Button {
                    restoreOriginal()

                } label: {
                    Text(
                        "Restore Original GIF"
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
                    .frame(
                        height: 48
                    )
                }
                .buttonStyle(
                    .plain
                )
            }
        }
    }


    private func infoValue(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(title)
                .font(
                    .caption2
                        .weight(
                            .semibold
                        )
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .muted
                )

            Text(value)
                .font(
                    StrengthLabFigmaTheme
                        .bold(16)
                )
                .foregroundStyle(
                    StrengthLabFigmaTheme
                        .ink
                )
        }
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

        return "Full length"
    }


    @MainActor
    private func loadInformation()
        async
    {
        guard
            let sourceURL
        else {
            errorMessage =
                "No GIF source is available."

            return
        }

        isLoading =
            true

        errorMessage =
            nil

        do {
            let loaded =
                try await StrengthLabGIFEditEngine
                    .inspect(
                        sourceURL
                    )

            info =
                loaded

            if
                let editedFPS =
                    exercise
                        .gifEditedFPS
            {
                targetFPS =
                    max(
                        3,
                        min(
                            30,
                            Int(
                                editedFPS
                                    .rounded()
                            )
                        )
                    )
            } else {
                targetFPS =
                    max(
                        3,
                        min(
                            30,
                            Int(
                                loaded
                                    .averageFPS
                                    .rounded()
                            )
                        )
                    )
            }

            outputWidth =
                exercise
                    .gifEditedMaxWidth
                ??
                0

        } catch {
            errorMessage =
                error.localizedDescription
        }

        isLoading =
            false
    }


    @MainActor
    private func saveEditedGIF()
        async
    {
        guard
            let sourceURL
        else {
            return
        }

        isSaving =
            true

        errorMessage =
            nil

        savedMessage =
            nil

        do {
            if
                exercise
                    .gifSourceURL
                    == nil
            {
                exercise.gifSourceURL =
                    sourceURL
            }

            let outputURL =
                try await StrengthLabGIFEditEngine
                    .export(
                        sourceURL:
                            sourceURL,
                        exerciseID:
                            exercise.uuid,
                        targetFPS:
                            targetFPS,
                        maxWidth:
                            outputWidth
                            == 0
                            ? nil
                            : outputWidth
                    )

            exercise.gifURL =
                outputURL

            exercise.gifEditedFPS =
                Double(
                    targetFPS
                )

            exercise.gifEditedMaxWidth =
                outputWidth
                == 0
                ? nil
                : outputWidth

            try modelContext.save()

            savedMessage =
                "Edited GIF saved at \(targetFPS) FPS."

        } catch {
            errorMessage =
                error.localizedDescription
        }

        isSaving =
            false
    }


    @MainActor
    private func restoreOriginal()
    {
        guard
            let original =
                exercise
                    .gifSourceURL
        else {
            return
        }

        let oldEdited =
            exercise.gifURL

        exercise.gifURL =
            original

        exercise.gifEditedFPS =
            nil

        exercise.gifEditedMaxWidth =
            nil

        try? modelContext.save()

        // An existing edited GIF may be shared with another workout.
        // Restore this reference without deleting its underlying file.
        _ = oldEdited

        savedMessage =
            "Original GIF restored."
    }
}


struct StrengthLabGIFEditInfo:
    Sendable
{
    let frameCount:
        Int

    let duration:
        Double

    let averageFPS:
        Double

    let width:
        Int

    let height:
        Int
}


enum StrengthLabGIFEditEngine {

    enum EditError:
        LocalizedError
    {
        case invalidGIF
        case cannotCreateOutput
        case cannotEncode

        var errorDescription:
            String?
        {
            switch self {

            case .invalidGIF:
                return
                    "StrengthLab could not read this GIF."

            case .cannotCreateOutput:
                return
                    "StrengthLab could not create the edited GIF file."

            case .cannotEncode:
                return
                    "StrengthLab could not finish encoding the GIF."
            }
        }
    }


    static func inspect(
        _ url: URL
    ) async throws
        -> StrengthLabGIFEditInfo
    {
        let data =
            try await loadData(
                from:
                    url
            )

        return try await Task.detached {
            try inspectData(
                data
            )
        }
        .value
    }


    static func export(
        sourceURL:
            URL,
        exerciseID:
            UUID,
        targetFPS:
            Int,
        maxWidth:
            Int?
    ) async throws
        -> URL
    {
        let data =
            try await loadData(
                from:
                    sourceURL
            )

        let destination =
            try editedGIFURL(
                exerciseID:
                    exerciseID
            )

        return try await Task.detached {
            try encode(
                data:
                    data,
                destination:
                    destination,
                targetFPS:
                    max(
                        3,
                        min(
                            30,
                            targetFPS
                        )
                    ),
                maxWidth:
                    maxWidth
            )

            return destination
        }
        .value
    }


    private static func loadData(
        from url: URL
    ) async throws
        -> Data
    {
        if url.isFileURL {
            return try Data(
                contentsOf:
                    url
            )
        }

        let (
            data,
            response
        ) =
            try await URLSession
                .shared
                .data(
                    from:
                        url
                )

        if
            let response =
                response
                    as?
                    HTTPURLResponse,
            !(200...299)
                .contains(
                    response.statusCode
                )
        {
            throw EditError
                .invalidGIF
        }

        return data
    }


    private static func inspectData(
        _ data: Data
    ) throws
        -> StrengthLabGIFEditInfo
    {
        guard
            let source =
                CGImageSourceCreateWithData(
                    data
                        as CFData,
                    nil
                )
        else {
            throw EditError
                .invalidGIF
        }

        let count =
            CGImageSourceGetCount(
                source
            )

        guard count > 0 else {
            throw EditError
                .invalidGIF
        }

        var duration =
            0.0

        for index in 0..<count {
            duration +=
                delay(
                    source:
                        source,
                    index:
                        index
                )
        }

        guard
            let image =
                CGImageSourceCreateImageAtIndex(
                    source,
                    0,
                    nil
                )
        else {
            throw EditError
                .invalidGIF
        }

        return
            StrengthLabGIFEditInfo(
                frameCount:
                    count,
                duration:
                    duration,
                averageFPS:
                    duration > 0
                    ? Double(count)
                        / duration
                    : 10,
                width:
                    image.width,
                height:
                    image.height
            )
    }


    private static func encode(
        data: Data,
        destination:
            URL,
        targetFPS:
            Int,
        maxWidth:
            Int?
    ) throws
    {
        guard
            let source =
                CGImageSourceCreateWithData(
                    data
                        as CFData,
                    nil
                )
        else {
            throw EditError
                .invalidGIF
        }

        let sourceCount =
            CGImageSourceGetCount(
                source
            )

        guard sourceCount > 0 else {
            throw EditError
                .invalidGIF
        }

        var frameEnds:
            [Double] = []

        frameEnds.reserveCapacity(
            sourceCount
        )

        var duration =
            0.0

        for index in
            0..<sourceCount
        {
            duration +=
                delay(
                    source:
                        source,
                    index:
                        index
                )

            frameEnds.append(
                duration
            )
        }

        guard duration > 0 else {
            throw EditError
                .invalidGIF
        }

        let frameDuration =
            1.0
            /
            Double(
                targetFPS
            )

        let outputCount =
            max(
                2,
                Int(
                    ceil(
                        duration
                        /
                        frameDuration
                    )
                )
            )

        try?
            FileManager
                .default
                .removeItem(
                    at:
                        destination
                )

        guard
            let output =
                CGImageDestinationCreateWithURL(
                    destination
                        as CFURL,
                    UTType
                        .gif
                        .identifier
                        as CFString,
                    outputCount,
                    nil
                )
        else {
            throw EditError
                .cannotCreateOutput
        }

        let gifProperties:
            [CFString: Any] =
        [
            kCGImagePropertyGIFLoopCount:
                0
        ]

        let fileProperties:
            [CFString: Any] =
        [
            kCGImagePropertyGIFDictionary:
                gifProperties
        ]

        CGImageDestinationSetProperties(
            output,
            fileProperties
                as CFDictionary
        )

        var sourceIndex =
            0

        for outputIndex in
            0..<outputCount
        {
            let time =
                min(
                    duration
                        - 0.000_001,
                    Double(
                        outputIndex
                    )
                    *
                    frameDuration
                )

            while
                sourceIndex
                    <
                    sourceCount - 1
                &&
                time
                    >=
                    frameEnds[
                        sourceIndex
                    ]
            {
                sourceIndex += 1
            }

            guard
                let original =
                    CGImageSourceCreateImageAtIndex(
                        source,
                        sourceIndex,
                        nil
                    )
            else {
                continue
            }

            let frame =
                resize(
                    original,
                    maxWidth:
                        maxWidth
                )

            let frameGIFProperties:
                [CFString: Any] =
            [
                kCGImagePropertyGIFDelayTime:
                    frameDuration,

                kCGImagePropertyGIFUnclampedDelayTime:
                    frameDuration
            ]

            let frameProperties:
                [CFString: Any] =
            [
                kCGImagePropertyGIFDictionary:
                    frameGIFProperties
            ]

            CGImageDestinationAddImage(
                output,
                frame,
                frameProperties
                    as CFDictionary
            )
        }

        guard
            CGImageDestinationFinalize(
                output
            )
        else {
            throw EditError
                .cannotEncode
        }
    }


    private static func delay(
        source:
            CGImageSource,
        index:
            Int
    ) -> Double
    {
        guard
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    index,
                    nil
                )
                as NSDictionary?,
            let gif =
                properties[
                    kCGImagePropertyGIFDictionary
                ]
                as?
                NSDictionary
        else {
            return 0.1
        }

        if
            let value =
                gif[
                    kCGImagePropertyGIFUnclampedDelayTime
                ]
                as?
                NSNumber
        {
            let delay =
                value.doubleValue

            if delay > 0.001 {
                return delay
            }
        }

        if
            let value =
                gif[
                    kCGImagePropertyGIFDelayTime
                ]
                as?
                NSNumber
        {
            let delay =
                value.doubleValue

            if delay > 0.001 {
                return delay
            }
        }

        return 0.1
    }


    private static func resize(
        _ image:
            CGImage,
        maxWidth:
            Int?
    ) -> CGImage
    {
        guard
            let maxWidth,
            maxWidth > 0,
            image.width
                > maxWidth
        else {
            return image
        }

        let scale =
            Double(maxWidth)
            /
            Double(
                image.width
            )

        let height =
            max(
                1,
                Int(
                    (
                        Double(
                            image.height
                        )
                        *
                        scale
                    )
                    .rounded()
                )
            )

        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        guard
            let context =
                CGContext(
                    data: nil,
                    width:
                        maxWidth,
                    height:
                        height,
                    bitsPerComponent:
                        8,
                    bytesPerRow:
                        0,
                    space:
                        colorSpace,
                    bitmapInfo:
                        CGImageAlphaInfo
                            .premultipliedLast
                            .rawValue
                )
        else {
            return image
        }

        context.interpolationQuality =
            .high

        context.draw(
            image,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width:
                        maxWidth,
                    height:
                        height
                )
        )

        return
            context.makeImage()
            ??
            image
    }


    private static func editedGIFURL(
        exerciseID:
            UUID
    ) throws
        -> URL
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
            throw EditError
                .cannotCreateOutput
        }

        let folder =
            base
                .appendingPathComponent(
                    "StrengthLab",
                    isDirectory:
                        true
                )
                .appendingPathComponent(
                    "EditedGIFs",
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

        return
            folder
                .appendingPathComponent(
                    "\(exerciseID.uuidString).gif"
                )
    }
}
