#!/usr/bin/env python3
"""Install the ROLI Bass Studio into a working ConsciousConnection checkout.

Run from repository root after:
    git fetch origin feature/roli-bass-stand-by-me-20261028
    git show FETCH_HEAD:Scripts/install_roli_bass_stand_by_me.py | python3

Unlike replacing the whole Swift file, this inserts only the feature and
picker link. Existing local sax, Exquis, and other studio changes survive.
"""
from pathlib import Path
import datetime
import subprocess
import sys

def git(*args):
    return subprocess.check_output(["git", *args], text=True)

def main():
    root = Path(git("rev-parse", "--show-toplevel").strip())
    main_file = root / "ConsciousConnection" / "CreateMusicStudioView.swift"
    test_file = root / "ConsciousConnectionTests" / "CreateMusicStudioTests.swift"
    if not main_file.is_file():
        sys.exit("Cannot find ConsciousConnection/CreateMusicStudioView.swift")
    try:
        branch_source = git("show", "FETCH_HEAD:ConsciousConnection/CreateMusicStudioView.swift")
        branch_tests = git("show", "FETCH_HEAD:ConsciousConnectionTests/CreateMusicStudioTests.swift")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"FETCH_HEAD does not contain this feature: {exc}")

    begin = "// MARK: - ROLI bass song studio"
    end = "// ROLI_BASS_STAND_BY_ME_END_V1"
    if begin not in branch_source or end not in branch_source:
        sys.exit("Fetched branch is missing the Bass Studio implementation.")
    feature = branch_source[branch_source.index(begin):branch_source.index(end) + len(end)]

    src = main_file.read_text(encoding="utf-8")
    new_src = src

    if "// ROLI_BASS_STUDIO_LINK_V1" not in new_src:
        link_anchor = 'destination: MusicLabListView(instrument: "keys"))'
        if link_anchor not in new_src:
            sys.exit("Cannot locate Keys Studio navigation link; no changes made.")
        link = '''\n                // ROLI_BASS_STUDIO_LINK_V1
                StudioLink(title: "Bass Studio · ROLI Block",
                           subtitle: "1 song · notes translated from bass tab",
                           icon: "music.note.list", destination: BassStudioLibraryView())'''
        new_src = new_src.replace(link_anchor, link_anchor + link, 1)

    if "// ROLI_BASS_STAND_BY_ME_V1" not in new_src:
        new_src = new_src.rstrip() + "\n\n" + feature + "\n"

    if "import AVFoundation" not in new_src:
        if "import SwiftUI\n" not in new_src:
            sys.exit("Cannot locate SwiftUI import; no changes made.")
        new_src = new_src.replace("import SwiftUI\n", "import SwiftUI\nimport AVFoundation\n", 1)

    if new_src != src:
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = main_file.with_name(main_file.name + f".before-roli-bass-{stamp}.bak")
        backup.write_text(src, encoding="utf-8")
        main_file.write_text(new_src, encoding="utf-8")
        print(f"Installed Bass Studio; original backed up to {backup.name}")
    else:
        print("Bass Studio is already installed; source unchanged.")

    if test_file.is_file():
        original_tests = test_file.read_text(encoding="utf-8")
        test_marker = "// ROLI_BASS_STAND_BY_ME_TESTS_V1"
        if test_marker not in original_tests:
            test_start = branch_tests.find(test_marker)
            test_end = branch_tests.rfind("}")
            local_end = original_tests.rfind("}")
            if min(test_start, test_end, local_end) < 0:
                print("Tests could not be merged; app code was still installed.")
            else:
                tests_to_insert = branch_tests[test_start:test_end].rstrip()
                test_file.write_text(
                    original_tests[:local_end].rstrip() + "\n\n    " +
                    tests_to_insert + "\n" + original_tests[local_end:],
                    encoding="utf-8"
                )
                print("Added bass tab and MIDI conversion tests.")
        else:
            print("Bass Studio tests already installed.")

    print("Open Xcode, build, then Create → Practice an instrument → Bass Studio → Stand by Me.")

if __name__ == "__main__":
    main()
