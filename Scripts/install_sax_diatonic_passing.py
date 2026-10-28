#!/usr/bin/env python3
"""Safely add the 10-key Sax Studio passing-tone exercise while preserving local work.

Uses a three-way text merge (current local file, original Sax Play file, new
passing-tone file). If modifications overlap or the Swift syntax check fails,
stop without touching the installed file. No Git checkout, branch merge,
backups, WAV changes, MIDI changes, or other app-file changes.
"""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
FILE = ROOT / "ConsciousConnection/SaxStudioPlayView.swift"
REPO_PATH = "ConsciousConnection/SaxStudioPlayView.swift"
BASE_COMMIT = "b8e0144f438e2725c21b06ce14ace1d28717c2b2"
MARKER = "SAX_DIATONIC_PASSING_V1"

EXPECTED_KEYS = [
    'case bMinor = "B minor"', 'case dMajor = "D major"',
    'case fSharpMinor = "F♯ minor"', 'case aMajor = "A major"',
    'case aMinor = "A minor"', 'case cMajor = "C major"',
    'case bFlatMinor = "B♭ minor"', 'case dFlatMajor = "D♭ major"',
    'case eMinor = "E minor"', 'case gMajor = "G major"',
]


def stop(message):
    sys.exit("SAFE STOP: " + message + "\nYour application files were not changed.")


def git_file(ref):
    result = subprocess.run(
        ["git", "show", ref + ":" + REPO_PATH],
        cwd=ROOT, capture_output=True, text=True
    )
    if result.returncode:
        stop("Could not read the Sax feature source at " + ref
             + ". Fetch the feature branch first.")
    return result.stdout


def main():
    if not FILE.is_file():
        stop("SaxStudioPlayView.swift is missing. Install Sax Play first.")

    original_bytes = FILE.read_bytes()
    try:
        installed = original_bytes.decode("utf-8")
    except UnicodeDecodeError:
        stop("The installed Sax Play file is not UTF-8.")

    if MARKER in installed:
        print("The passing-tone exercise is already present. No changes needed.")
        return

    baseline = git_file(BASE_COMMIT)
    proposed = git_file("FETCH_HEAD")
    if MARKER not in proposed or not all(k in proposed for k in EXPECTED_KEYS):
        stop("FETCH_HEAD does not contain the approved ten-key passing-tone exercise.")
    for token in (
        "private enum SaxFingeringSequence",
        "private enum SaxFingeringDrills",
        "struct SaxStudioPlayView",
        "private func fingeringImage",
    ):
        if token not in installed:
            stop("Your Sax Play layout has changed too much for a safe merge: "
                 + token)

    with tempfile.TemporaryDirectory() as directory:
        temp = Path(directory)
        local = temp / "installed.swift"
        base = temp / "original.swift"
        incoming = temp / "passing.swift"
        local.write_text(installed, encoding="utf-8")
        base.write_text(baseline, encoding="utf-8")
        incoming.write_text(proposed, encoding="utf-8")

        merge = subprocess.run(
            ["git", "merge-file", "-p", str(local), str(base), str(incoming)],
            capture_output=True, text=True
        )
        if merge.returncode != 0:
            if merge.returncode == 1:
                stop("Your local Sax edits overlap the new exercise in at least "
                     "one place. A clean merge isn't possible automatically. "
                     "Nothing was overwritten. Please share a git diff of "
                     "ConsciousConnection/SaxStudioPlayView.swift so I can "
                     "make a targeted patch.")
            stop("Git could not perform the safety merge:\n" + merge.stderr[-800:])

        merged = merge.stdout
        if not merged or MARKER not in merged or any(
            key not in merged for key in EXPECTED_KEYS
        ):
            stop("The merged Sax file didn't contain all of the approved exercise.")
        if "<<<<<<<" in merged or ">>>>>>>" in merged:
            stop("Unexpected conflict markers in the merged file.")

        candidate = temp / "validated.swift"
        candidate.write_text(merged, encoding="utf-8")
        syntax = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True
        )
        if syntax.returncode:
            stop("The combined Swift file did not pass the syntax check:\n"
                 + syntax.stderr[-1800:])

        if FILE.read_bytes() != original_bytes:
            stop("Your local Sax file changed during validation. Please rerun.")

        # Atomic replacement only after clean merge + validation.
        fd, temp_name = tempfile.mkstemp(
            prefix=".SaxStudioPlay.passing.", suffix=".swift", dir=FILE.parent
        )
        try:
            os.fchmod(fd, FILE.stat().st_mode & 0o777)
            with os.fdopen(fd, "wb") as destination:
                destination.write(merged.encode("utf-8"))
            if FILE.read_bytes() != original_bytes:
                stop("Your local Sax file changed during installation. Please rerun.")
            os.replace(temp_name, FILE)
        finally:
            if os.path.exists(temp_name):
                os.unlink(temp_name)

    print("✓ Passing tones installed with your non-conflicting local Sax changes kept.")
    print("✓ All 10 concert keys, transposed for written E-flat alto.")
    print("✓ Three-note in-key groups: highest → lowest → highest playable note.")
    print("✓ Existing fingering diagrams, WAVs and other app files untouched.")
    print("✓ Rebuild in Xcode with Command-R.")


if __name__ == "__main__":
    main()
