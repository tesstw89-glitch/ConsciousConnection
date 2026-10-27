#!/usr/bin/env python3
"""Install Sax Studio Play mode into Desktop ConsciousConnection.
One-paste fetch installer. Never merges, switches branches, creates backups,
or overwrites unrelated local work. Requires the user's 33 original PNGs.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

PROJECT = Path.home() / "Desktop/ConsciousConnection"
APP = PROJECT / "ConsciousConnection"
CATALOGUE_SCREEN = APP / "CreateMusicStudioView.swift"
SAX_PLAY = APP / "SaxStudioPlayView.swift"
ASSETS = APP / "Assets.xcassets"


def safe_stop(message):
    raise SystemExit("SAFE STOP: " + message + "\nNo application files changed.")


def branch_source(path):
    result = subprocess.run(
        ["git", "show", "FETCH_HEAD:" + path],
        cwd=PROJECT, capture_output=True
    )
    if result.returncode:
        safe_stop("Couldn't retrieve approved feature file " + path)
    return result.stdout


def all_images(folder):
    return folder.is_dir() and all(
        (folder / f"{number:03d}.png").is_file()
        for number in range(58, 91)
    )


def find_png_directory():
    candidates = []
    for home_dir in ("Downloads", "Desktop"):
        base = Path.home() / home_dir
        if not base.is_dir():
            continue
        nearby = [base] + list(base.glob("*")) + list(base.glob("*/*"))
        for path in nearby:
            if all_images(path) and path not in candidates:
                candidates.append(path)
    if len(candidates) == 1:
        print("Found 33 fingering PNGs in:", candidates[0])
        return candidates[0]
    print("Choose the folder containing 058.png through 090.png.")
    script = 'POSIX path of (choose folder with prompt "Select the folder containing all 33 alto sax fingering PNGs")'
    result = subprocess.run(
        ["osascript", "-e", script], text=True, capture_output=True
    )
    if result.returncode != 0 or not result.stdout.strip():
        safe_stop("Folder selection was cancelled. Put the images in ~/Downloads/SaxFingerings and rerun.")
    folder = Path(result.stdout.strip()).expanduser()
    if not all_images(folder):
        missing = [f"{n:03d}.png" for n in range(58, 91)
                   if not (folder / f"{n:03d}.png").is_file()]
        safe_stop("Selected folder is missing: " + ", ".join(missing))
    return folder


def main():
    if not CATALOGUE_SCREEN.is_file() or not ASSETS.is_dir():
        safe_stop("Expected ConsciousConnection Desktop project not found.")
    original = CATALOGUE_SCREEN.read_text()
    if not original.count('infoBlock("ALTO WRITTEN",'):
        safe_stop("This project does not yet have the expected Sax Studio lab screen.")
    if not (APP / "KeysStudioPlayView.swift").is_file():
        safe_stop("The shared Keys Studio drum WAV player is not installed.")
    new_swift = branch_source("ConsciousConnection/SaxStudioPlayView.swift")

    needle = '                    infoBlock("ALTO WRITTEN", lab.saxChords + "\\n" + lab.palette)'
    navigation = """                    NavigationLink(destination: SaxStudioPlayView(lab: lab)) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title3.bold())
                                .frame(width: 42, height: 42)
                                .background(
                                    Color(red: 0.61, green: 0.92, blue: 0.80),
                                    in: Circle()
                                )
                                .foregroundStyle(Color.black)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("PLAY SAX FINGERINGS")
                                    .font(.headline)
                                Text("Drum groove · timed written-note diagrams")
                                    .font(.caption)
                                    .opacity(0.78)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            .white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)
"""
    if original.count(needle) == 1:
        edited = original.replace(needle, navigation + needle, 1)
    elif "SaxStudioPlayView(lab: lab)" in original:
        edited = original
        print("Existing Sax Play link found; preserving it.")
    else:
        safe_stop("Unexpected Sax Studio lesson layout. Refusing to edit it.")

    if SAX_PLAY.exists() and SAX_PLAY.read_bytes() != new_swift:
        safe_stop("Existing SaxStudioPlayView.swift differs. It was not overwritten.")

    # Make sure the existing global X can be suppressed during sax performance.
    app_entry = APP / "ConsciousConnectionApp.swift"
    if not app_entry.is_file() or "KeysStudioPerformanceVisibility" not in app_entry.read_text():
        safe_stop("Landscape global-back-button fix is missing. Tell me; I'll supply a targeted patch.")

    wavs = [APP / f"KeysGroove_{meter}_{tempo}.wav"
            for meter in ("4_4", "5_4", "6_8")
            for tempo in (70, 80, 90, 100, 110, 120, 130, 140)]
    if any(not p.is_file() for p in wavs):
        safe_stop("Missing Keys Studio WAVs. Sax Play uses those same 24 drum WAVs.")

    folder = find_png_directory()
    payload = {}
    metadata = json.dumps(
        {"images": [{"filename": "", "idiom": "universal"}],
         "info": {"author": "xcode", "version": 1}}, indent=2
    )
    for num in range(58, 91):
        file = folder / f"{num:03d}.png"
        content = file.read_bytes()
        if not content.startswith(b"\x89PNG\r\n\x1a\n"):
            safe_stop(f"{file} is not a valid PNG file.")
        asset = ASSETS / f"SaxFingering_{num:03d}.imageset"
        content_file = asset / "Contents.json"
        image_file = asset / file.name
        contents = metadata.replace('"filename": ""', f'"filename": "{file.name}"') + "\n"
        if asset.exists() and (not image_file.exists() or
                                not content_file.exists()):
            safe_stop("Existing fingering asset is incomplete: " + asset.name)
        if image_file.exists() and image_file.read_bytes() != content:
            safe_stop("Fingering asset already exists with different contents: " + asset.name)
        if content_file.exists() and content_file.read_text() != contents:
            safe_stop("Fingering asset metadata differs: " + asset.name)
        payload[num] = (asset, image_file, content_file, content, contents)

    print("Ready: 22 guided drills, all 33 fingerings, portrait and landscape playback.")
    print("WAVs and existing music lessons will not be altered. No backup will be created.")

    with tempfile.TemporaryDirectory() as td:
        proposed_swift = Path(td) / "SaxStudioPlayView.swift"
        proposed_screen = Path(td) / "CreateMusicStudioView.swift"
        proposed_swift.write_bytes(new_swift)
        proposed_screen.write_text(edited)
        parse = subprocess.run(
            ["xcrun", "swiftc", "-frontend", "-parse",
             str(proposed_swift), str(proposed_screen)],
            capture_output=True, text=True
        )
        if parse.returncode:
            safe_stop("Swift syntax check failed:\n" + parse.stderr[-1400:])
        print("Swift syntax check passed. Full iOS build still required.")

    added_files = []
    added_dirs = []
    try:
        if not SAX_PLAY.exists():
            SAX_PLAY.write_bytes(new_swift)
            added_files.append(SAX_PLAY)
        for _, (directory, img, meta, data, contents) in payload.items():
            if not directory.exists():
                directory.mkdir()
                added_dirs.append(directory)
            if not img.exists():
                img.write_bytes(data)
                added_files.append(img)
            if not meta.exists():
                meta.write_text(contents)
                added_files.append(meta)
        if edited != original:
            CATALOGUE_SCREEN.write_text(edited)
    except Exception:
        CATALOGUE_SCREEN.write_text(original)
        for path in reversed(added_files):
            path.unlink(missing_ok=True)
        for path in reversed(added_dirs):
            path.rmdir()
        raise

    print("\n✓ Sax Studio Play installed!")
    print("✓ 33 PNG images installed as Xcode image assets (058 = low B-flat3; 090 = high F-sharp6)")
    print("✓ 8 BPM choices, 4 note-change rates, lesson line or chromatic")
    print("✓ Landscape full-screen and subtle-glow Play/Stop")
    print("✓ No backup, no merge, no WAVs replaced")
    print("Open the app in Xcode, press ⌘R, then open a Sax Studio lab.")


if __name__ == "__main__":
    main()
