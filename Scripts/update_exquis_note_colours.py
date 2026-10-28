#!/usr/bin/env python3
"""Update only Exquis pad colours in an already-installed Keys Studio.

Run after fetching origin feature/exquis-board-20261027.
Keeps the existing photo calibration, pad geometry, keys, MIDI and audio untouched.
If the existing Swift code differs from the expected version, stop without writing.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
BOARD = ROOT / "ConsciousConnection/ExquisChordBoard.swift"
REPO_PATH = "ConsciousConnection/ExquisChordBoard.swift"
MARKER = "EXQUIS_PITCH_CLASS_COLOURS_V1"


def stop(message):
    sys.exit("SAFE STOP: " + message + "\nNo app files changed.")


def once(source, old, new, description):
    if source.count(old) != 1:
        stop("Unexpected existing code for " + description)
    return source.replace(old, new, 1)


def main():
    if not BOARD.is_file():
        stop("ExquisChordBoard.swift isn't installed.")
    original = BOARD.read_text(encoding="utf-8")
    if MARKER in original:
        print("Exquis note colours already installed. No changes.")
        return

    result = subprocess.run(
        ["git", "show", "FETCH_HEAD:" + REPO_PATH],
        cwd=ROOT, text=True, capture_output=True
    )
    if result.returncode or MARKER not in result.stdout:
        stop("Fetch the updated Exquis feature branch before applying the patch.")

    source = result.stdout
    start = source.index("// " + MARKER)
    end = source.index("struct ExquisChordBoard: View {", start)
    palette = source[start:end]

    updated = once(original,
        "struct ExquisChordBoard: View {",
        palette + "struct ExquisChordBoard: View {",
        "note-colour palette")
    updated = once(updated,
        '    private let mint = Color(red: 0.61, green: 0.92, blue: 0.80)\n'
        '    private let gold = Color(red: 1, green: 0.84, blue: 0.28)\n',
        "",
        "old shared colours")
    updated = once(updated,
        '''                            ExquisHexagon()
                                .fill((isRoot ? gold : mint).opacity(isRoot ? 0.90 : 0.79))
                                .overlay {
                                    ExquisHexagon()
                                        .stroke(ink.opacity(0.76),
                                                lineWidth: max(0.8, scale * 2))
                                }''',
        '''                            ExquisHexagon()
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
                                }''',
        "pitch-class overlay")
    updated = once(updated,
        '        .accessibilityLabel("Exquis chord \\(chord.symbol). Mint: chord notes. Gold: root.")',
        '        .accessibilityLabel("Exquis chord \\(chord.symbol). Each note has its own colour across octaves. White outlines show root notes.")',
        "accessibility label")

    with tempfile.TemporaryDirectory() as temp:
        candidate = Path(temp) / BOARD.name
        candidate.write_text(updated, encoding="utf-8")
        parse = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True
        )
        if parse.returncode:
            stop("Swift syntax check failed:\n" + parse.stderr[-1600:])

    BOARD.write_text(updated, encoding="utf-8")
    print("✓ Exquis pads now use 12 distinct note colours.")
    print("✓ The same note repeats its colour across every octave (E1 = E2, etc).")
    print("✓ Root notes retain a white outline.")
    print("✓ Pad alignment, photo, chords and audio were not changed.")
    print("✓ Rebuild in Xcode with Command-R.")


if __name__ == "__main__":
    main()
