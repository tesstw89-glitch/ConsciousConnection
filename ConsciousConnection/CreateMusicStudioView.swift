import SwiftUI
import AVFoundation

struct MusicChord: Codable, Hashable {
    let symbol: String
    let bars: Int
    let notes: [String]
}

struct MusicLab: Codable, Identifiable {
    let id: String
    let instrument: String
    let number: Int
    let category: String
    let title: String
    let subtitle: String
    let tonal: String
    let progression: String
    let groove: String
    let goal: String
    let palette: String
    let saxChords: String
    let backing: String
    let steps: [String]
    let bringHome: String
    let chords: [MusicChord]
}

private struct MusicLabFile: Codable {
    let schema: Int
    let source: String
    let labs: [MusicLab]
}

enum MusicLabLibrary {
    static let all: [MusicLab] = {
        guard let url = Bundle.main.url(forResource: "MusicLabCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MusicLabFile.self, from: data) else {
            return []
        }
        return file.labs
    }()
}

private let studioMint = Color(red: 0.61, green: 0.92, blue: 0.80)
private let studioInk = Color(red: 0.07, green: 0.10, blue: 0.14)

struct CreateMusicHomeView: View {
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("CREATE / RYE DAZE")
                    .font(.caption.bold()).tracking(2).foregroundStyle(studioMint)
                Text("Make music.")
                    .font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Pick something you actually want to practise. Your instrument, your songs, your musical ideas.")
                    .foregroundStyle(.white.opacity(0.72)).padding(.bottom, 6)
                StudioLink(title: "Practice an instrument",
                           subtitle: "23 saxophone labs · 19 Minilogue chord labs",
                           icon: "music.mic", destination: MusicInstrumentPickerView())
                StudioLink(title: "Quick Create",
                           subtitle: "Make a musical idea, not a perfect loop",
                           icon: "waveform.path", destination: QuickCreateIdeasView())
                StudioLink(title: "Song arrangement laboratory",
                           subtitle: "Entrances, exits, textures and transitions",
                           icon: "square.stack.3d.up", destination: MusicArrangementLabsView())
                StudioLink(title: "Work on an existing song",
                           subtitle: "Continue a song plan you've already started",
                           icon: "slider.horizontal.3", destination: CreateSongLabView())
                StudioLink(title: "Practise an existing song",
                           subtitle: "A deliberate performance rehearsal",
                           icon: "metronome", destination: PractiseExistingSongView())
                Text("Music first. The studio backings are production briefs; no audio is bundled in this version.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.59)).padding(.top, 10)
            }
            .padding(.horizontal, 22).padding(.top, 28).padding(.bottom, 42)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StudioBackground<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            LinearGradient(colors: [studioInk, Color(red: 0.14, green: 0.19, blue: 0.23), studioInk],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView { content }
        }
    }
}

private struct StudioLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.title2).foregroundStyle(studioMint).frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.64))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
            }
            .padding(17).background(.white.opacity(0.085), in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }
}

struct MusicInstrumentPickerView: View {
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("PRACTICE AN INSTRUMENT")
                    .font(.caption.bold()).tracking(1.6).foregroundStyle(studioMint)
                Text("Choose your studio").font(.largeTitle.bold()).foregroundStyle(.white)
                StudioLink(title: "Saxophone Studio",
                           subtitle: "23 saxophone exercises · written E♭ alto notes",
                           icon: "music.note", destination: MusicLabListView(instrument: "sax"))
                StudioLink(title: "Keys Studio",
                           subtitle: "19 harmony labs · coloured Minilogue chord diagrams",
                           icon: "pianokeys", destination: MusicLabListView(instrument: "keys"))
                // ROLI_BASS_STUDIO_LINK_V1
                StudioLink(title: "Bass Studio · ROLI Block",
                           subtitle: "1 song · notes translated from bass tab",
                           icon: "music.note.list", destination: BassStudioLibraryView())
            }.padding(22)
        }
        .navigationTitle("Practice an instrument")
    }
}

struct MusicLabListView: View {
    let instrument: String
    @AppStorage("KeysStudioBoardMode") private var boardMode = "Piano"
    @State private var search = ""
    private var labs: [MusicLab] {
        MusicLabLibrary.all.filter {
            $0.instrument == instrument &&
            (search.isEmpty || $0.title.localizedStandardContains(search)
             || $0.tonal.localizedStandardContains(search)
             || $0.category.localizedStandardContains(search))
        }
    }
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 14) {
                Text(instrument == "keys" ? "KEYS / MINILOGUE MIDI" : "SAXOPHONE / E♭ ALTO")
                    .font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text(instrument == "keys" ? "Harmony to play." : "Improvise with the band.")
                    .font(.title.bold()).foregroundStyle(.white)
                Text(instrument == "keys" ?
                     "Concert-pitch chords. Drum and bass accompaniment only." :
                     "Backing chords are concert pitch. Your sax notes are written for E♭ alto.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                if instrument == "keys" {
                    KeysBoardModePicker(selection: $boardMode)
                }
                TextField("Find a sound, key or lesson", text: $search)
                    .textInputAutocapitalization(.never)
                    .padding(13).background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                ForEach(labs) { lab in
                    NavigationLink(destination: MusicLabDetailView(lab: lab)) {
                        HStack(alignment: .top, spacing: 14) {
                            Text(String(format: "%02d", lab.number))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(studioMint).frame(width: 39)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(lab.title).font(.headline).foregroundStyle(.white)
                                Text(lab.category.capitalized).font(.caption2.bold()).foregroundStyle(studioMint)
                                Text(lab.tonal).font(.caption).foregroundStyle(.white.opacity(0.68))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(15).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                    }.buttonStyle(.plain)
                }
                if labs.isEmpty { Text("No matching lessons.").foregroundStyle(.white.opacity(0.7)) }
            }.padding(20).padding(.bottom, 30)
        }
        .navigationTitle(instrument == "keys" ? "Keys Studio" : "Saxophone Studio")
    }
}

struct MusicLabDetailView: View {
    let lab: MusicLab
    @AppStorage("KeysStudioBoardMode") private var boardMode = "Piano"
    @State private var chordIndex = 0
    @State private var rootless = false
    @State private var notes = ""
    @State private var lastPractised: Date?
    private var currentChord: MusicChord? {
        guard !lab.chords.isEmpty else { return nil }
        return lab.chords[min(chordIndex, lab.chords.count - 1)]
    }
    private var practiceDateKey: String { "MusicStudio.Practised." + lab.id }
    private var notesKey: String { "MusicStudio.Notes." + lab.id }
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(lab.instrument == "keys" ? "KEYS" : "SAX") · LAB \(String(format: "%02d", lab.number))")
                    .font(.caption.bold()).tracking(1.6).foregroundStyle(studioMint)
                Text(lab.title).font(.largeTitle.bold()).foregroundStyle(.white)
                Text(lab.category.capitalized + " · " + lab.tonal)
                    .font(.subheadline).foregroundStyle(studioMint)
                Text(lab.goal).font(.body).foregroundStyle(.white.opacity(0.86))
                infoBlock("THE MUSICAL WORLD", lab.groove + "\n" + lab.progression)
                if lab.instrument == "keys" {
                    if let chord = currentChord { chordPanel(chord) }
                    infoBlock("HARMONIC INGREDIENTS", lab.palette)
                } else {
                    NavigationLink(destination: SaxStudioPlayView(lab: lab)) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title3.bold())
                                .frame(width: 42, height: 42)
                                .background(
                                    Color(red: 0.61, green: 0.92, blue: 0.80),
                                    in: Circle()
                                )
                                .foregroundStyle(Color.black)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(lab.id == "sax-23" ? "PLAY PASSING-TONE EXERCISE" : "PLAY SAX FINGERINGS")
                                    .font(.headline)
                                Text("Drum groove · timed written-note diagrams")
                                    .font(.caption)
                                    .opacity(0.78)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            .white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)
                    infoBlock("ALTO WRITTEN", lab.saxChords + "\n" + lab.palette)
                }
                infoBlock(lab.instrument == "keys" ? "DRUMS + BASS ARRANGEMENT" : "FULL-BAND ARRANGEMENT",
                          lab.backing)
                Text("YOUR PRACTICE").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                ForEach(Array(lab.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.caption.bold()).foregroundStyle(studioMint).frame(width: 26)
                        Text(step).font(.subheadline).foregroundStyle(.white.opacity(0.91))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                }
                infoBlock("BRING HOME", lab.bringHome)
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRACTICE NOTES").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                    TextField("Something you discovered or want to revisit", text: $notes, axis: .vertical)
                        .lineLimit(3...6).padding(12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .onChange(of: notes) { _, value in
                            UserDefaults.standard.set(value, forKey: notesKey)
                        }
                    Button {
                        let now = Date()
                        UserDefaults.standard.set(now, forKey: practiceDateKey)
                        lastPractised = now
                    } label: {
                        Label(lastPractised == nil ? "Mark practised" :
                                "Practised · \(lastPractised!.formatted(date: .abbreviated, time: .omitted))",
                              systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity).padding(15)
                            .background(studioMint, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(studioInk)
                    }.buttonStyle(.plain)
                }
            }.padding(20).padding(.bottom, 35)
        }
        .navigationTitle("Lab \(lab.number)").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = UserDefaults.standard.string(forKey: notesKey) ?? ""
            lastPractised = UserDefaults.standard.object(forKey: practiceDateKey) as? Date
        }
    }
    private func infoBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).tracking(1.4).foregroundStyle(studioMint)
            Text(body).font(.subheadline).foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
    }
    private func chordPanel(_ chord: MusicChord) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(boardMode == "Exquis" ? "EXQUIS · CHORD SHAPE" : "MINILOGUE · CHORD SHAPE")
                        .font(.caption2.bold()).tracking(1.1).foregroundStyle(studioMint)
                    Text(chord.symbol).font(.title2.bold()).foregroundStyle(.white)
                    if chord.bars > 0 {
                        Text("\(chord.bars) bars").font(.caption).foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
                NavigationLink(destination: KeysStudioPlayView(lab: lab)) {
                    Label("Play", systemImage: "play.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(studioMint, in: Capsule())
                        .foregroundStyle(studioInk)
                }
                .buttonStyle(.plain)
                Button {
                    chordIndex = (chordIndex + lab.chords.count - 1) % lab.chords.count
                } label: { Image(systemName: "chevron.left").padding(10) }
                    .accessibilityLabel("Previous chord")
                Button {
                    chordIndex = (chordIndex + 1) % lab.chords.count
                } label: { Image(systemName: "chevron.right").padding(10) }
                    .accessibilityLabel("Next chord")
            }.foregroundStyle(studioMint)
            KeysBoardModePicker(selection: $boardMode)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(lab.chords.indices, id: \.self) { index in
                        Button {
                            chordIndex = index
                        } label: {
                            Text(lab.chords[index].symbol).font(.caption.bold())
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(index == chordIndex ? studioMint : Color.white.opacity(0.1),
                                            in: Capsule())
                                .foregroundStyle(index == chordIndex ? studioInk : Color.white)
                        }.buttonStyle(.plain)
                    }
                }
            }
            Group {
                if boardMode == "Exquis" {
                    ExquisChordBoard(labID: lab.id,
                                     chordIndex: chordIndex,
                                     chord: chord,
                                     omitRoot: rootless)
                        .frame(height: 220)
                } else {
                    CuratedMinilogueKeyboard(labID: lab.id, chordIndex: chordIndex,
                                          chord: chord, omitRoot: rootless)
                }
            }
            Toggle("Leave a played root to the bass", isOn: $rootless)
                .toggleStyle(.switch)
                .tint(studioMint)
            let leftHand = CuratedKeyboardShape.notes(labID: lab.id, index: chordIndex,
                                                     chord: chord, omitRoot: rootless)
                .filter { $0.hand == "left" }.map(\.label).joined(separator: " · ")
            let rightHand = CuratedKeyboardShape.notes(labID: lab.id, index: chordIndex,
                                                      chord: chord, omitRoot: rootless)
                .filter { $0.hand == "right" }.map(\.label).joined(separator: " · ")
            VStack(alignment: .leading, spacing: 5) {
                Text("LEFT: " + (leftHand.isEmpty ? "Rest — let the bass lead" : leftHand))
                    .foregroundStyle(CuratedMinilogueKeyboard.leftColour)
                Text("RIGHT: " + (rightHand.isEmpty ? "Rest" : rightHand))
                    .foregroundStyle(CuratedMinilogueKeyboard.rightColour)
            }
            .font(.caption.monospaced())
            Text("Blue = left hand; pink = right hand. The yellow dot identifies the root, even when the bass plays it and that key isn't coloured. These are deliberately reviewed voicings for this lab, not an automatic split. The slash bass note belongs to the backing track.")
                .font(.caption2).foregroundStyle(.white.opacity(0.62))
        }.padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickCreateIdeasView: View {
    @State private var idea = 0
    private let ideas: [(String, String)] = [
        ("Rhythm first", "Make an eight-bar drum groove. Add bass only when the beat has its own personality. Finish with a simple chord or melody."),
        ("Harmony first", "Find a chord colour that moves you. Add bass and a contrasting drum rhythm. Save one complete musical idea."),
        ("Texture first", "Make a strange rhythmic texture with XO samples. Add a harmonic layer, then let the texture support a short groove."),
        ("Bass first", "Play a bass figure on any controller. Make your drums answer it. Add one melodic or chordal idea."),
        ("Unexpected turn", "Build a short groove. Change just one part halfway through so it briefly becomes another musical world.")
    ]
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 18) {
                Text("QUICK CREATE").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text("Make something small.").font(.largeTitle.bold()).foregroundStyle(.white)
                Text(ideas[idea].0).font(.title2.bold()).foregroundStyle(studioMint)
                Text(ideas[idea].1).foregroundStyle(.white.opacity(0.85)).padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 15))
                Button { idea = (idea + 1) % ideas.count } label: {
                    Label("Another challenge", systemImage: "shuffle")
                        .padding(13).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(studioMint)
                Text("You choose all the actual notes, sounds, instruments and tempo.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.6))
            }.padding(22)
        }
        .navigationTitle("Quick Create")
    }
}

struct PractiseExistingSongView: View {
    @AppStorage("MusicPracticeSong.title.v1") private var title = ""
    @AppStorage("MusicPracticeSong.focus.v1") private var focus = ""
    @AppStorage("MusicPracticeSong.notes.v1") private var notes = ""
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 15) {
                Text("PRACTISE AN EXISTING SONG")
                    .font(.caption.bold()).tracking(1.4).foregroundStyle(studioMint)
                Text("Get it under your fingers.").font(.title.bold()).foregroundStyle(.white)
                Text("Choose one passage of a song you're learning or performing. Make one useful improvement rather than trying to perfect everything at once.")
                    .foregroundStyle(.white.opacity(0.8))
                input("SONG", text: $title, prompt: "What are you playing?")
                input("TODAY'S FOCUS", text: $focus, prompt: "A transition, solo, chord section, or full run-through")
                input("NEXT TIME", text: $notes, prompt: "What should you revisit?")
            }.padding(22)
        }
        .navigationTitle("Practise a song")
    }
    private func input(_ heading: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(heading).font(.caption.bold()).foregroundStyle(studioMint)
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(2...4).padding(12)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - ROLI bass song studio
// ROLI_BASS_STAND_BY_ME_V1
// Concert / sounding pitches in MIDI octave convention (C4 = MIDI 60).
// This is an EXACT pitch/fret-order conversion of the user-supplied eight-bar
// tab. ASCII spacing is NOT a reliable rhythm transcription; steps are manual.

enum BassTabString: String {
    case lowE = "E", a = "A", d = "D", g = "G"

    var openMIDI: Int {
        switch self {
        case .lowE: return 28  // E1
        case .a: return 33     // A1
        case .d: return 38     // D2
        case .g: return 43     // G2
        }
    }
}

struct BassTabNote: Equatable {
    let string: BassTabString
    let fret: Int

    init(_ string: BassTabString, _ fret: Int) {
        self.string = string
        self.fret = fret
    }

    var midi: Int { string.openMIDI + fret }
    var label: String { Self.name(midi) }

    static func name(_ midi: Int) -> String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "G♯", "A", "B♭", "B"]
        return names[midi % 12] + String(midi / 12 - 1)
    }
}

struct BassSongBar: Identifiable {
    let number: Int
    let harmony: String
    let notes: [BassTabNote]
    var id: Int { number }
}

enum BassSongLibrary {
    // Original tab: standard tuning E1–A1–D2–G2, eight bars, repeat.
    // A | A | F♯m | F♯m | D | E | A | A
    static let standByMe: [BassSongBar] = [
        .init(number: 1, harmony: "A", notes: [.init(.d, 7), .init(.d, 7), .init(.a, 7), .init(.d, 6)]),
        .init(number: 2, harmony: "A", notes: [.init(.d, 7), .init(.d, 7), .init(.d, 7), .init(.d, 6)]),
        .init(number: 3, harmony: "F♯m", notes: [.init(.d, 4), .init(.d, 4), .init(.a, 7)]),
        .init(number: 4, harmony: "F♯m", notes: [.init(.d, 4), .init(.d, 4), .init(.d, 4), .init(.a, 7)]),
        .init(number: 5, harmony: "D", notes: [.init(.a, 5), .init(.a, 5), .init(.a, 5), .init(.d, 4)]),
        .init(number: 6, harmony: "E", notes: [.init(.a, 7), .init(.a, 7), .init(.a, 7), .init(.d, 6)]),
        .init(number: 7, harmony: "A", notes: [.init(.d, 7), .init(.d, 7), .init(.a, 7), .init(.d, 6)]),
        .init(number: 8, harmony: "A", notes: [.init(.d, 7), .init(.d, 7), .init(.a, 7), .init(.d, 6)])
    ]
}

@MainActor
private final class BassStudioAudio: ObservableObject {
    @Published private(set) var groovePlaying = false
    @Published var error: String?

    private let engine = AVAudioEngine()
    private let drums = AVAudioPlayerNode()
    private let bassPreview = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

    init() {
        engine.attach(drums)
        engine.attach(bassPreview)
        engine.connect(drums, to: engine.mainMixerNode, format: format)
        engine.connect(bassPreview, to: engine.mainMixerNode, format: format)
        drums.volume = 0.78
        bassPreview.volume = 0.66
    }

    private func ready() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try engine.start() }
    }

    func toggleGroove(bpm: Int) {
        if groovePlaying {
            stopGroove()
            return
        }
        error = nil
        guard let url = Bundle.main.url(forResource: "KeysGroove_4_4_\(bpm)", withExtension: "wav") else {
            error = "The \(bpm) BPM drum groove is missing."
            return
        }
        do {
            try ready()
            let file = try AVAudioFile(forReading: url)
            guard file.length <= Int64(UInt32.max),
                  file.processingFormat.channelCount == 2,
                  abs(file.processingFormat.sampleRate - 44_100) < 0.1 else {
                error = "The drum loop is not stereo 44.1 kHz."
                return
            }
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                          frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: buffer)
            drums.stop()
            drums.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            drums.play()
            groovePlaying = true
        } catch {
            stopGroove()
            self.error = "Could not play the groove: \(error.localizedDescription)"
        }
    }

    func preview(midi: Int) {
        error = nil
        do {
            try ready()
            let sampleRate = 44_100.0
            let frames = Int(sampleRate * 0.62)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
            buffer.frameLength = AVAudioFrameCount(frames)
            guard let channels = buffer.floatChannelData else { return }
            let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            for i in 0..<frames {
                let t = Double(i) / sampleRate
                let attack = min(1.0, t / 0.012)
                let release = min(1.0, (0.62 - t) / 0.11)
                let envelope = attack * max(0.0, release) * exp(-2.5 * t)
                let wave = sin(2.0 * .pi * frequency * t)
                    + 0.28 * sin(4.0 * .pi * frequency * t)
                    + 0.10 * sin(6.0 * .pi * frequency * t)
                let sample = Float(0.26 * envelope * wave)
                channels[0][i] = sample
                channels[1][i] = sample
            }
            bassPreview.stop()
            bassPreview.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            bassPreview.play()
        } catch {
            self.error = "Could not preview note: \(error.localizedDescription)"
        }
    }

    func stopGroove() {
        drums.stop()
        groovePlaying = false
    }

    func stopAll() {
        stopGroove()
        bassPreview.stop()
        engine.stop()
    }
}

struct BassStudioLibraryView: View {
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 15) {
                Text("RYE DAZE / ROLI BLOCK")
                    .font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text("Bass Studio").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Learn real bass parts, one song and one phrase at a time. Concert-pitch MIDI notes for your ROLI.")
                    .foregroundStyle(.white.opacity(0.76))
                NavigationLink(destination: BassStandByMeView()) {
                    HStack(spacing: 14) {
                        Text("01").font(.title2.bold()).foregroundStyle(studioMint)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Stand by Me").font(.headline).foregroundStyle(.white)
                            Text("Ben E. King · beginner · A major · 8-bar loop")
                                .font(.caption).foregroundStyle(.white.opacity(0.68))
                            Text("31 notes · converted from your bass tab")
                                .font(.caption2).foregroundStyle(studioMint)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(17)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                Text("First song added. More can join this library without changing your sax or keys studios.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.6))
            }
            .padding(20).padding(.bottom, 32)
        }
        .navigationTitle("Bass Studio")
    }
}

struct BassStandByMeView: View {
    @StateObject private var audio = BassStudioAudio()
    @AppStorage("BassStudio.StandByMe.bar.v1") private var barIndex = 0
    @AppStorage("BassStudio.StandByMe.note.v1") private var noteIndex = 0
    @AppStorage("BassStudio.StandByMe.tempo.v1") private var tempo = 90
    @AppStorage("BassStudio.StandByMe.runs.v1") private var completedRuns = 0
    @AppStorage("BassStudio.StandByMe.notes.v1") private var journal = ""

    private let tempos = [70, 80, 90, 100, 110, 120, 130, 140]
    private var bars: [BassSongBar] { BassSongLibrary.standByMe }
    private var safeBarIndex: Int { max(0, min(barIndex, bars.count - 1)) }
    private var currentBar: BassSongBar { bars[safeBarIndex] }
    private var safeNoteIndex: Int { max(0, min(noteIndex, currentBar.notes.count - 1)) }
    private var currentNote: BassTabNote { currentBar.notes[safeNoteIndex] }

    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 17) {
                Text("BASS STUDIO / SONG 01")
                    .font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text("Stand by Me").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Ben E. King · A major · 4/4 · standard bass tuning")
                    .font(.subheadline).foregroundStyle(studioMint)

                Text("Your eight-bar tab, converted to sounding pitches. Follow the note order on your ROLI Block. It loops back to bar 1 after bar 8.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.82))

                VStack(alignment: .leading, spacing: 10) {
                    Text("CHOOSE A BAR")
                        .font(.caption.bold()).tracking(1.4).foregroundStyle(studioMint)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(bars.indices, id: \.self) { index in
                                let bar = bars[index]
                                Button {
                                    barIndex = index
                                    noteIndex = 0
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(String(format: "%02d", bar.number)).font(.headline.bold())
                                        Text(bar.harmony).font(.caption2)
                                    }
                                    .frame(width: 52, height: 52)
                                    .foregroundStyle(safeBarIndex == index ? studioInk : .white)
                                    .background(safeBarIndex == index ? studioMint : Color.white.opacity(0.11),
                                                in: RoundedRectangle(cornerRadius: 11))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Bar \(bar.number), \(bar.harmony)")
                            }
                        }
                    }
                    Text("Bar \(currentBar.number) of 8 · \(currentBar.harmony) chord · note \(safeNoteIndex + 1) of \(currentBar.notes.count)")
                        .font(.caption).foregroundStyle(.white.opacity(0.70))
                }
                .padding(15)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 11) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(currentNote.label)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(studioMint)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("MIDI \(currentNote.midi)").font(.title3.bold())
                            Text("\(currentNote.string.rawValue) string · fret \(currentNote.fret)")
                                .font(.caption).foregroundStyle(.white.opacity(0.7))
                        }
                        .foregroundStyle(.white)
                    }
                    HStack(spacing: 6) {
                        ForEach([38, 40, 42, 44, 45], id: \.self) { pitch in
                            Text(BassTabNote.name(pitch))
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundStyle(currentNote.midi == pitch ? studioInk : .white)
                                .background(currentNote.midi == pitch ? studioMint : Color.white.opacity(0.09),
                                            in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                    Text("The highlighted pitch is your next ROLI note. Set your DAW/controller octave so the displayed MIDI number matches.")
                        .font(.caption2).foregroundStyle(.white.opacity(0.68))
                    HStack(spacing: 10) {
                        Button { step(by: -1) } label: {
                            Label("Previous", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity).padding(12)
                        }
                        Button { audio.preview(midi: currentNote.midi) } label: {
                            Label("Hear note", systemImage: "speaker.wave.2")
                                .frame(maxWidth: .infinity).padding(12)
                        }
                        Button { step(by: 1) } label: {
                            Label("Next", systemImage: "chevron.right")
                                .frame(maxWidth: .infinity).padding(12)
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(studioInk)
                    .background(studioMint, in: RoundedRectangle(cornerRadius: 12))
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("BAR \(currentBar.number) · NOTE ORDER")
                        .font(.caption.bold()).tracking(1.3).foregroundStyle(studioMint)
                    HStack(spacing: 6) {
                        ForEach(currentBar.notes.indices, id: \.self) { index in
                            let note = currentBar.notes[index]
                            Button {
                                noteIndex = index
                                audio.preview(midi: note.midi)
                            } label: {
                                VStack(spacing: 5) {
                                    Text(note.label).font(.subheadline.bold())
                                    Text(String(index + 1)).font(.caption2)
                                        .opacity(0.70)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .foregroundStyle(safeNoteIndex == index ? studioInk : .white)
                                .background(safeNoteIndex == index ? studioMint : Color.white.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Note \(index + 1), \(note.label), MIDI \(note.midi)")
                        }
                    }
                }
                .padding(15)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("PLAY ALONG · DRUMS ONLY")
                        .font(.caption.bold()).tracking(1.3).foregroundStyle(studioMint)
                    HStack {
                        Text("Tempo").foregroundStyle(.white)
                        Spacer()
                        Picker("Tempo", selection: $tempo) {
                            ForEach(tempos, id: \.self) { value in
                                Text("\(value) BPM").tag(value)
                            }
                        }
                        .tint(studioMint)
                        .pickerStyle(.menu)
                    }
                    Button { audio.toggleGroove(bpm: tempo) } label: {
                        Label(audio.groovePlaying ? "Stop drum groove" : "Play drum groove",
                              systemImage: audio.groovePlaying ? "stop.fill" : "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding(14)
                            .background(studioMint, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(studioInk)
                    }
                    .buttonStyle(.plain)
                    Text("The tab gives pitches and their order, not verified beat positions or note lengths. The drum loop is independent; advance the notes yourself and learn the timing by listening to the song.")
                        .font(.caption).foregroundStyle(.white.opacity(0.72))
                    if let error = audio.error {
                        Text(error).font(.caption).foregroundStyle(.orange)
                    }
                }
                .padding(15)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("PRACTICE LOG")
                        .font(.caption.bold()).tracking(1.3).foregroundStyle(studioMint)
                    TextField("What felt good? What needs another run?", text: $journal, axis: .vertical)
                        .lineLimit(2...4).padding(12)
                        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                    Button {
                        completedRuns += 1
                        barIndex = 0
                        noteIndex = 0
                    } label: {
                        Label("Completed an 8-bar run · \(completedRuns)",
                              systemImage: "checkmark.circle")
                            .font(.subheadline.bold()).frame(maxWidth: .infinity)
                            .padding(13)
                            .foregroundStyle(studioMint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(15)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20).padding(.bottom, 35)
        }
        .navigationTitle("Stand by Me")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tempo) { _, _ in audio.stopGroove() }
        .onDisappear { audio.stopAll() }
    }

    private func step(by offset: Int) {
        let next = safeNoteIndex + offset
        if next >= currentBar.notes.count {
            barIndex = (safeBarIndex + 1) % bars.count
            noteIndex = 0
        } else if next < 0 {
            barIndex = (safeBarIndex + bars.count - 1) % bars.count
            noteIndex = bars[barIndex].notes.count - 1
        } else {
            noteIndex = next
        }
    }
}
// ROLI_BASS_STAND_BY_ME_END_V1
