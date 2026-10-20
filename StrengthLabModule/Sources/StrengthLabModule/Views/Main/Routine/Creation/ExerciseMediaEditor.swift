import SwiftUI

struct ExerciseMediaEditor: View {
    @Environment(ExerciseManager.self) private var exerciseManager

    let exercise: SetDeckExercise

    @State private var videoText: String
    @State private var gifText: String

    init(exercise: SetDeckExercise) {
        self.exercise = exercise
        _videoText = State(initialValue: exercise.videoURL?.absoluteString ?? "")
        let possiblePublicGIF =
            exercise.gifSourceURL

        let publicGIFText: String

        if
            let possiblePublicGIF,
            let scheme =
                possiblePublicGIF
                    .scheme?
                    .lowercased(),
            ["http", "https"]
                .contains(
                    scheme
                ),
            possiblePublicGIF
                .host?
                .lowercased()
                != "file"
        {
            publicGIFText =
                possiblePublicGIF
                    .absoluteString
        } else {
            publicGIFText =
                ""
        }

        _gifText =
            State(
                initialValue:
                    publicGIFText
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Exercise Media", systemImage: "photo.on.rectangle.angled")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("YouTube / source video URL", text: $videoText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveVideoURL)
                .onChange(of: videoText) { _, newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedWebURL(newValue) != nil {
                        saveVideoURL()
                    }
                }

            TextField("Public GIF URL", text: $gifText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveGIFURL)
                .onChange(of: gifText) { _, newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedWebURL(newValue) != nil {
                        saveGIFURL()
                    }
                }

            if !gifText.isEmpty && parsedWebURL(gifText) == nil {
                Label("Enter a valid http(s) GIF URL", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("The source video stays available as a link; the GIF is the lightweight demo shown inside the workout.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            repairMalformedLocalGIFIfNeeded()
        }
        .onDisappear {
            saveVideoURL()
            saveGIFURL()
        }
    }

    private func saveVideoURL() {
        let trimmed = videoText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            exerciseManager.updateExercise(exercise) { $0.videoURL = nil }
        } else if let url = parsedWebURL(trimmed) {
            exerciseManager.updateExercise(exercise) { $0.videoURL = url }
        }
    }

    private func saveGIFURL() {
        repairMalformedLocalGIFIfNeeded()

        let trimmed =
            gifText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        if trimmed.isEmpty {

            /*
             A generated/local GIF is not a value for the
             "Public GIF URL" field.

             Leaving this field blank must NEVER delete
             locally generated exercise media.
            */
            if
                let current =
                    exercise.gifURL,
                current.isFileURL
            {
                return
            }

            /*
             Also preserve the generated GIF while an
             imported master video exists.
            */
            if
                exercise.importedVideoURL
                    != nil
            {
                return
            }

            exerciseManager.updateExercise(
                exercise
            ) {
                $0.gifURL = nil
                $0.gifSourceURL = nil
                $0.gifEditedFPS = nil
                $0.gifEditedMaxWidth = nil
                $0.gifTrimStart = nil
                $0.gifTrimEnd = nil
            }

            return
        }

        /*
         Never interpret file:///... as a web URL.
        */
        if
            trimmed
                .localizedCaseInsensitiveContains(
                    "file:///"
                )
        {
            repairMalformedLocalGIFIfNeeded()
            return
        }

        guard
            let url =
                parsedWebURL(
                    trimmed
                )
        else {
            return
        }

        let existingSource =
            exercise
                .gifSourceURL?
                .absoluteString

        if existingSource
            != url.absoluteString
        {
            exerciseManager.updateExercise(
                exercise
            ) {
                $0.gifSourceURL = url
                $0.gifURL = url
                $0.gifEditedFPS = nil
                $0.gifEditedMaxWidth = nil
                $0.gifTrimStart = nil
                $0.gifTrimEnd = nil
            }
        }
    }


    private func repairMalformedLocalGIFIfNeeded()
    {
        guard
            let current =
                exercise.gifURL,
            !current.isFileURL
        else {
            return
        }

        let value =
            current.absoluteString

        guard
            let range =
                value.range(
                    of:
                        "file:///",
                    options:
                        .caseInsensitive
                )
        else {
            return
        }

        let fileString =
            String(
                value[
                    range.lowerBound...
                ]
            )

        guard
            let repaired =
                URL(
                    string:
                        fileString
                ),
            repaired.isFileURL,
            FileManager.default
                .fileExists(
                    atPath:
                        repaired.path
                )
        else {
            return
        }

        exerciseManager.updateExercise(
            exercise
        ) {
            $0.gifURL =
                repaired

            /*
             A malformed https://file:/// value was never
             a genuine public GIF source.
            */
            if
                $0.gifSourceURL?
                    .absoluteString
                    .localizedCaseInsensitiveContains(
                        "file:///"
                    )
                ==
                true
            {
                $0.gifSourceURL =
                    nil
            }
        }

        gifText =
            ""
    }

    private func parsedWebURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard
            !trimmed
                .localizedCaseInsensitiveContains(
                    "file:///"
                )
        else {
            return nil
        }

        let candidate: String
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            candidate = trimmed
        } else {
            candidate = "https://\(trimmed)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }

        return url
    }
}
