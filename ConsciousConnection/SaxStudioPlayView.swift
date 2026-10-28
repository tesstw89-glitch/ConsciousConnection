import SwiftUI
import AVFoundation
import UIKit

// Sax fingerings are WRITTEN alto-sax pitches: MIDI 58 = low B-flat3;
// MIDI 90 = high F-sharp6. Concert-pitch accompaniment is separate.
private struct SaxPracticeNote {
    let midi: Int
    let writtenName: String
}

private enum SaxFingeringSequence: String, CaseIterable, Identifiable {
    case lesson = "Lesson phrase"
    case chromatic = "All fingerings"
    case passing = "Passing tones"
    var id: String { rawValue }
}

// EXQUIS-independent SAX_PASSING_KEYS_V1: these are CONCERT key choices.
// Every displayed and played fingering is a WRITTEN E-flat alto note.
private enum SaxPassingKey: String, CaseIterable, Identifiable {
    case bMinor = "B minor"
    case dMajor = "D major"
    case fSharpMinor = "F♯ minor"
    case aMajor = "A major"
    case aMinor = "A minor"
    case cMajor = "C major"
    case bFlatMinor = "B♭ minor"
    case dFlatMajor = "D♭ major"
    case eMinor = "E minor"
    case gMajor = "G major"

    var id: String { rawValue }

    var writtenKey: String {
        switch self {
        case .bMinor: return "G♯ minor"
        case .dMajor: return "B major"
        case .fSharpMinor: return "D♯ minor"
        case .aMajor: return "F♯ major"
        case .aMinor: return "F♯ minor"
        case .cMajor: return "A major"
        case .bFlatMinor: return "G minor"
        case .dFlatMajor: return "B♭ major"
        case .eMinor: return "C♯ minor"
        case .gMajor: return "E major"
        }
    }

    // Correct diatonic spellings (including E♯ where appropriate).
    // Minor keys use natural minor; major keys use the major scale.
    var writtenScale: [String] {
        switch self {
        case .bMinor: return ["G♯", "A♯", "B", "C♯", "D♯", "E", "F♯"]
        case .dMajor: return ["B", "C♯", "D♯", "E", "F♯", "G♯", "A♯"]
        case .fSharpMinor: return ["D♯", "E♯", "F♯", "G♯", "A♯", "B", "C♯"]
        case .aMajor: return ["F♯", "G♯", "A♯", "B", "C♯", "D♯", "E♯"]
        case .aMinor: return ["F♯", "G♯", "A", "B", "C♯", "D", "E"]
        case .cMajor: return ["A", "B", "C♯", "D", "E", "F♯", "G♯"]
        case .bFlatMinor: return ["G", "A", "B♭", "C", "D", "E♭", "F"]
        case .dFlatMajor: return ["B♭", "C", "D", "E♭", "F", "G", "A"]
        case .eMinor: return ["C♯", "D♯", "E", "F♯", "G♯", "A", "B"]
        case .gMajor: return ["E", "F♯", "G♯", "A", "B", "C♯", "D♯"]
        }
    }
}

private enum SaxFingeringRate: Int, CaseIterable, Identifiable {
    case bar = 1, half = 2, quarter = 4, eighth = 8
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .bar: return "1 bar"
        case .half: return "½ bar"
        case .quarter: return "¼ bar"
        case .eighth: return "⅛ bar"
        }
    }
}

private enum SaxGrooveMeter: String {
    case four = "4_4", five = "5_4", six = "6_8"
    init(_ lab: MusicLab) {
        if lab.groove.contains("5/4") { self = .five }
        else if lab.groove.contains("6/8") { self = .six }
        else { self = .four }
    }
    var pulses: Int {
        switch self {
        case .four: return 4
        case .five: return 5
        case .six: return 2 // dotted-quarter pulses
        }
    }
    var label: String {
        switch self {
        case .four: return "4/4"
        case .five: return "5/4"
        case .six: return "6/8"
        }
    }
}

// Introductory finger drills based on each lesson's stated written-note
// examples. These are prompts for improvisation, NOT prescribed solos.
private enum SaxFingeringDrills {
    private static let patterns: [String: String] = [
        "sax-01": "G♯4 B4 D♯5 G♯5 F♯5 D♯5 C♯5 B4",
        "sax-02": "B♭3 B3 C4 D♭4 D4 E♭4 E4 F4 F♯4 G4 A♭4 A4 B♭4",
        "sax-03": "B♭4 D5 F5 A5 F5 D5 C5 A4",
        "sax-04": "F♯4 A4 C♯5 F♯5 C♯5 A4 F♯4 A4",
        "sax-05": "C♯4 E4 F♯4 G♯4 F♯4 E4 C♯4 G♯4 A4 C♯5",
        "sax-06": "B♭4 D5 F5 D5 G4 B♭4 D5 B♭4",
        "sax-07": "B4 F♯5 B5 A♯5 F♯5 E5 D♯5 B4",
        "sax-08": "G4 B♭4 C5 D5 F5 D5 C5 B♭4",
        "sax-09": "E4 F♯4 G♯4 B4 C♯5 B4 G♯4 F♯4",
        "sax-10": "G♯4 B4 D♯5 E5 E♯5 F♯5 E♯5 E5",
        "sax-11": "B4 D♯5 E♯5 F♯5 A♯5 G♯5 E♯5 D♯5",
        "sax-12": "C♯5 D5 E5 C♯5 B4 A4 G♯4 F♯4",
        "sax-13": "F♯4 G♯4 A4 A♯4 D♯4 F♯4 A♯4 C♯5",
        "sax-14": "E4 G4 G♯4 B4 D5 B4 G♯4 E4",
        "sax-15": "A4 C♯5 E5 G♯5 F♯5 E5 C♯5 A4",
        "sax-16": "B4 B4 A♯4 F♯4 E♯4 E♯4 F♯4 A♯4",
        "sax-17": "G♯4 B4 D5 F♯5 C♯5 E♯5 F♯5 A4",
        "sax-18": "B4 D♯5 F♯5 B4 D5 G5 B4 D♯5",
        "sax-19": "G♯4 G♯4 F♯4 E♯4 F♯4 A♯4 B4 F♯4",
        "sax-20": "G♯4 B4 D♯5 F♯5 A4 C5 E5 G5 G♯4 B4 D♯5",
        "sax-21": "C♯4 E4 G♯4 C♯5 E5 G♯4 C♯5 E5",
        "sax-22": "D♯4 F♯4 A♯4 C♯5 B4 D♯5 F♯5 G♯4 B4 D♯5 A♯4 C♯5"
    ]

    private static let bases: [String: Int] = [
        "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
    ]

    static func parse(_ written: String) -> SaxPracticeNote? {
        let token = written.replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
        guard token.count >= 2,
              let first = token.first,
              let base = bases[String(first)],
              let octaveChar = token.last,
              let octave = octaveChar.wholeNumberValue else { return nil }
        let suffix = String(token.dropFirst().dropLast())
        let accidental: Int
        switch suffix {
        case "#": accidental = 1
        case "b": accidental = -1
        case "": accidental = 0
        default: return nil
        }
        let midi = (octave + 1) * 12 + base + accidental
        guard (58...90).contains(midi) else { return nil }
        return SaxPracticeNote(midi: midi, writtenName: written)
    }

    static func lesson(_ lab: MusicLab) -> [SaxPracticeNote] {
        (patterns[lab.id] ?? "").split(separator: " ").compactMap { parse(String($0)) }
    }

    // SAX_DIATONIC_PASSING_V1: overlapping groups of three scale notes.
    // Descend in key from the highest available written sax note and then
    // ascend from the lowest. Each note is shown by the existing fingering
    // diagrams; adjacent groups overlap by two scale degrees.
    static func passingTones(_ concertKey: SaxPassingKey) -> [SaxPracticeNote] {
        var namesByPitchClass: [Int: String] = [:]
        for name in concertKey.writtenScale {
            if let note = parse(name + "4") {
                namesByPitchClass[note.midi % 12] = name
            }
        }
        let scale: [SaxPracticeNote] = (58...90).compactMap { midi in
            guard let name = namesByPitchClass[midi % 12] else { return nil }
            return SaxPracticeNote(
                midi: midi,
                writtenName: name + String(midi / 12 - 1)
            )
        }
        guard scale.count >= 3 else { return [] }
        var result: [SaxPracticeNote] = []
        for i in stride(from: scale.count - 1, through: 2, by: -1) {
            result.append(contentsOf: [scale[i], scale[i - 1], scale[i - 2]])
        }
        for i in 0...(scale.count - 3) {
            result.append(contentsOf: [scale[i], scale[i + 1], scale[i + 2]])
        }
        return result
    }

    static let chromatic: [SaxPracticeNote] = {
        let names = ["C", "C♯", "D", "E♭", "E", "F",
                     "F♯", "G", "A♭", "A", "B♭", "B"]
        return (58...90).map { midi in
            SaxPracticeNote(
                midi: midi,
                writtenName: names[midi % 12] + String(midi / 12 - 1)
            )
        }
    }()
}

@MainActor
private final class SaxDrumPlayer: ObservableObject {
    @Published private(set) var playing = false
    @Published var error: String?
    private let engine = AVAudioEngine()
    private let drums = AVAudioPlayerNode()

    init() {
        engine.attach(drums)
        engine.connect(drums, to: engine.mainMixerNode,
                       format: AVAudioFormat(standardFormatWithSampleRate: 44_100,
                                             channels: 2)!)
        drums.volume = 0.82
    }

    func start(tempo: Int, metre: SaxGrooveMeter) {
        stop()
        error = nil
        let filename = "KeysGroove_\(metre.rawValue)_\(tempo)"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else {
            error = "Missing \(filename).wav. Install the Keys Studio drum WAVs first."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            mode: .default,
                                                            options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let file = try AVAudioFile(forReading: url)
            guard file.length > 0, file.length < Int64(UInt32.max),
                  file.processingFormat.channelCount == 2,
                  abs(file.processingFormat.sampleRate - 44_100) < 0.1 else {
                error = "This groove requires stereo 44.1 kHz WAV audio."
                return
            }
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                          frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: buffer)
            try engine.start()
            drums.scheduleBuffer(buffer, at: nil, options: [.loops])
            drums.play()
            playing = true
        } catch {
            stop()
            self.error = "Unable to play groove: \(error.localizedDescription)"
        }
    }

    func elapsed() -> Double {
        guard playing, let renderTime = drums.lastRenderTime,
              let time = drums.playerTime(forNodeTime: renderTime) else { return 0 }
        return max(0, Double(time.sampleTime) / time.sampleRate)
    }

    func stop() {
        drums.stop()
        engine.stop()
        playing = false
    }
}

struct SaxStudioPlayView: View {
    let lab: MusicLab
    @StateObject private var player = SaxDrumPlayer()
    @State private var tempo = 90
    @State private var rate: SaxFingeringRate = .quarter
    @State private var sequence: SaxFingeringSequence = .lesson
    @State private var passingKey: SaxPassingKey = .bMinor
    @State private var step = 0
    @State private var performanceDismissed = false

    private let tempos = [70, 80, 90, 100, 110, 120, 130, 140]
    private let mint = Color(red: 0.61, green: 0.92, blue: 0.80)
    private let background = Color(red: 0.08, green: 0.11, blue: 0.15)
    private var metre: SaxGrooveMeter { SaxGrooveMeter(lab) }
    private var notes: [SaxPracticeNote] {
        let chosen: [SaxPracticeNote]
        switch sequence {
        case .lesson: chosen = SaxFingeringDrills.lesson(lab)
        case .chromatic: chosen = SaxFingeringDrills.chromatic
        case .passing: chosen = SaxFingeringDrills.passingTones(passingKey)
        }
        return chosen.isEmpty ? SaxFingeringDrills.chromatic : chosen
    }
    private var passingGroup: String {
        guard sequence == .passing else { return "" }
        let list = notes
        let offset = (max(0, step) / 3) * 3
        return list[offset..<min(offset + 3, list.count)]
            .map(\.writtenName).joined(separator: " – ")
    }
    private var current: SaxPracticeNote {
        let list = notes
        return list[max(0, step) % list.count]
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > geometry.size.height
            let performing = wide && !performanceDismissed

            Group {
                if performing {
                    performanceStage(height: geometry.size.height)
                } else {
                    portraitStage
                }
            }
            .background(background.ignoresSafeArea())
            .toolbar(performing ? .hidden : .visible, for: .navigationBar)
            .statusBarHidden(performing)
            .onAppear { setGlobalBackButtonHidden(performing) }
            .onChange(of: wide) { _, newWide in
                if !newWide { performanceDismissed = false }
                setGlobalBackButtonHidden(newWide && !performanceDismissed)
            }
            .onChange(of: performanceDismissed) { _, _ in
                setGlobalBackButtonHidden(wide && !performanceDismissed)
            }
        }
        .navigationTitle("Sax Play")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let digits = lab.groove.prefix(while: { $0.isNumber })
            let wanted = Int(digits) ?? 90
            tempo = tempos.min(by: { abs($0 - wanted) < abs($1 - wanted) }) ?? 90
        }
        .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { _ in
            guard player.playing else { return }
            let secondsPerNote = Double(metre.pulses) * 60.0
                / Double(tempo * rate.rawValue)
            let tick = Int(floor(player.elapsed() / secondsPerNote))
            step = max(0, tick) % notes.count
        }
        .onChange(of: tempo) { _, _ in restartIfPlaying() }
        .onChange(of: rate) { _, _ in restartIfPlaying() }
        .onChange(of: sequence) { _, _ in restartIfPlaying() }
        .onChange(of: passingKey) { _, _ in restartIfPlaying() }
        .onDisappear {
            player.stop()
            setGlobalBackButtonHidden(false)
        }
    }

    private var portraitStage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("SAX STUDIO / PLAY")
                    .font(.caption.bold()).tracking(1.6).foregroundStyle(mint)
                Text(lab.title).font(.title2.bold()).foregroundStyle(.white)
                Text("Alto sax WRITTEN pitch · \(metre.label) drums")
                    .font(.caption).foregroundStyle(.white.opacity(0.7))

                HStack {
                    Text("GROOVE SPEED").font(.caption.bold()).foregroundStyle(mint)
                    Spacer()
                    Picker("Tempo", selection: $tempo) {
                        ForEach(tempos, id: \.self) { value in
                            Text("\(value) BPM").tag(value)
                        }
                    }
                    .tint(mint)
                }

                Text("CHANGE FINGERING EVERY")
                    .font(.caption.bold()).foregroundStyle(mint)
                Picker("Change fingering every", selection: $rate) {
                    ForEach(SaxFingeringRate.allCases) { selection in
                        Text(selection.title).tag(selection)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Fingering sequence", selection: $sequence) {
                    ForEach(SaxFingeringSequence.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)

                if sequence == .passing {
                    HStack {
                        Text("CONCERT KEY").font(.caption.bold()).foregroundStyle(mint)
                        Spacer()
                        Picker("Concert key", selection: $passingKey) {
                            ForEach(SaxPassingKey.allCases) { key in
                                Text(key.rawValue).tag(key)
                            }
                        }
                        .tint(mint)
                    }
                    Text("Written alto: " + passingKey.writtenKey
                         + " · Natural minor / major scale · top → bottom → top")
                        .font(.caption).foregroundStyle(.white.opacity(0.72))
                }

                fingeringImage(maxHeight: 290)

                HStack {
                    Text("\(current.writtenName) · written alto")
                        .font(.title2.bold()).foregroundStyle(.white)
                    Spacer()
                    Text("\(step + 1) / \(notes.count)")
                        .font(.caption.monospacedDigit()).foregroundStyle(mint)
                }
                if sequence == .passing {
                    Text(passingGroup)
                        .font(.subheadline.bold())
                        .foregroundStyle(mint)
                        .accessibilityLabel("Three-note passing group: " + passingGroup)
                }
                playbackButton

                if let error = player.error {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
                Text("Suggested lesson phrases are fingering drills, not prescribed solos. You can improvise freely over the drums. Turn sideways for performance mode.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.68))
            }
            .padding(20)
        }
    }

    private func performanceStage(height: CGFloat) -> some View {
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 5) {
                Spacer(minLength: 0)
                fingeringImage(maxHeight: max(130, height - 118))
                Text(current.writtenName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if sequence == .passing {
                    Text(passingKey.rawValue + " concert · " + passingGroup)
                        .font(.caption.bold())
                        .foregroundStyle(mint)
                }
                Spacer(minLength: 0)
                playbackButton
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 20)
        }
        .overlay(alignment: .bottomLeading) {
            Button {
                performanceDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.17), in: Circle())
            }
            .accessibilityLabel("Exit sax performance mode")
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.bottom, 8)
        }
    }

    private func fingeringImage(maxHeight: CGFloat) -> some View {
        let name = String(format: "SaxFingering_%03d", current.midi)
        return Group {
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                    Text("Missing fingering image \(name)")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxHeight)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 15))
        .clipped()
    }

    private var playbackButton: some View {
        Button {
            if player.playing {
                player.stop()
                step = 0
            } else {
                step = 0
                player.start(tempo: tempo, metre: metre)
            }
        } label: {
            Image(systemName: player.playing ? "stop.fill" : "play.fill")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.black.opacity(0.9))
                .frame(width: 68, height: 68)
                .background(
                    LinearGradient(
                        colors: [mint.opacity(0.86), mint, mint.opacity(0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: mint.opacity(0.14), radius: 7, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(player.playing ? "Stop groove" : "Play groove")
        .frame(maxWidth: .infinity)
    }

    private func restartIfPlaying() {
        step = 0
        if player.playing { player.start(tempo: tempo, metre: metre) }
    }

    private func setGlobalBackButtonHidden(_ hidden: Bool) {
        NotificationCenter.default.post(
            name: Notification.Name("KeysStudioPerformanceVisibility"),
            object: hidden
        )
    }
}
