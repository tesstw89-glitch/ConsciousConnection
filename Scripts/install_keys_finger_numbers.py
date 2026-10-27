#!/usr/bin/env python3
# Add suggested piano finger numbers to existing reviewed Minilogue chords.
# No ZIP, backups, checkout, merges or other file changes.
from pathlib import Path
import subprocess, tempfile, sys

root = Path.home() / "Desktop/ConsciousConnection/ConsciousConnection"
keyboard = root / "CuratedMinilogueKeyboard.swift"
play = root / "KeysStudioPlayView.swift"

if not (keyboard.is_file() and play.is_file()):
    sys.exit("SAFE STOP: Could not find both Keys Studio files.")
a, b = keyboard.read_text(), play.read_text()
if "KEYS_FINGER_NUMBERS_V1" in a:
    sys.exit("Finger-number patch is already installed.")
if a.count("struct CuratedKeyboardNote: Identifiable {") != 1 or a.count("private struct KeySurface: View {") != 1:
    sys.exit("SAFE STOP: Keyboard structure differs. No files changed.")
if b.count("private struct KeysPerformanceKey: View {") != 1:
    sys.exit("SAFE STOP: Landscape key rendering was not found. No files changed.")

def replace_once(source, before, after, label):
    if source.count(before) != 1:
        sys.exit(f"SAFE STOP: Unexpected {label}. No files changed.")
    return source.replace(before, after, 1)

helper = '''// KEYS_FINGER_NUMBERS_V1
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

'''
a = replace_once(a, 'enum CuratedKeyboardShape {', helper + 'enum CuratedKeyboardShape {', 'fingering helper insertion')
a = replace_once(a, '''    let hand: String
    var id: Int { midi }
''','''    let hand: String
    let finger: Int
    var id: Int { midi }

    init(midi: Int, label: String, hand: String, finger: Int = 0) {
        self.midi = midi
        self.label = label
        self.hand = hand
        self.finger = finger
    }
''', 'curated note definition')
a = replace_once(a, 'private static func position(_ note: String, hand: String) -> CuratedKeyboardNote?', 'private static func position(_ note: String, hand: String, finger: Int) -> CuratedKeyboardNote?', 'note initializer signature')
a = replace_once(a, 'CuratedKeyboardNote(midi: midi, label: note, hand: hand)', 'CuratedKeyboardNote(midi: midi, label: note, hand: hand, finger: finger)', 'note initializer')
a = replace_once(a, '''        let all = voicing.left.compactMap { position($0, hand: "left") }
                + voicing.right.compactMap { position($0, hand: "right") }
''','''        let leftFingers = CuratedFingerSuggestions.numbers(voicing.left, hand: "left")
        let rightFingers = CuratedFingerSuggestions.numbers(voicing.right, hand: "right")
        let all = voicing.left.enumerated().compactMap {
            position($0.element, hand: "left", finger: leftFingers[$0.offset])
        } + voicing.right.enumerated().compactMap {
            position($0.element, hand: "right", finger: rightFingers[$0.offset])
        }
''', 'hand assignment construction')
start = a.index('private struct KeySurface: View {')
head, tail = a[:start], a[start:]
tail = replace_once(tail, '''            Spacer(minLength: 0)
            if let note = note {
                Text(note.label)''','''            Spacer(minLength: 0)
            if let note = note {
                Text(String(note.finger))
                    .font(.system(size: isBlack ? 12 : 17, weight: .black, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.84))
                Spacer(minLength: 0)
                Text(note.label)''','portrait finger rendering')
a = head + tail
start = b.index('private struct KeysPerformanceKey: View {')
head, tail = b[:start], b[start:]
tail = replace_once(tail, '''            if let note {
                Text(note.label)''', '''            if let note {
                Text(String(note.finger))
                    .font(.system(size: black ? 19 : 30, weight: .black, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.82))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                Text(note.label)''', 'landscape finger rendering')
b = head + tail
with tempfile.TemporaryDirectory() as td:
    ka, pb = Path(td)/keyboard.name, Path(td)/play.name
    ka.write_text(a)
    pb.write_text(b)
    result = subprocess.run(['xcrun', 'swiftc', '-frontend', '-parse', str(ka), str(pb)],
                            capture_output=True, text=True)
    if result.returncode:
        print(result.stderr[-2200:])
        sys.exit('SAFE STOP: Swift syntax check failed. No files changed.')
keyboard.write_text(a)
play.write_text(b)
print('✓ Suggested finger numbers added to blue and pink keys.')
print('✓ 1 = thumb; 5 = little finger (both hands).')
print('✓ Portrait and landscape; root dots and hand colours preserved.')
print('✓ No backup; rebuild the existing app in Xcode with ⌘R.')
