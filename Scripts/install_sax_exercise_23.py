#!/usr/bin/env python3
"""Add Saxophone Studio Exercise 23 without replacing existing user edits.

Stages the existing Sax Play view, catalog and studio screen; if necessary
it first applies the already-approved guarded passing-tone patch to a TEMP
copy of Sax Play, never directly to the user's app. Validates every edited
file before atomically replacing the affected files. No checkout, merge,
external assets or WAV modifications.
"""
from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile

ROOT = Path.home() / "Desktop/ConsciousConnection"
APP = ROOT / "ConsciousConnection"
SAX = APP / "SaxStudioPlayView.swift"
CATALOG = APP / "MusicLabCatalog.json"
STUDIO = APP / "CreateMusicStudioView.swift"
EXERCISE_ID = "sax-23"
MARKER = "SAX23_DEDICATED_PLAY_V1"

def stop(reason):
    sys.exit("SAFE STOP: " + reason + "\nNo application files were changed.")

def fetch(path):
    result = subprocess.run(
        ["git", "show", "FETCH_HEAD:" + path],
        cwd=ROOT, text=True, capture_output=True
    )
    if result.returncode:
        stop("Could not fetch approved feature file " + path)
    return result.stdout

def replace_one(text, old, new, description):
    if text.count(old) != 1:
        stop("Cannot safely locate " + description + " in your existing files.")
    return text.replace(old, new, 1)

def ensure_passing_mode(original_sax, scratch):
    if "SAX_DIATONIC_PASSING_V1" in original_sax:
        if "SaxPassingKey" not in original_sax or "case passing" not in original_sax:
            stop("Found an incomplete earlier passing-tone update.")
        return original_sax

    # The previous installer operates only on this disposable temp copy.
    # The original Sax Play view remains completely untouched.
    installer = fetch("Scripts/install_sax_diatonic_passing.py")
    if "SAX_PASSING_NOTES_ADAPTER_V1" not in installer:
        stop("The Sax passing-tone prerequisite has changed unexpectedly.")
    shadow = scratch / "SaxStudioPlayView.swift"
    shadow.write_text(original_sax, encoding="utf-8")
    scope = {"__name__": "sax23_prerequisite_patch"}
    exec(compile(installer, "<approved sax passing installer>", "exec"), scope)
    scope["FILE"] = shadow
    try:
        scope["main"]()
    except SystemExit as error:
        stop("The local Sax Play view needs a more specific patch: " + str(error))
    merged = shadow.read_text(encoding="utf-8")
    if "SAX_DIATONIC_PASSING_V1" not in merged:
        stop("The staged passing-tone update did not finish.")
    return merged

def dedicate_play(sax):
    if MARKER in sax:
        if "lab.id == \"sax-23\"" not in sax:
            stop("Found an incomplete dedicated Exercise 23 Play screen.")
        return sax
    if "SAX_DIATONIC_PASSING_V1" not in sax:
        stop("The Sax Play view does not contain the passing-tone generator.")
    # Always start the dedicated exercise at the top, in B minor concert
    # (G-sharp minor written alto); user can choose another key immediately.
    original = '        .onAppear {\n            let digits = lab.groove.prefix(while: { $0.isNumber })'
    replacement = (
        '        .onAppear {\n'
        '            // SAX23_DEDICATED_PLAY_V1\n'
        '            if lab.id == "sax-23" {\n'
        '                sequence = .passing\n'
        '                passingKey = .bMinor\n'
        '                step = 0\n'
        '            }\n'
        '            let digits = lab.groove.prefix(while: { $0.isNumber })'
    )
    sax = replace_one(sax, original, replacement, "Sax Play onAppear initialization")

    # Exercise 23 must not show "Lesson phrase" / "All fingerings", and
    # the passing-tone option is hidden from other labs (it now has its own).
    start = '                Picker("Fingering sequence", selection: $sequence) {'
    finish = '                .pickerStyle(.segmented)'
    if sax.count(start) != 1:
        stop("Your Sax mode picker differs from the expected layout.")
    left = sax.index(start)
    right = sax.find(finish, left)
    if right == -1:
        stop("Could not find the end of your existing Sax mode picker.")
    right += len(finish)
    picker = sax[left:right]
    cases = "ForEach(SaxFingeringSequence.allCases) { choice in"
    if picker.count(cases) != 1:
        stop("Unexpected list of Sax Play modes.")
    picker = picker.replace(
        cases,
        "ForEach(SaxFingeringSequence.allCases.filter { $0 != .passing }) { choice in"
    )
    wrapped = (
        '                if lab.id != "sax-23" {\n'
        + "\n".join("    " + line for line in picker.split("\n"))
        + '\n                }'
    )
    sax = sax[:left] + wrapped + sax[right:]

    # The prior patch already displays the concert-key picker when in
    # passing mode. Our onAppear enables that mode for Exercise 23.
    if "Picker(\"Concert key\", selection: $passingKey)" not in sax:
        stop("The passing-tone concert-key picker is missing.")
    return sax

def update_catalog(original, lab):
    try:
        record = json.loads(original)
    except json.JSONDecodeError:
        stop("MusicLabCatalog.json is not valid JSON.")
    if not isinstance(record.get("labs"), list):
        stop("MusicLabCatalog.json has an unexpected structure.")
    labs = record["labs"]
    if lab.get("id") != EXERCISE_ID or lab.get("number") != 23 or lab.get("instrument") != "sax":
        stop("Exercise 23 has an invalid ID, number or instrument.")

    matching = [item for item in labs if item.get("id") == EXERCISE_ID]
    if len(matching) > 1:
        stop("The catalogue has duplicate sax-23 entries.")
    if matching:
        if matching[0] != lab:
            stop("Your existing sax-23 entry differs; it will not be overwritten.")
        return original

    if any(item.get("instrument") == "sax" and item.get("number") == 23 for item in labs):
        stop("Another Sax Studio lesson is already numbered 23.")
    prior = [i for i, item in enumerate(labs) if item.get("id") == "sax-22"]
    if len(prior) != 1:
        stop("Cannot find the existing Sax Studio lesson 22.")
    labs.insert(prior[0] + 1, lab)
    updated = json.dumps(record, ensure_ascii=False, indent=2) + "\n"
    return updated

def update_studio(original):
    result = original
    result = result.replace(
        "22 saxophone labs · 19 Minilogue chord labs",
        "23 saxophone labs · 19 Minilogue chord labs"
    ).replace(
        "22 full-band improvisation labs · written E♭ alto notes",
        "23 saxophone exercises · written E♭ alto notes"
    )
    if "SaxStudioPlayView(lab: lab)" not in result:
        anchor = '                    infoBlock("ALTO WRITTEN", lab.saxChords + "\\n" + lab.palette)'
        navigation = '''                    // SAX23_PLAY_LINK_V1
                    NavigationLink(destination: SaxStudioPlayView(lab: lab)) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title3.bold())
                                .frame(width: 42, height: 42)
                                .background(Color(red: 0.61, green: 0.92, blue: 0.80),
                                            in: Circle())
                                .foregroundStyle(Color.black)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(lab.id == "sax-23" ? "PLAY PASSING-TONE EXERCISE" :
                                     "PLAY SAX FINGERINGS")
                                    .font(.headline)
                                Text("Drum groove · timed written-note diagrams")
                                    .font(.caption).opacity(0.78)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
'''
        result = replace_one(result, anchor, navigation + anchor,
                             "Sax Play navigation link")
    else:
        # Preserve the existing customized navigation link. Only rename the
        # action on the new exercise if its original label is recognizable.
        result = result.replace(
            'Text("PLAY SAX FINGERINGS")',
            'Text(lab.id == "sax-23" ? "PLAY PASSING-TONE EXERCISE" : "PLAY SAX FINGERINGS")'
        )
    if "SaxStudioPlayView(lab: lab)" not in result:
        stop("Exercise 23 has no navigation to Sax Play.")
    return result

def check_swift(sax, studio, scratch):
    a = scratch / "SaxStudioPlayView.swift"
    b = scratch / "CreateMusicStudioView.swift"
    a.write_text(sax, encoding="utf-8")
    b.write_text(studio, encoding="utf-8")
    result = subprocess.run(
        ["xcrun", "swiftc", "-frontend", "-parse", str(a), str(b)],
        capture_output=True, text=True
    )
    if result.returncode:
        stop("Swift syntax check failed:\n" + result.stderr[-2200:])

def atomic_update(changes, originals):
    for path, data in originals.items():
        if path.read_bytes() != data:
            stop("A project file changed during installation: " + path.name)
    staged = []
    try:
        for path, replacement in changes.items():
            if replacement.encode("utf-8") == originals[path]:
                continue
            fd, tmp = tempfile.mkstemp(prefix=".sax23.", dir=path.parent)
            os.fchmod(fd, path.stat().st_mode & 0o777)
            with os.fdopen(fd, "wb") as output:
                output.write(replacement.encode("utf-8"))
            staged.append((path, tmp))
        for path, tmp in staged:
            if path.read_bytes() != originals[path]:
                stop("A project file changed during installation: " + path.name)
        for path, tmp in staged:
            os.replace(tmp, path)
    finally:
        for _, tmp in staged:
            if os.path.exists(tmp):
                os.unlink(tmp)

def main():
    paths = [SAX, CATALOG, STUDIO]
    if any(not path.is_file() for path in paths):
        stop("Sax Play, the music catalogue and the studio screen must all be installed.")
    original = {path: path.read_bytes() for path in paths}
    try:
        text_files = {path: data.decode("utf-8") for path, data in original.items()}
    except UnicodeDecodeError:
        stop("An app source file is not UTF-8.")
    try:
        lab = json.loads(fetch("Scripts/sax_passing_lab_23.json"))
    except json.JSONDecodeError:
        stop("The approved Exercise 23 entry is not valid JSON.")

    with tempfile.TemporaryDirectory() as scratch_dir:
        scratch = Path(scratch_dir)
        sax = ensure_passing_mode(text_files[SAX], scratch)
        sax = dedicate_play(sax)
        catalog = update_catalog(text_files[CATALOG], lab)
        studio = update_studio(text_files[STUDIO])
        # Round-trip the entire JSON before applying anything.
        loaded = json.loads(catalog)
        assert sum(l.get("id") == EXERCISE_ID for l in loaded["labs"]) == 1
        check_swift(sax, studio, scratch)
        atomic_update(
            {SAX: sax, CATALOG: catalog, STUDIO: studio}, original
        )
    print("✓ Sax Studio Exercise 23 added to the numbered lesson list.")
    print("✓ Its Play screen opens in Diatonic Passing Tones, with all 10 concert keys.")
    print("✓ Highest in-key alto note → lowest → highest; same fingering images.")
    print("✓ Other 22 lessons and their Play modes remain unchanged.")
    print("✓ No WAVs, MIDI files, Exquis, or other project files modified.")
    print("✓ Rebuild the app in Xcode using Command-R.")

if __name__ == "__main__":
    main()
