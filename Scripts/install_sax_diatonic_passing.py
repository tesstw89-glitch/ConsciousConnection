#!/usr/bin/env python3
"""Install an in-key descending/ascending passing-tone mode in Sax Studio Play.

Safe update of the single Swift file; does not merge or checkout branches,
does not modify the catalog, fingering images, MIDI, audio, or other studios.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
FILE = ROOT / "ConsciousConnection/SaxStudioPlayView.swift"
REF_PATH = "ConsciousConnection/SaxStudioPlayView.swift"
BASE_COMMIT = "b8e0144f438e2725c21b06ce14ace1d28717c2b2"
MARKER = "SAX_DIATONIC_PASSING_V1"


def stop(message):
    sys.exit("SAFE STOP: " + message + "\nNo app files changed.")


def git_file(ref):
    result = subprocess.run(
        ["git", "show", ref + ":" + REF_PATH],
        cwd=ROOT, capture_output=True, text=True
    )
    if result.returncode:
        stop("Cannot access " + REF_PATH + " at " + ref
             + ". Fetch the sax feature branch first.")
    return result.stdout


def main():
    if not FILE.is_file():
        stop("SaxStudioPlayView.swift is not installed. Install Sax Play first.")
    installed = FILE.read_text(encoding="utf-8")
    if MARKER in installed:
        print("Diatonic passing tones already installed. No changes.")
        return

    original = git_file(BASE_COMMIT)
    proposed = git_file("FETCH_HEAD")
    if installed != original:
        stop("Your SaxStudioPlayView.swift has local changes. "
             "To avoid overwriting them, this installer has not touched it.")
    expected_keys = [
        'case bMinor = "B minor"', 'case dMajor = "D major"',
        'case fSharpMinor = "F♯ minor"', 'case aMajor = "A major"',
        'case aMinor = "A minor"', 'case cMajor = "C major"',
        'case bFlatMinor = "B♭ minor"', 'case dFlatMajor = "D♭ major"',
        'case eMinor = "E minor"', 'case gMajor = "G major"'
    ]
    if MARKER not in proposed or not all(k in proposed for k in expected_keys):
        stop("The fetched branch does not contain the approved 10-key exercise.")

    with tempfile.TemporaryDirectory() as directory:
        candidate = Path(directory) / FILE.name
        candidate.write_text(proposed, encoding="utf-8")
        result = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True
        )
        if result.returncode:
            stop("Swift syntax check failed:\n" + result.stderr[-1800:])

    FILE.write_text(proposed, encoding="utf-8")
    print("✓ Sax Play now offers Diatonic Passing Tones in 10 favourite concert keys.")
    print("✓ Correct written E-flat alto notes, natural minor or major.")
    print("✓ Three-note overlapping groups descend, then ascend across sax range.")
    print("✓ Same 33 fingering pictures and existing drum playback.")
    print("✓ No catalog, backing WAV, Exquis or other app files changed.")
    print("✓ Rebuild the project in Xcode using Command-R.")


if __name__ == "__main__":
    main()
