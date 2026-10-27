import XCTest
@testable import ConsciousConnection

final class CreateMusicStudioTests: XCTestCase {
    func testFullSourceCatalogLoads() {
        let labs = MusicLabLibrary.all
        XCTAssertEqual(labs.filter { $0.instrument == "keys" }.count, 19)
        XCTAssertEqual(labs.filter { $0.instrument == "sax" }.count, 22)
        XCTAssertTrue(labs.allSatisfy { $0.steps.count == 5 })
    }

    func testBMinorNineHighlightsOnlyItsActualPitches() {
        let chord = MusicChord(symbol: "Bm9", bars: 2,
                               notes: ["B", "D", "F♯", "A", "C♯"])
        let shape = ChordVoicing.positions(for: chord, rootless: false, inversion: 0)
        XCTAssertEqual(shape.map(\.midi), [59, 62, 66, 69, 73])
        XCTAssertEqual(shape.map(\.label), ["B3", "D4", "F♯4", "A4", "C♯5"])
    }

    func testFlatNineAndEnharmonicWhiteKey() {
        let chord = MusicChord(symbol: "C♯7(♭9)", bars: 4,
                               notes: ["C♯", "E♯", "G♯", "B", "D"])
        let shape = ChordVoicing.positions(for: chord, rootless: false, inversion: 0)
        XCTAssertEqual(Set(shape.map { $0.midi % 12 }), Set([1, 5, 8, 11, 2]))
        XCTAssertTrue(shape.allSatisfy { (48...84).contains($0.midi) })
    }

    func testSlashChordDoesNotForceTheBassIntoKeyboardShape() {
        let chord = MusicChord(symbol: "B/A", bars: 2,
                               notes: ["B", "D♯", "F♯"])
        let shape = ChordVoicing.positions(for: chord, rootless: false, inversion: 0)
        XCTAssertEqual(Set(shape.map { $0.midi % 12 }), Set([11, 3, 6]))
        XCTAssertFalse(shape.contains { $0.midi % 12 == 9 })
    }

    func testRootlessChordLeavesTheBassRootToTheTrack() {
        let chord = MusicChord(symbol: "Gm9", bars: 2,
                               notes: ["G", "B♭", "D", "F", "A"])
        let shape = ChordVoicing.positions(for: chord, rootless: true, inversion: 0)
        XCTAssertEqual(shape.map(\.label), ["B♭4", "D5", "F5", "A5"])
        XCTAssertFalse(shape.contains { $0.midi % 12 == 7 })
    }

    func testAllKeysStudioChordsStayOnTheMinilogue() {
        for lab in MusicLabLibrary.all where lab.instrument == "keys" {
            for chord in lab.chords {
                for rootless in [false, true] {
                    let notes = ChordVoicing.positions(for: chord, rootless: rootless, inversion: 0)
                    XCTAssertFalse(notes.isEmpty, "\(lab.title): \(chord.symbol)")
                    XCTAssertTrue(notes.allSatisfy { (48...84).contains($0.midi) },
                                  "\(lab.title): \(chord.symbol)")
                }
            }
        }
    }
}