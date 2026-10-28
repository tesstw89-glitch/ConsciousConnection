#!/usr/bin/env python3
"""Safely put octave-free note labels on the installed 61-pad Exquis board.

Apply to the already-coloured Exquis Swift file. Only the note-colour helper,
pad overlay and accessibility description are changed. Calibration/photo,
other app features, sound and MIDI are left untouched.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
BOARD = ROOT / "ConsciousConnection/ExquisChordBoard.swift"
REPO_PATH = "ConsciousConnection/ExquisChordBoard.swift"
BASE_COMMIT = "60e7f5a83f3217a732305618bcdc8ea83d5e6e1f"
MARKER = "EXQUIS_PAD_NOTE_LABELS_V1"


def stop(message):
    sys.exit("SAFE STOP: " + message + "\nNo app files changed.")


def git_file(ref):
    proc = subprocess.run(
        ["git", "show", ref + ":" + REPO_PATH],
        cwd=ROOT, capture_output=True, text=True
    )
    if proc.returncode:
        stop("Cannot read Exquis from git ref " + ref + ". Fetch the feature branch.")
    return proc.stdout


def replace_once(source, old, new, label):
    if source.count(old) != 1:
        stop("Unexpected installed Exquis source at " + label)
    return source.replace(old, new, 1)


def pad_block(source, new=False):
    if new:
        begin = source.index("                    // EXQUIS_PAD_NOTE_LABELS_V1")
    else:
        begin = source.index("                    ForEach(ExquisLayout.pads) { pad in")
    finish = source.index(
        "\n                }\n                .frame(width: w, height: h)", begin
    )
    # This is the ForEach's closing brace, immediately before the ZStack closes.
    return source[begin:finish]


def accessibility_line(source):
    matches = [
        line for line in source.splitlines()
        if line.lstrip().startswith('.accessibilityLabel("Exquis chord')
    ]
    if len(matches) != 1:
        stop("Expected one Exquis accessibility description.")
    return matches[0]


def main():
    if not BOARD.is_file():
        stop("ExquisChordBoard.swift not installed.")
    existing = BOARD.read_text(encoding="utf-8")
    if MARKER in existing:
        print("Exquis note names already installed. No changes.")
        return
    if "EXQUIS_PITCH_CLASS_COLOURS_V1" not in existing:
        stop("Install the Exquis 12-note colour update before note labels.")

    old = git_file(BASE_COMMIT)
    new = git_file("FETCH_HEAD")
    if "EXQUIS_PITCH_CLASS_NOTE_NAMES_V1" not in new or MARKER not in new:
        stop("Fetched feature branch does not contain the note-name patch.")

    original_tail = (
        "    static func colour(for pitchClass: Int) -> Color {\n"
        "        chromatic[((pitchClass % 12) + 12) % 12]\n"
        "    }\n}"
    )
    marker_pos = new.index("    // EXQUIS_PITCH_CLASS_NOTE_NAMES_V1")
    end_pos = new.index("\n}\n\nstruct ExquisChordBoard: View {", marker_pos)
    helpers = new[marker_pos:end_pos]
    updated = replace_once(
        existing, original_tail,
        original_tail[:-1] + "\n\n" + helpers + "\n}",
        "pitch-class names"
    )
    updated = replace_once(
        updated, pad_block(old), pad_block(new, new=True),
        "61-pad overlay"
    )
    updated = replace_once(
        updated, accessibility_line(old), accessibility_line(new),
        "accessibility label"
    )

    with tempfile.TemporaryDirectory() as directory:
        candidate = Path(directory) / BOARD.name
        candidate.write_text(updated, encoding="utf-8")
        check = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True
        )
        if check.returncode:
            stop("Swift syntax check failed:\n" + check.stderr[-1800:])

    BOARD.write_text(updated, encoding="utf-8")
    print("✓ Added note names on all 61 Exquis pads, ignoring octave.")
    print("✓ Note colours and root outlines preserved.")
    print("✓ Existing photo alignment, MIDI, audio and other screens untouched.")
    print("✓ Rebuild in Xcode with Command-R.")


if __name__ == "__main__":
    main()
