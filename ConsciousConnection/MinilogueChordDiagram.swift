import SwiftUI

// A drawn 37-key C3–C6 Minilogue layout. No bitmap overlays: highlights
// remain aligned as the device rotates or the view changes width.
struct MinilogueChordDiagram: View {
    let chord: MusicChord
    let rootless: Bool
    let inversion: Int

    private let whiteScale = [0, 2, 4, 5, 7, 9, 11]
    private let highlight = Color(red: 0.30, green: 0.84, blue: 0.73)
    private let rootHighlight = Color(red: 1.00, green: 0.72, blue: 0.39)

    private var selected: [Int: String] {
        Dictionary(uniqueKeysWithValues: ChordVoicing.positions(for: chord,
                                                                 rootless: rootless,
                                                                 inversion: inversion)
            .map { ($0.midi, $0.label) })
    }

    private var rootClass: Int {
        ChordVoicing.pitchClass(ChordVoicing.root(of: chord.symbol)) ?? 0
    }

    private func whiteMIDI(_ index: Int) -> Int {
        48 + (index / 7) * 12 + whiteScale[index % 7]
    }

    var body: some View {
        GeometryReader { geometry in
            let whiteWidth = geometry.size.width / 22
            let blackWidth = whiteWidth * 0.62
            let blackHeight = geometry.size.height * 0.62
            let pressed = selected

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.14, green: 0.17, blue: 0.19))

                ForEach(0..<22, id: \.self) { index in
                    let midi = whiteMIDI(index)
                    let active = pressed[midi] != nil
                    let root = active && (midi % 12 == rootClass)
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active ? (root ? rootHighlight : highlight) : Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.7), lineWidth: 0.8))
                        if let name = pressed[midi] {
                            Text(name)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .foregroundStyle(Color.black)
                                .padding(.bottom, 5)
                        }
                    }
                    .frame(width: whiteWidth - 0.5, height: geometry.size.height - 4)
                    .position(x: whiteWidth * (CGFloat(index) + 0.5),
                              y: geometry.size.height / 2)
                }

                ForEach(0..<21, id: \.self) { index in
                    let natural = whiteMIDI(index)
                    if [0, 2, 5, 7, 9].contains(natural % 12) {
                        let midi = natural + 1
                        let active = pressed[midi] != nil
                        let root = active && (midi % 12 == rootClass)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(active ? (root ? rootHighlight : highlight) : Color.black)
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.gray.opacity(0.8), lineWidth: 0.75))
                            if let name = pressed[midi] {
                                Text(name)
                                    .font(.system(size: 7, weight: .bold, design: .rounded))
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                                    .foregroundStyle(Color.black)
                                    .padding(.bottom, 4)
                            }
                        }
                        .frame(width: blackWidth, height: blackHeight)
                        .position(x: CGFloat(index + 1) * whiteWidth,
                                  y: blackHeight / 2 + 2)
                        .zIndex(2)
                    }
                }
            }
        }
        .frame(height: 104)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Minilogue keyboard. \(chord.symbol). Play \(ChordVoicing.positions(for: chord, rootless: rootless, inversion: inversion).map(\.label).joined(separator: ", "))")
    }
}

struct ChordVoicing {
    struct Position {
        let midi: Int
        let label: String
    }

    static func root(of symbol: String) -> String {
        let characters = Array(symbol)
        guard let letter = characters.first else { return "C" }
        if characters.count > 1 && ["♯", "#", "♭", "b"].contains(String(characters[1])) {
            return String(characters.prefix(2))
        }
        return String(letter)
    }

    static func pitchClass(_ text: String) -> Int? {
        guard let first = text.first else { return nil }
        let fundamentals: [Character: Int] = [
            "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
        ]
        guard let base = fundamentals[first] else { return nil }
        let rest = text.dropFirst()
        let accidental = rest.first == "♯" || rest.first == "#" ? 1 :
            (rest.first == "♭" || rest.first == "b" ? -1 : 0)
        return (base + accidental + 12) % 12
    }

    private static let sharps = [
        "C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"
    ]
    private static let flats = [
        "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"
    ]

    // Explicit chord ingredients from the user's Keys Studio manual take
    // priority. For slash chords, the bass note belongs to the backing
    // track; the keyboard shows the upper chord unless it is part of the voicing.
    private static func notes(for chord: MusicChord) -> [(Int, String)] {
        if !chord.notes.isEmpty {
            let candidates = chord.notes.compactMap { name -> (Int, String)? in
                guard let pitch = pitchClass(name) else { return nil }
                return (pitch, name)
            }
            if candidates.count >= 3 { return unique(candidates) }
        }
        let name = chord.symbol.components(separatedBy: "/")[0]
        let root = root(of: name)
        let rootPC = pitchClass(root) ?? 0
        let suffix = String(name.dropFirst(root.count))
        var intervals: [Int]
        if suffix.hasPrefix("m7♭5") {
            intervals = [0, 3, 6, 10]
        } else if suffix.hasPrefix("maj") {
            intervals = [0, 4, 7, 11]
            if suffix.contains("9") { intervals.append(14) }
        } else if suffix.hasPrefix("m") {
            intervals = [0, 3, 7]
            if suffix.contains("7") || suffix.contains("9") || suffix.contains("11") {
                intervals.append(10)
            }
            if suffix.contains("9") || suffix.contains("11") { intervals.append(14) }
            if suffix.contains("11") || suffix.contains("add11") { intervals.append(17) }
        } else if suffix.contains("sus") {
            intervals = [0, 5, 7, 10]
            if suffix.contains("13") { intervals += [14, 21] }
        } else if suffix.hasPrefix("7") || suffix.hasPrefix("13") {
            intervals = [0, 4, 7, 10]
            if suffix.contains("13") { intervals += [14, 21] }
        } else if suffix.hasPrefix("6") {
            intervals = [0, 4, 7, 9]
            if suffix.contains("9") { intervals.append(14) }
        } else {
            intervals = [0, 4, 7]
        }
        if suffix.contains("♭9") { intervals.append(13) }
        if suffix.contains("♯11") { intervals.append(18) }
        if suffix.contains("add11") && !intervals.contains(17) { intervals.append(17) }

        let useFlats = name.contains("♭") || ["F", "B♭", "E♭", "A♭", "D♭", "G♭"].contains(root)
        return unique(intervals.map { interval in
            let pc = (rootPC + interval) % 12
            return (pc, (useFlats ? flats : sharps)[pc])
        })
    }

    private static func unique(_ input: [(Int, String)]) -> [(Int, String)] {
        var used: Set<Int> = []
        return input.filter { used.insert($0.0).inserted }
    }

    static func positions(for chord: MusicChord, rootless: Bool, inversion: Int) -> [Position] {
        let rootPC = pitchClass(root(of: chord.symbol)) ?? 0
        var tones = notes(for: chord)
        if rootless { tones.removeAll { $0.0 == rootPC } }
        guard !tones.isEmpty else { return [] }

        let shift = ((inversion % tones.count) + tones.count) % tones.count
        tones = Array(tones.dropFirst(shift)) + Array(tones.prefix(shift))
        var current = 60 + tones[0].0
        var arranged: [Position] = []
        for (pc, writtenName) in tones {
            while current % 12 != pc { current += 1 }
            arranged.append(Position(midi: current,
                                     label: writtenName + String(current / 12 - 1)))
            current += 1
        }
        // Keep all suggested keys inside the real 37-key C3–C6 compass.
        while arranged.last.map({ $0.midi > 84 }) == true {
            arranged = arranged.map { pos in
                Position(midi: pos.midi - 12,
                         label: String(pos.label.dropLast(1)) + String(pos.midi / 12 - 2))
            }
        }
        return arranged.filter { (48...84).contains($0.midi) }
    }
}