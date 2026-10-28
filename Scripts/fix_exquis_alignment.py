#!/usr/bin/env python3
"""Correct cropped Exquis photo calibration without overwriting other app features."""
from pathlib import Path
import subprocess
import tempfile
import sys

APP = Path.home() / "Desktop/ConsciousConnection/ConsciousConnection"
FILE = APP / "ExquisChordBoard.swift"

def stop(message):
    sys.exit("SAFE STOP: " + message + "\nNo app files changed.")

if not FILE.is_file():
    stop("ExquisChordBoard.swift wasn't found. Install Exquis first.")

old = FILE.read_text()
if "croppedFirstX = 0.07545" in old:
    print("Exquis alignment is already corrected. No changes needed.")
    sys.exit(0)

def change(src, previous, updated, label):
    if src.count(previous) != 1:
        stop("Unexpected Exquis code for " + label)
    return src.replace(previous, updated, 1)

new = old
new = change(new,
'''        return decoded.keys
    }()''',
'''        // EXQUIS_CROPPED_CALIBRATION_V2
        // The supplied dark photo is a tighter crop of the original
        // drawing. Its note map still describes the same 61 pads.
        // Translate the old normalised centres into the cropped frame.
        let size = UIImage(named: "ExquisBoard")?.size ?? .zero
        let cropped = size.height > 0 && size.width / size.height > 1.50
        if !cropped { return decoded.keys }
        let originalFirstX = 0.2069672131147541
        let originalLastX = 0.7941176470588235
        let originalFirstY = 0.2635651898447753
        let originalLastY = 0.7413461798695499
        let croppedFirstX = 0.07545
        let croppedLastX = 0.93021
        let croppedFirstY = 0.11253
        let croppedLastY = 0.87356
        return decoded.keys.map { pad in
            let x = croppedFirstX + (pad.x - originalFirstX)
                * (croppedLastX - croppedFirstX) / (originalLastX - originalFirstX)
            let y = croppedFirstY + (pad.y - originalFirstY)
                * (croppedLastY - croppedFirstY) / (originalLastY - originalFirstY)
            return ExquisPad(idx: pad.idx, note: pad.note, x: x, y: y)
        }
    }()''',
"pad-centre calibration")
new = change(new,
'''            let active = chordPitchClasses
            let root = rootPitchClass''',
'''            let active = chordPitchClasses
            let root = rootPitchClass
            let cropped = photoWidth / photoHeight > 1.50
            let hexWidth = cropped ? w * 0.094 : w * (109.0 / 1754.0)
            let hexHeight = cropped ? h * 0.129 : h * (96.0 / 1241.0)''',
"highlight sizing")
new = change(new,
'''                                .frame(width: w * (109.0 / 1754.0),
                                       height: h * (96.0 / 1241.0))''',
'''                                .frame(width: hexWidth, height: hexHeight)''',
"highlight frame")
if 'private var photoSize: CGSize' not in new:
    stop("Exquis view is not the expected resolution-independent version.")

with tempfile.TemporaryDirectory() as directory:
    candidate = Path(directory) / FILE.name
    candidate.write_text(new)
    verify = subprocess.run(
        ["xcrun", "swiftc", "-frontend", "-parse", str(candidate)],
        capture_output=True, text=True
    )
    if verify.returncode:
        stop("Swift syntax check failed:\n" + verify.stderr[-1400:])

FILE.write_text(new)
print("✓ Exquis overlays realigned to the 1202 × 770 cropped photo.")
print("✓ Highlights enlarged to fit whole hexagon faces.")
print("✓ All 61 positions; mint notes and gold roots unchanged.")
print("✓ Piano mode, WAV grooves and audio untouched. No backup.")
print("✓ Rebuild the existing app in Xcode with ⌘R.")
