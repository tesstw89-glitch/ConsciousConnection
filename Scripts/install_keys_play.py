#!/usr/bin/env python3
"""Install Keys Play Mode in Desktop ConsciousConnection, with no backups or Git checkout."""
from pathlib import Path
import subprocess
import tempfile
import shutil
import sys

ROOT = Path.home() / 'Desktop/ConsciousConnection'
APP = ROOT / 'ConsciousConnection'
EDITOR = APP / 'CreateMusicStudioView.swift'
SWIFT = APP / 'KeysStudioPlayView.swift'
GENERATOR = ROOT / 'Scripts' / 'generate_keys_grooves.py'


def stop(message):
    raise SystemExit('SAFE STOP: ' + message + '  NO CHANGES MADE.')


def branch_file(path):
    return subprocess.check_output(['git', 'show', f'FETCH_HEAD:{path}'], cwd=ROOT)


def install():
    if not EDITOR.exists() or not (APP / 'CuratedMinilogueKeyboard.swift').is_file():
        stop('Expected CreateMusicStudioView.swift and the coloured keyboard component.')
    if not (APP / 'Keys_Studio_Hand_Assignments.json').is_file():
        stop('Reviewed left/right hand assignments not installed yet.')
    original = EDITOR.read_text()
    marker = '                Spacer()\n                Button {\n                    chordIndex = (chordIndex + lab.chords.count - 1) % lab.chords.count'
    play = '''                Spacer()
                NavigationLink(destination: KeysStudioPlayView(lab: lab)) {
                    Label("Play", systemImage: "play.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(studioMint, in: Capsule())
                        .foregroundStyle(studioInk)
                }
                .buttonStyle(.plain)
                Button {
                    chordIndex = (chordIndex + lab.chords.count - 1) % lab.chords.count'''
    if original.count(marker) != 1 or original.count('private func chordPanel(_ chord: MusicChord) -> some View') != 1:
        if 'KeysStudioPlayView(lab: lab)' in original:
            print('Play button already present; leaving navigation untouched.')
            modified = original
        else:
            stop('Could not locate exactly one known chord header to add Play next to.')
    else:
        modified = original.replace(marker, play, 1)

    swift = branch_file('ConsciousConnection/KeysStudioPlayView.swift')
    gen = branch_file('Scripts/generate_keys_grooves.py')
    for location, content in [(SWIFT, swift), (GENERATOR, gen)]:
        if location.exists() and location.read_bytes() != content:
            stop('Existing file differs: ' + str(location))
    print('Ready: one new Play-mode Swift file, original demonstration WAV loops, one small button edit.')
    swiftc = shutil.which('swiftc')
    if swiftc:
        with tempfile.TemporaryDirectory() as td:
            candidate = Path(td) / 'CreateMusicStudioView.swift'
            proposed = Path(td) / 'KeysStudioPlayView.swift'
            candidate.write_text(modified)
            proposed.write_bytes(swift)
            test = subprocess.run([swiftc, '-frontend', '-parse', str(candidate), str(proposed)],
                                  capture_output=True, text=True)
            if test.returncode:
                stop('Swift syntax check failed:\n' + test.stderr[-1500:])
        print('Swift syntax check passed (full Xcode build still required).')

    with tempfile.TemporaryDirectory() as td:
        temp_gen = Path(td) / 'generate_keys_grooves.py'
        temp_gen.write_bytes(gen)
        temp_wavs = Path(td) / 'WAVs'
        run = subprocess.run([sys.executable, str(temp_gen), str(temp_wavs)],
                             capture_output=True, text=True)
        if run.returncode:
            stop('Drum-WAV generation failed:\n' + run.stderr[-900:])
        print(run.stdout.strip())
        wavs = sorted(temp_wavs.glob('KeysGroove_*.wav'))
        if len(wavs) != 24:
            stop('Expected 24 WAV assets (8 tempi × 3 metres).')
        for source in wavs:
            dest = APP / source.name
            if dest.exists() and dest.read_bytes() != source.read_bytes():
                stop('Existing WAV is different: ' + dest.name)
        created = []
        try:
            if not SWIFT.exists():
                SWIFT.write_bytes(swift)
                created.append(SWIFT)
            if not GENERATOR.exists():
                GENERATOR.parent.mkdir(parents=True, exist_ok=True)
                GENERATOR.write_bytes(gen)
                created.append(GENERATOR)
            for source in wavs:
                dest = APP / source.name
                if not dest.exists():
                    dest.write_bytes(source.read_bytes())
                    created.append(dest)
            if modified != original:
                EDITOR.write_text(modified)
            print('✓ Play mode added. Original Create features untouched. No backup created.')
            print('✓ Xcode: build and run (⌘R). Do not uninstall your app.')
        except Exception:
            EDITOR.write_text(original)
            for dest in created:
                dest.unlink(missing_ok=True)
            raise


if __name__ == '__main__':
    install()
