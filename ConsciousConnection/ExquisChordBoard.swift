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
        return decoded.keys
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

struct ExquisChordBoard: View {
    let labID: String
    let chordIndex: Int
    let chord: MusicChord
    let omitRoot: Bool

    private let ink = Color(red: 0.08, green: 0.11, blue: 0.15)
    private let mint = Color(red: 0.61, green: 0.92, blue: 0.80)
    private let gold = Color(red: 1, green: 0.84, blue: 0.28)
    private let photoWidth: CGFloat = 1754
    private let photoHeight: CGFloat = 1241

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
            let scale = min(geometry.size.width / photoWidth,
                            geometry.size.height / photoHeight)
            let w = photoWidth * scale
            let h = photoHeight * scale
            let active = chordPitchClasses
            let root = rootPitchClass

            ZStack {
                ZStack(alignment: .topLeading) {
                    Image("ExquisBoard")
                        .resizable()
                        .frame(width: w, height: h)

                    ForEach(ExquisLayout.pads) { pad in
                        if let pc = pad.pitchClass,
                           pc == root || active.contains(pc) {
                            let isRoot = pc == root
                            ExquisHexagon()
                                .fill((isRoot ? gold : mint).opacity(isRoot ? 0.90 : 0.79))
                                .overlay {
                                    ExquisHexagon()
                                        .stroke(ink.opacity(0.76),
                                                lineWidth: max(0.8, scale * 2))
                                }
                                .frame(width: 109 * scale, height: 96 * scale)
                                .position(x: w * pad.x, y: h * pad.y)
                        }
                    }
                }
                .frame(width: w, height: h)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Exquis chord \(chord.symbol). Mint: chord notes. Gold: root.")
    }
}
