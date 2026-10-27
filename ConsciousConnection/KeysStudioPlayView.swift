import SwiftUI
import AVFoundation
import Darwin

// WAV and synthesized chord buffers share one AVAudioEngine start time.
// The visual piano reads the player sample clock, not a drifting timer.
private enum KeysChordRate: Int, CaseIterable, Identifiable {
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

private enum KeysGrooveMeter: String {
    case four = "4_4", five = "5_4", six = "6_8"
    init(groove: String) {
        if groove.contains("5/4") { self = .five }
        else if groove.contains("6/8") { self = .six }
        else { self = .four }
    }
    var pulsesPerBar: Int {
        switch self {
        case .four: return 4
        case .five: return 5
        case .six: return 2 // dotted-quarter pulse in the 6/8 lab
        }
    }
    var display: String {
        switch self {
        case .four: return "4/4"
        case .five: return "5/4"
        case .six: return "6/8"
        }
    }
}

@MainActor
private final class KeysStudioLoopPlayer: ObservableObject {
    @Published private(set) var playing = false
    @Published var error: String?

    private let engine = AVAudioEngine()
    private let drums = AVAudioPlayerNode()
    private let piano = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var started = false

    init() {
        engine.attach(drums)
        engine.attach(piano)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        engine.connect(drums, to: engine.mainMixerNode, format: format)
        engine.connect(piano, to: engine.mainMixerNode, format: format)
        drums.volume = 0.84
        piano.volume = 0.52
    }

    func start(lab: MusicLab, bpm: Int, meter: KeysGrooveMeter,
               rate: Int, omitRoot: Bool, hearPiano: Bool) {
        stop()
        error = nil
        guard !lab.chords.isEmpty else { error = "This lesson has no chords."; return }
        guard let url = Bundle.main.url(forResource: "KeysGroove_\(meter.rawValue)_\(bpm)", withExtension: "wav") else {
            error = "Drum WAV missing for \(bpm) BPM in \(meter.display). Re-run the groove generator."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let file = try AVAudioFile(forReading: url)
            guard file.length < Int64(UInt32.max), file.processingFormat.channelCount == 2,
                  abs(file.processingFormat.sampleRate - sampleRate) < 0.1 else {
                error = "The drum WAV must be stereo, 44.1 kHz."; return
            }
            let drumBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                              frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: drumBuffer)
            let chordBuffer = makePianoBuffer(lab: lab, bpm: bpm, meter: meter,
                                              rate: rate, omitRoot: omitRoot)
            try engine.start()
            started = true
            drums.scheduleBuffer(drumBuffer, at: nil, options: [.loops])
            piano.scheduleBuffer(chordBuffer, at: nil, options: [.loops])
            piano.volume = hearPiano ? 0.52 : 0
            let startTime = AVAudioTime(hostTime: mach_absolute_time() + AVAudioTime.hostTime(forSeconds: 0.15))
            drums.play(at: startTime)
            piano.play(at: startTime)
            playing = true
        } catch {
            stop()
            self.error = "Audio could not start: \(error.localizedDescription)"
        }
    }

    func setPianoAudible(_ enabled: Bool) { piano.volume = enabled ? 0.52 : 0 }

    func elapsedSeconds() -> Double {
        guard playing, let nodeTime = drums.lastRenderTime,
              let playerTime = drums.playerTime(forNodeTime: nodeTime) else { return 0 }
        return max(0, Double(playerTime.sampleTime) / playerTime.sampleRate)
    }

    func stop() {
        drums.stop()
        piano.stop()
        if started { engine.stop(); started = false }
        playing = false
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var (x, y) = (a, b)
        while y != 0 { (x, y) = (y, x % y) }
        return x
    }

    private func makePianoBuffer(lab: MusicLab, bpm: Int, meter: KeysGrooveMeter,
                                 rate: Int, omitRoot: Bool) -> AVAudioPCMBuffer {
        let chordCount = lab.chords.count
        let totalSteps = (chordCount * (2 * rate)) / gcd(chordCount, 2 * rate)
        let chordSeconds = Double(meter.pulsesPerBar) * 60.0 / Double(bpm * rate)
        let totalFrames = Int((Double(totalSteps) * chordSeconds * sampleRate).rounded())
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                      frameCapacity: AVAudioFrameCount(totalFrames))!
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        guard let audio = buffer.floatChannelData else { return buffer }
        for channel in 0..<2 { audio[channel].initialize(repeating: 0, count: totalFrames) }

        for step in 0..<totalSteps {
            let index = step % chordCount
            let chord = lab.chords[index]
            let pitches = CuratedKeyboardShape.notes(labID: lab.id, index: index,
                                                     chord: chord, omitRoot: omitRoot)
            if pitches.isEmpty { continue }
            let startFrame = Int((Double(step) * chordSeconds * sampleRate).rounded())
            let seconds = min(chordSeconds * 0.88, 1.75)
            let frames = min(Int(seconds * sampleRate), totalFrames - startFrame)
            if frames <= 0 { continue }
            let gain = 0.24 / Float(max(1, pitches.count))
            for pitch in pitches {
                let frequency = 440.0 * pow(2, Double(pitch.midi - 69) / 12)
                for i in 0..<frames {
                    let t = Double(i) / sampleRate
                    let attack = min(1.0, t / 0.008)
                    let release = min(1.0, (seconds - t) / 0.085)
                    let envelope = Float(attack * max(0, release) * exp(-1.8 * t))
                    let tone = Float(
                        sin(2 * .pi * frequency * t) * 0.75 +
                        sin(4 * .pi * frequency * t) * 0.18 * exp(-3*t) +
                        sin(6 * .pi * frequency * t) * 0.07 * exp(-5*t)
                    )
                    let value = gain * envelope * tone
                    audio[0][startFrame + i] += value
                    audio[1][startFrame + i] += value
                }
            }
        }
        return buffer
    }
}

struct KeysStudioPlayView: View {
    let lab: MusicLab
    @StateObject private var player = KeysStudioLoopPlayer()
    @State private var tempo = 90
    @State private var rate: KeysChordRate = .bar
    @State private var hearPiano = false
    @State private var omitRoot = false
    @State private var currentChordIndex = 0

    private let tempos = [70, 80, 90, 100, 110, 120, 130, 140]
    private let accent = Color(red: 0.61, green: 0.92, blue: 0.80)
    private var meter: KeysGrooveMeter { KeysGrooveMeter(groove: lab.groove) }
    private var currentChord: MusicChord? {
        guard !lab.chords.isEmpty else { return nil }
        return lab.chords[currentChordIndex % lab.chords.count]
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.11, blue: 0.15).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Text("KEYS STUDIO / PLAY")
                        .font(.caption.bold()).tracking(1.5).foregroundStyle(accent)
                    Text(lab.title).font(.title2.bold()).foregroundStyle(.white)
                    Text("Drum groove · \(meter.display) · \(tempo) BPM")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.7))

                    Text("BACKING GROOVE")
                        .font(.caption.bold()).foregroundStyle(accent)
                    Picker("BPM", selection: $tempo) {
                        ForEach(tempos, id: \.self) { bpm in Text("\(bpm) BPM").tag(bpm) }
                    }.pickerStyle(.menu).tint(accent)

                    Text("CHORD CHANGES")
                        .font(.caption.bold()).foregroundStyle(accent)
                    Picker("How long each chord lasts", selection: $rate) {
                        ForEach(KeysChordRate.allCases) { choice in
                            Text(choice.title).tag(choice)
                        }
                    }.pickerStyle(.segmented)

                    Toggle("Hear piano chords", isOn: $hearPiano).tint(accent)
                    Toggle("Use rootless chord voicings", isOn: $omitRoot).tint(accent)
                    Text("The piano sound uses the exact notes highlighted for each hand. Switch it off when you want to play those chords yourself.")
                        .font(.caption).foregroundStyle(.white.opacity(0.65))

                    if let chord = currentChord {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(chord.symbol).font(.largeTitle.bold()).foregroundStyle(.white)
                                Spacer()
                                Text("\(currentChordIndex + 1) / \(lab.chords.count)")
                                    .font(.caption.monospacedDigit()).foregroundStyle(accent)
                            }
                            CuratedMinilogueKeyboard(labID: lab.id, chordIndex: currentChordIndex,
                                                     chord: chord, omitRoot: omitRoot)
                        }
                        .padding(14)
                        .background(.white.opacity(0.085), in: RoundedRectangle(cornerRadius: 15))
                    }

                    HStack {
                        Button {
                            if player.playing { player.stop(); currentChordIndex = 0 }
                            else { play() }
                        } label: {
                            Label(player.playing ? "Stop" : "Play",
                                  systemImage: player.playing ? "stop.fill" : "play.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(14)
                                .background(accent, in: RoundedRectangle(cornerRadius: 13))
                                .foregroundStyle(Color.black)
                        }.buttonStyle(.plain)
                    }
                    if let error = player.error {
                        Text(error).font(.caption).foregroundStyle(.orange)
                    }
                    Text("The selected WAV provides drums. The piano is a lightweight synthesized preview, not a sampled grand piano. Tempo and chord rate are adjustable while stopped or playing.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.55))
                }
                .padding(20)
            }
        }
        .navigationTitle("Play Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let statedBPM = Int(lab.groove.prefix(while: { $0.isNumber })) ?? 90
            tempo = tempos.min(by: { abs($0-statedBPM) < abs($1-statedBPM) }) ?? 90
            omitRoot = lab.category.localizedCaseInsensitiveContains("rootless")
        }
        .onReceive(Timer.publish(every: 1.0/30.0, on: .main, in: .common).autoconnect()) { _ in
            guard player.playing && !lab.chords.isEmpty else { return }
            let duration = Double(meter.pulsesPerBar) * 60.0 / Double(tempo * rate.rawValue)
            let step = Int(floor(player.elapsedSeconds() / duration))
            currentChordIndex = max(0, step) % lab.chords.count
        }
        .onChange(of: tempo) { _, _ in restartIfPlaying() }
        .onChange(of: rate) { _, _ in restartIfPlaying() }
        .onChange(of: omitRoot) { _, _ in restartIfPlaying() }
        .onChange(of: hearPiano) { _, value in player.setPianoAudible(value) }
        .onDisappear { player.stop() }
    }

    private func restartIfPlaying() {
        if player.playing { play() }
        else { currentChordIndex = 0 }
    }

    private func play() {
        currentChordIndex = 0
        player.start(lab: lab, bpm: tempo, meter: meter, rate: rate.rawValue,
                     omitRoot: omitRoot, hearPiano: hearPiano)
    }
}
