import SwiftUI
import UIKit

// EXQUIS_BOARD_V1: visual-only chord guide, no MIDI or audio changes.
// Highlight every pad sharing the selected note's pitch class, irrespective of octave.
private struct ExquisMapFile: Decodable { let keys: [ExquisPad] }
private struct ExquisPad: Decodable, Identifiable {
    let idx: Int
    let note: String
    let x: Double
    let y: Double
    var id: Int { idx }
    var pitchClass: Int? { ChordVoicing.pitchClass(String(note.dropLast())) }
}

private enum ExquisLayout {
    static let pads: [ExquisPad] = {
        guard let url = Bundle.main.url(forResource: "ExquisBoardMap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ExquisMapFile.self, from: data)
        else { return [] }
        // Some copies of Exquis-keys.jpg are tightly cropped and dark.
        // Their 61 hexagons have the SAME note order, but the calibration's
        // normalised positions were measured on the original white image.
        // Remap those positions onto the tightly cropped photo once.
        let size = UIImage(named: "ExquisBoard")?.size ?? .zero
        let cropped = size.height > 0 && size.width / size.height > 1.50
        if !cropped { return decoded.keys }
        let originalFirstX = 0.2069672131147541
        let originalLastX = 0.7941176470588235
        let originalFirstY = 0.2635651898447753
        let originalLastY = 0.7413461798695499
        let croppedFirstX = 0.07545
        let croppedLastX = 0.93021
        let croppedFirstY = 0.11253
        let croppedLastY = 0.87356
        return decoded.keys.map { pad in
            let x = croppedFirstX + (pad.x - originalFirstX)
                * (croppedLastX - croppedFirstX) / (originalLastX - originalFirstX)
            let y = croppedFirstY + (pad.y - originalFirstY)
                * (croppedLastY - croppedFirstY) / (originalLastY - originalFirstY)
            return ExquisPad(idx: pad.idx, note: pad.note, x: x, y: y)
        }
    }()
}

struct KeysBoardModePicker: View {
    @Binding var selection: String
    var body: some View {
        Picker("Keyboard", selection: $selection) {
            Text("Piano").tag("Piano")
            Text("Exquis").tag("Exquis")
        }
        .pickerStyle(.segmented)
    }
}

private struct ExquisHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.25, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 0.75, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.5))
        p.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
        p.closeSubpath()
        return p
    }
}

// EXQUIS_PITCH_CLASS_COLOURS_V1
// Each of the twelve pitch classes has its own colour; every octave shares it.
private enum ExquisNoteColours {
    // C, C♯, D, D♯, E, F, F♯, G, G♯, A, A♯, B.
    static let chromatic: [Color] = [
        Color(red: 0.92, green: 0.26, blue: 0.33), // C · crimson
        Color(red: 0.16, green: 0.72, blue: 0.44), // C♯ · green
        Color(red: 1.00, green: 0.80, blue: 0.23), // D · yellow
        Color(red: 0.30, green: 0.45, blue: 0.96), // D♯ · blue
        Color(red: 0.99, green: 0.51, blue: 0.17), // E · orange
        Color(red: 0.66, green: 0.34, blue: 0.90), // F · violet
        Color(red: 0.15, green: 0.78, blue: 0.89), // F♯ · cyan
        Color(red: 0.92, green: 0.31, blue: 0.72), // G · magenta
        Color(red: 0.68, green: 0.84, blue: 0.21), // G♯ · lime
        Color(red: 0.12, green: 0.54, blue: 0.58), // A · teal
        Color(red: 1.00, green: 0.62, blue: 0.73), // A♯ · pink
        Color(red: 0.70, green: 0.54, blue: 0.33)  // B · bronze
    ]

    static func colour(for pitchClass: Int) -> Color {
        chromatic[((pitchClass % 12) + 12) % 12]
    }

    // EXQUIS_PITCH_CLASS_NOTE_NAMES_V1: chromatic names, no octave numbers.
    static let noteNames = ["C", "C♯", "D", "D♯", "E", "F",
                            "F♯", "G", "G♯", "A", "A♯", "B"]

    static func noteName(for pitchClass: Int) -> String {
        noteNames[((pitchClass % 12) + 12) % 12]
    }

    static func labelColour(for pitchClass: Int) -> Color {
        // Choose dark lettering on the light-coloured pads.
        switch ((pitchClass % 12) + 12) % 12 {
        case 1, 2, 4, 6, 8, 10, 11:
            return Color(red: 0.08, green: 0.11, blue: 0.15)
        default:
            return .white
        }
    }
}

struct ExquisChordBoard: View {
    let labID: String
    let chordIndex: Int
    let chord: MusicChord
    let omitRoot: Bool

    private let ink = Color(red: 0.08, green: 0.11, blue: 0.15)
    private var photoSize: CGSize {
        UIImage(named: "ExquisBoard")?.size
            ?? CGSize(width: 1754, height: 1241)
    }

    private var chordPitchClasses: Set<Int> {
        Set(CuratedKeyboardShape.notes(
            labID: labID, index: chordIndex, chord: chord, omitRoot: omitRoot
        ).map { $0.midi % 12 })
    }
    private var rootPitchClass: Int {
        ChordVoicing.pitchClass(ChordVoicing.root(of: chord.symbol)) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            let photoWidth = max(1, photoSize.width)
            let photoHeight = max(1, photoSize.height)
            let scale = min(geometry.size.width / photoWidth,
                            geometry.size.height / photoHeight)
            let w = photoWidth * scale
            let h = photoHeight * scale
            let active = chordPitchClasses
            let root = rootPitchClass
            let cropped = photoWidth / photoHeight > 1.50
            let hexWidth = cropped ? w * 0.094 : w * (109.0 / 1754.0)
            let hexHeight = cropped ? h * 0.129 : h * (96.0 / 1241.0)

            ZStack {
                ZStack(alignment: .topLeading) {
                    Image("ExquisBoard")
                        .resizable()
                        .frame(width: w, height: h)

                    // EXQUIS_PAD_NOTE_LABELS_V1: label all 61 pads, highlight chord pitches.
                    ForEach(ExquisLayout.pads) { pad in
                        if let pc = pad.pitchClass {
                            let isRoot = pc == root
                            let isHighlighted = isRoot || active.contains(pc)
                            ZStack {
                                if isHighlighted {
                                    ExquisHexagon()
                                        .fill(ExquisNoteColours.colour(for: pc).opacity(0.87))
                                        .overlay {
                                            ExquisHexagon()
                                                .stroke(ink.opacity(0.78),
                                                        lineWidth: max(0.8, scale * 2))
                                        }
                                        .overlay {
                                            if isRoot {
                                                ExquisHexagon()
                                                    .stroke(.white, lineWidth: max(1.8, scale * 3.5))
                                            }
                                        }
                                }

                                Text(ExquisNoteColours.noteName(for: pc))
                                    .font(.system(size: max(8, min(16, hexWidth * 0.41)),
                                                  weight: .bold, design: .rounded))
                                    .foregroundStyle(isHighlighted
                                                     ? ExquisNoteColours.labelColour(for: pc)
                                                     : Color.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .padding(.horizontal, 2)
                                    .background {
                                        if !isHighlighted {
                                            Capsule().fill(Color.black.opacity(0.65))
                                        }
                                    }
                                    .frame(maxWidth: hexWidth * 0.88)
                                    .allowsHitTesting(false)
                            }
                            .frame(width: hexWidth, height: hexHeight)
                            .position(x: w * pad.x, y: h * pad.y)
                        }
                    }
                }
                .frame(width: w, height: h)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Exquis chord \(chord.symbol). Every pad shows its note name without octave numbers. Chord notes are coloured; white outlines show roots.")
    }
}
