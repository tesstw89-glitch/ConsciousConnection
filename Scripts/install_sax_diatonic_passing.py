#!/usr/bin/env python3
"""Add the Sax passing-tone mode by small, checked edits to the LOCAL view.

This deliberately does NOT merge or replace the whole Sax Play file: other
locally customized UI, fingerings, audio and performance controls stay as-is.
If a necessary anchor is missing, stop before any application file changes.
"""
from pathlib import Path
import os
import re
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
FILE = ROOT / "ConsciousConnection/SaxStudioPlayView.swift"
REMOTE = "ConsciousConnection/SaxStudioPlayView.swift"
MARKER = "SAX_DIATONIC_PASSING_V1"

def stop(reason):
    sys.exit("SAFE STOP: " + reason + "\nNo app files changed.")

def exactly_one(s, old, new, label):
    if s.count(old) != 1:
        stop("Cannot safely identify " + label + " in your local Sax file.")
    return s.replace(old, new, 1)

def remote_swift():
    result = subprocess.run(
        ["git", "show", "FETCH_HEAD:" + REMOTE],
        cwd=ROOT, capture_output=True, text=True
    )
    if result.returncode:
        stop("Fetch the Sax feature branch before running the installer.")
    return result.stdout

def extract(s, beginning, ending, label):
    if s.count(beginning) != 1:
        stop("Cannot read " + label + " from the approved branch.")
    start = s.index(beginning)
    if s.find(ending, start) < 0:
        stop("The approved branch does not have a complete " + label + ".")
    return s[start:s.index(ending, start)]

def inject_case(s):
    pattern = re.compile(r'(?m)^(?P<indent>[ \t]*)case chromatic = "All fingerings"$')
    hits = list(pattern.finditer(s))
    if len(hits) != 1:
        stop('Cannot locate the existing "All fingerings" sequence option.')
    hit = hits[0]
    line = hit.group(0)
    return s[:hit.start()] + line + "\n" + hit.group("indent") + 'case passing = "Passing tones"' + s[hit.end():]

def main():
    if not FILE.is_file():
        stop("SaxStudioPlayView.swift is missing. Install Sax Play first.")
    original_bytes = FILE.read_bytes()
    try:
        local = original_bytes.decode("utf-8")
    except UnicodeDecodeError:
        stop("The local Sax file is not UTF-8 text.")
    if MARKER in local:
        print("Passing tones are already installed. No changes.")
        return

    source = remote_swift()
    key_marker = "// EXQUIS-independent SAX_PASSING_KEYS_V1"
    if MARKER not in source or key_marker not in source:
        stop("The fetched source is missing the approved passing-tone exercise.")
    keys = extract(source, key_marker, "private enum SaxFingeringRate", "ten concert-key options")
    generator = extract(source,
        "    // SAX_DIATONIC_PASSING_V1",
        "    static let chromatic: [SaxPracticeNote]",
        "descending/ascending passing-tone generator"
    )
    if len(re.findall(r'(?m)^    case \w+ = "', keys)) != 10:
        stop("Expected exactly ten concert keys.")
    if "static func parse(" not in local or "private enum SaxFingeringDrills" not in local:
        stop("The current sax-fingering parser is different; no update attempted.")

    new = inject_case(local)
    new = exactly_one(
        new,
        "private enum SaxFingeringRate",
        keys + "private enum SaxFingeringRate",
        "rate picker and key definitions"
    )
    new = exactly_one(
        new,
        "    static let chromatic: [SaxPracticeNote]",
        generator + "    static let chromatic: [SaxPracticeNote]",
        "existing fingering list"
    )

    state = re.compile(
        r'(?m)^(?P<indent>[ \t]*)@State private var sequence: SaxFingeringSequence = \.\w+[ \t]*$'
    )
    found = list(state.finditer(new))
    if len(found) != 1:
        stop("Cannot identify the Sax Play fingering-sequence state.")
    hit = found[0]
    new = (new[:hit.end()] +
           "\n" + hit.group("indent") +
           "@State private var passingKey: SaxPassingKey = .bMinor" +
           new[hit.end():])

    notes_head = "    private var notes: [SaxPracticeNote] {"
    notes_intro = (
        notes_head +
        "\n        // SAX_PASSING_NOTES_ADAPTER_V1: preserve all existing practice modes.\n"
        "        if sequence == .passing {\n"
        "            let selected = SaxFingeringDrills.passingTones(passingKey)\n"
        "            return selected.isEmpty ? SaxFingeringDrills.chromatic : selected\n"
        "        }"
    )
    new = exactly_one(new, notes_head, notes_intro, "practice-note selection")

    # Add selection UI without touching other controls or layout.
    portrait_anchor = "                fingeringImage(maxHeight: 290)"
    controls = (
        '                // SAX_PASSING_KEY_PICKER_V1\n'
        '                if sequence == .passing {\n'
        '                    HStack {\n'
        '                        Text("CONCERT KEY").font(.caption.bold()).foregroundStyle(mint)\n'
        '                        Spacer()\n'
        '                        Picker("Concert key", selection: $passingKey) {\n'
        '                            ForEach(SaxPassingKey.allCases) { key in\n'
        '                                Text(key.rawValue).tag(key)\n'
        '                            }\n'
        '                        }\n'
        '                        .tint(mint)\n'
        '                    }\n'
        '                    Text("Alto written: " + passingKey.writtenKey\n'
        '                         + " · Descend to the bottom, then return to the top")\n'
        '                        .font(.caption).foregroundStyle(.white.opacity(0.72))\n'
        '                }\n\n'
    )
    new = exactly_one(new, portrait_anchor,
                      controls + portrait_anchor,
                      "portrait fingering diagram")

    # A different key must restart playback so the drill's first note is the
    # highest note in that key rather than retaining an old playhead index.
    observer = (
        '        .onChange(of: passingKey) { _, _ in restartIfPlaying() }\n'
    )
    playback_disappear = "        .onDisappear {\n            player.stop()"
    new = exactly_one(new, playback_disappear,
                      observer + playback_disappear,
                      "playback-change handler")

    # Show each full three-note group; one highlighted note at a time.
    group_property = (
        "    private var passingGroup: String {\n"
        "        guard sequence == .passing else { return \"\" }\n"
        "        let list = notes\n"
        "        let offset = (max(0, step) / 3) * 3\n"
        "        return list[offset..<min(offset + 3, list.count)]\n"
        "            .map(\\.writtenName).joined(separator: \" – \")\n"
        "    }\n"
    )
    new = exactly_one(new, "    private var current: SaxPracticeNote {",
                      group_property + "    private var current: SaxPracticeNote {",
                      "fingering indicator")

    # Integrate the name of the exercise in the existing portrait view.
    title_anchor = '                Text(lab.title).font(.title2.bold()).foregroundStyle(.white)'
    if new.count(title_anchor) == 1:
        new = new.replace(
            title_anchor,
            '                Text(sequence == .passing ? "Diatonic passing tones" : lab.title)\n'
            '                    .font(.title2.bold()).foregroundStyle(.white)',
            1
        )
    group_anchor = '                playbackButton\n\n                if let error = player.error'
    if new.count(group_anchor) == 1:
        new = new.replace(group_anchor,
            '                if sequence == .passing {\n'
            '                    Text(passingGroup)\n'
            '                        .font(.subheadline.bold()).foregroundStyle(mint)\n'
            '                }\n' + group_anchor, 1
        )
    if "SAX_PASSING_KEY_PICKER_V1" not in new or MARKER not in new:
        stop("Incomplete passing-tone installation; no file written.")

    with tempfile.TemporaryDirectory() as directory:
        candidate = Path(directory) / FILE.name
        candidate.write_text(new, encoding="utf-8")
        check = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True
        )
        if check.returncode:
            stop("Swift syntax check failed:\n" + check.stderr[-1800:])

    if FILE.read_bytes() != original_bytes:
        stop("Your Sax file was modified during the update. Run the patch again.")
    file_mode = FILE.stat().st_mode & 0o777
    descriptor, temp_path = tempfile.mkstemp(
        prefix=".SaxStudioPlay.passing.", suffix=".swift", dir=FILE.parent
    )
    try:
        os.fchmod(descriptor, file_mode)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(new.encode("utf-8"))
        if FILE.read_bytes() != original_bytes:
            stop("Your Sax file changed while installing. Run the patch again.")
        os.replace(temp_path, FILE)
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)

    print("✓ Sax passing-tone exercise added without replacing existing Sax code.")
    print("✓ Ten favourite CONCERT keys; written E-flat alto note names.")
    print("✓ Three-note overlapping groups from highest to lowest and back.")
    print("✓ Existing controls, fingerings and audio preserved.")
    print("✓ Swift syntax check passed. Rebuild in Xcode with Command-R.")

if __name__ == "__main__":
    main()
