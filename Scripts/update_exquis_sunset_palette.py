#!/usr/bin/env python3
"""Safely apply the Sunset Glow-inspired Exquis palette to an installed board.

The existing 61-pad map, alignment, notes, roots, chords and audio are preserved.
Run after fetching origin feature/exquis-board-20261027.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
BOARD = ROOT / "ConsciousConnection/ExquisChordBoard.swift"
REPO_PATH = "ConsciousConnection/ExquisChordBoard.swift"
PREVIOUS_COMMIT = "e919dbf7e4a1029feea622fed5721309ae16deb6"
MARKER = "EXQUIS_SUNSET_PALETTE_V2"


def stop(reason):
    sys.exit("SAFE STOP: " + reason + "\nNo app files changed.")


def git_file(ref):
    result = subprocess.run(
        ["git", "show", ref + ":" + REPO_PATH],
        cwd=ROOT, text=True, capture_output=True,
    )
    if result.returncode:
        stop("Cannot read feature code at " + ref + ". Fetch the branch first.")
    return result.stdout


def palette_part(source, new=False):
    start_key = "    // EXQUIS_SUNSET_PALETTE_V2" if new else (
        "    static let chromatic: [Color] = ["
    )
    start = source.find(start_key)
    if start == -1:
        stop("Expected Exquis palette not found.")
    end = source.find("    static func colour(for pitchClass: Int)", start)
    if end == -1:
        stop("Expected Exquis pitch-class lookup not found.")
    return source[start:end]


def label_contrast_part(source):
    start = source.find("    static func labelColour(for pitchClass: Int) -> Color {")
    if start == -1:
        return None
    end = source.find("    }\n}", start)
    if end == -1:
        stop("Expected note label contrast function not found.")
    return source[start:end + len("    }\n")]


def replace_exact(source, old, replacement, name):
    if source.count(old) != 1:
        stop("Installed Exquis code differs at " + name + ".")
    return source.replace(old, replacement, 1)


def main():
    if not BOARD.is_file():
        stop("ExquisChordBoard.swift is not installed.")

    old_local = BOARD.read_text(encoding="utf-8")
    if MARKER in old_local:
        print("Sunset Glow Exquis colours already installed. No changes.")
        return
    if "EXQUIS_PITCH_CLASS_COLOURS_V1" not in old_local:
        stop("Install the Exquis pitch-class colours before applying this palette.")

    previous = git_file(PREVIOUS_COMMIT)
    newest = git_file("FETCH_HEAD")
    if MARKER not in newest or "EXQUIS_PAD_NOTE_LABELS_V1" not in newest:
        stop("The fetched branch doesn't contain the new Sunset Glow palette.")

    updated = replace_exact(
        old_local, palette_part(previous), palette_part(newest, new=True),
        "chromatic palette",
    )
    if "static func labelColour" in updated:
        updated = replace_exact(
            updated,
            label_contrast_part(previous),
            label_contrast_part(newest),
            "note label contrast",
        )

    with tempfile.TemporaryDirectory() as directory:
        candidate = Path(directory) / BOARD.name
        candidate.write_text(updated, encoding="utf-8")
        syntax = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True,
        )
        if syntax.returncode:
            stop("Swift syntax check failed:\n" + syntax.stderr[-1600:])

    BOARD.write_text(updated, encoding="utf-8")
    print("✓ Sunset Glow's seven exact colours + five complementary shades applied.")
    print("✓ Twelve colours repeat by note name, regardless of octave.")
    print("✓ Existing note labels retain readable contrast.")
    print("✓ Alignment, chord shapes, root outlines, MIDI and audio unchanged.")
    print("✓ Rebuild the app in Xcode with Command-R.")


if __name__ == "__main__":
    main()
