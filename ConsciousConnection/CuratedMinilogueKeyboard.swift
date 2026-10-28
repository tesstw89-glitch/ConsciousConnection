import SwiftUI

// Each note's octave and hand is curated for its exact lesson/progression slot.
// Do not infer hands by note order or a keyboard split point.
private struct CuratedHandFile: Decodable {
    let schema: Int
    let labs: [String: [CuratedHandSlot]]
}

private struct CuratedHandSlot: Decodable {
    let chord: String
    let left: [String]
    let right: [String]
    let rootPC: Int
}

struct CuratedKeyboardNote: Identifiable {
    let midi: Int
    let label: String
    let hand: String
    let finger: Int
    var id: Int { midi }

    init(midi: Int, label: String, hand: String, finger: Int = 0) {
        self.midi = midi
        self.label = label
        self.hand = hand
        self.finger = finger
    }
}

// KEYS_FINGER_NUMBERS_V1
// Suggested piano fingering: 1 = thumb, 5 = little finger.
// Numbers refer to the original voicing, even when the root is omitted.
private enum CuratedFingerSuggestions {
    static func numbers(_ names: [String], hand: String) -> [Int] {
        let midi: [Int] = names.compactMap { name in
            guard let octave = name.last?.wholeNumberValue,
                  let pc = ChordVoicing.pitchClass(String(name.dropLast())) else { return nil }
            return (octave + 1) * 12 + pc
        }
        guard midi.count == names.count else { return Array(repeating: 0, count: names.count) }
        let count = midi.count
        guard count > 0 else { return [] }
        if count == 1 { return [1] }
        let span = midi.last! - midi.first!
        if hand == "left" {
            if count == 2 {
                let low = span <= 2 ? 2 : span <= 4 ? 3 : span <= 6 ? 4 : 5
                return [low, 1]
            }
            if count == 3 { return [5, 3, 1] }
            if count == 4 { return [5, 4, 2, 1] }
            return [5, 4, 3, 2, 1]
        }
        if count == 2 {
            let high = span <= 2 ? 2 : span <= 4 ? 3 : span <= 6 ? 4 : 5
            return [1, high]
        }
        if count == 3 {
            let lowGap = midi[1] - midi[0]
            let highGap = midi[2] - midi[1]
            if span <= 4 { return [1, 2, 3] }
            if lowGap <= 2 { return [1, 2, 5] }
            if highGap <= 2 { return [1, lowGap >= 5 ? 4 : 3, 5] }
            return [1, 3, 5]
        }
        if count == 4 { return [1, 2, 3, 5] }
        return [1, 2, 3, 4, 5]
    }
}

enum CuratedKeyboardShape {
    private static let catalog: CuratedHandFile? = {
        guard let url = Bundle.main.url(forResource: "Keys_Studio_Hand_Assignments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(CuratedHandFile.self, from: data),
              file.schema == 1 else { return nil }
        return file
    }()

    private static func slot(labID: String, index: Int, chord: MusicChord) -> CuratedHandSlot? {
        guard let all = catalog?.labs[labID], all.indices.contains(index) else { return nil }
        let value = all[index]
        // A data mismatch is safer to show as an empty keyboard than a false hand assignment.
        return value.chord == chord.symbol ? value : nil
    }

    private static func position(_ note: String, hand: String, finger: Int) -> CuratedKeyboardNote? {
        guard let octave = note.last?.wholeNumberValue,
              let pitchClass = ChordVoicing.pitchClass(String(note.dropLast())) else { return nil }
        let midi = (octave + 1) * 12 + pitchClass
        guard (48...84).contains(midi) else { return nil }
        return CuratedKeyboardNote(midi: midi, label: note, hand: hand, finger: finger)
    }

    static func notes(labID: String, index: Int, chord: MusicChord, omitRoot: Bool) -> [CuratedKeyboardNote] {
        guard let voicing = slot(labID: labID, index: index, chord: chord) else { return [] }
        let leftFingers = CuratedFingerSuggestions.numbers(voicing.left, hand: "left")
        let rightFingers = CuratedFingerSuggestions.numbers(voicing.right, hand: "right")
        let all = voicing.left.enumerated().compactMap {
            position($0.element, hand: "left", finger: leftFingers[$0.offset])
        } + voicing.right.enumerated().compactMap {
            position($0.element, hand: "right", finger: rightFingers[$0.offset])
        }
        return omitRoot ? all.filter { $0.midi % 12 != voicing.rootPC } : all
    }

    static func hasShape(labID: String, index: Int, chord: MusicChord) -> Bool {
        slot(labID: labID, index: index, chord: chord) != nil
    }

    static func rootMarker(labID: String, index: Int, chord: MusicChord, omitRoot: Bool) -> Int? {
        guard let voicing = slot(labID: labID, index: index, chord: chord) else { return nil }
        let notes = notes(labID: labID, index: index, chord: chord, omitRoot: omitRoot)
        if let played = notes.first(where: { $0.midi % 12 == voicing.rootPC }) { return played.midi }
        let anchor = notes.first?.midi ?? 60
        return (48...84).filter { $0 % 12 == voicing.rootPC }
            .min(by: { abs($0 - anchor) < abs($1 - anchor) })
    }
}


struct CuratedMinilogueKeyboard: View {
    let labID: String
    let chordIndex: Int
    let chord: MusicChord
    let omitRoot: Bool

    static let leftColour = Color(
        red: 0.39, green: 0.71, blue: 0.98
    )
    static let rightColour = Color(
        red: 0.99, green: 0.60, blue: 0.71
    )
    static let rootColour = Color(
        red: 1.00, green: 0.87, blue: 0.22
    )

    private var currentNotes: [CuratedKeyboardNote] {
        CuratedKeyboardShape.notes(
            labID: labID,
            index: chordIndex,
            chord: chord,
            omitRoot: omitRoot
        )
    }

    private var currentRootMIDI: Int? {
        CuratedKeyboardShape.rootMarker(
            labID: labID,
            index: chordIndex,
            chord: chord,
            omitRoot: omitRoot
        )
    }

    var body: some View {
        let notes = currentNotes

        return VStack(alignment: .leading, spacing: 12) {
            CuratedMinilogueKeybed(
                notes: notes,
                rootMIDI: currentRootMIDI
            )
            .frame(height: 110)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                accessibilityDescription(notes)
            )

            if notes.isEmpty {
                Text("No reviewed hand shape for this chord.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            handLegend
        }
    }

    private func accessibilityDescription(
        _ notes: [CuratedKeyboardNote]
    ) -> String {
        let left = notes
            .filter { $0.hand == "left" }
            .map(\.label)
            .joined(separator: ", ")

        let right = notes
            .filter { $0.hand == "right" }
            .map(\.label)
            .joined(separator: ", ")

        return "Minilogue chord \(chord.symbol). " +
               "Left hand: \(left). Right hand: \(right)"
    }

    private var handLegend: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Self.leftColour)
                .frame(width: 9, height: 9)
            Text("Left hand")

            Circle()
                .fill(Self.rightColour)
                .frame(width: 9, height: 9)
            Text("Right hand")

            Circle()
                .fill(Self.rootColour)
                .frame(width: 9, height: 9)
            Text("Root")

            Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.85))
    }
}

// Keyboard rendering is separated to simplify
// SwiftUI compilation without changing note assignments.
private struct CuratedMinilogueKeybed: View {
    let notes: [CuratedKeyboardNote]
    let rootMIDI: Int?

    private let whiteScale = [0, 2, 4, 5, 7, 9, 11]

    private func whiteMIDI(_ index: Int) -> Int {
        48 + (index / 7) * 12 + whiteScale[index % 7]
    }

    var body: some View {
        let pressed = Dictionary(
            uniqueKeysWithValues: notes.map { ($0.midi, $0) }
        )

        return GeometryReader { geometry in
            let whiteWidth = geometry.size.width / 22

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(
                        red: 0.14,
                        green: 0.17,
                        blue: 0.19
                    ))

                whiteKeys(
                    width: whiteWidth,
                    height: geometry.size.height,
                    pressed: pressed
                )

                blackKeys(
                    width: whiteWidth,
                    height: geometry.size.height,
                    pressed: pressed
                )
            }
        }
    }

    private func whiteKeys(
        width: CGFloat,
        height: CGFloat,
        pressed: [Int: CuratedKeyboardNote]
    ) -> some View {
        ForEach(0..<22, id: \.self) { index in
            let midi = whiteMIDI(index)

            KeySurface(
                note: pressed[midi],
                isRoot: rootMIDI == midi,
                isBlack: false
            )
            .frame(
                width: width - 0.5,
                height: height - 4
            )
            .position(
                x: width * (CGFloat(index) + 0.5),
                y: height / 2
            )
        }
    }

    private func blackKeys(
        width: CGFloat,
        height: CGFloat,
        pressed: [Int: CuratedKeyboardNote]
    ) -> some View {
        ForEach(0..<21, id: \.self) { index in
            let natural = whiteMIDI(index)

            if [0, 2, 5, 7, 9].contains(natural % 12) {
                let midi = natural + 1
                let blackHeight = height * 0.64

                KeySurface(
                    note: pressed[midi],
                    isRoot: rootMIDI == midi,
                    isBlack: true
                )
                .frame(
                    width: width * 0.62,
                    height: blackHeight
                )
                .position(
                    x: CGFloat(index + 1) * width,
                    y: blackHeight / 2 + 2
                )
                .zIndex(2)
            }
        }
    }
}

private struct KeySurface: View {
    let note: CuratedKeyboardNote?
    let isRoot: Bool
    let isBlack: Bool

    private var baseColour: Color {
        if note?.hand == "left" { return CuratedMinilogueKeyboard.leftColour }
        if note?.hand == "right" { return CuratedMinilogueKeyboard.rightColour }
        return isBlack ? .black : .white
    }

    var body: some View {
        VStack(spacing: 0) {
            if isRoot {
                Circle()
                    .fill(CuratedMinilogueKeyboard.rootColour)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            if let note = note {
                Text(String(note.finger))
                    .font(.system(size: isBlack ? 12 : 17, weight: .black, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.84))
                Spacer(minLength: 0)
                Text(note.label)
                    .font(.system(size: isBlack ? 7 : 8, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .foregroundStyle(Color.black)
                    .padding(.bottom, 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(baseColour, in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2)
            .stroke(isBlack ? Color.gray.opacity(0.75) : Color.black.opacity(0.75), lineWidth: 0.8))
    }
}
