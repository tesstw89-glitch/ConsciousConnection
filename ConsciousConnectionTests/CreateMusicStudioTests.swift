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

    // ROLI_BASS_STAND_BY_ME_TESTS_V1
    func testStandByMeExactUserTabPitchesAndBars() {
        let bars = BassSongLibrary.standByMe
        XCTAssertEqual(bars.count, 8)
        XCTAssertEqual(bars.map(\.harmony), ["A", "A", "F♯m", "F♯m", "D", "E", "A", "A"])
        XCTAssertEqual(bars.map { $0.notes.count }, [4, 4, 3, 4, 4, 4, 4, 4])
        XCTAssertEqual(bars.flatMap(\.notes).count, 31)
        let pitches = bars.map { $0.notes.map(\.midi) }
        XCTAssertEqual(pitches, [
            [45, 45, 40, 44],
            [45, 45, 45, 44],
            [42, 42, 40],
            [42, 42, 42, 40],
            [38, 38, 38, 42],
            [40, 40, 40, 44],
            [45, 45, 40, 44],
            [45, 45, 40, 44]
        ])
        XCTAssertEqual(Set(bars.flatMap(\.notes).map(\.midi)), Set([38, 40, 42, 44, 45]))
    }

    func testBassTabConvertsStandardTuningNotGuitarOctaves() {
        XCTAssertEqual(BassTabNote(.lowE, 0).midi, 28)
        XCTAssertEqual(BassTabNote(.a, 0).midi, 33)
        XCTAssertEqual(BassTabNote(.d, 0).midi, 38)
        XCTAssertEqual(BassTabNote(.g, 0).midi, 43)
        XCTAssertEqual(BassTabNote(.d, 7).label, "A2")
        XCTAssertEqual(BassTabNote(.a, 5).label, "D2")
        XCTAssertEqual(BassTabNote(.d, 6).label, "G♯2")
    }
}