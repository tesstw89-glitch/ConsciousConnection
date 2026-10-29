#!/usr/bin/env python3
"""Repair UK percentage target mismatches in the two nutrition metric types.

Only edits the metric declarations and their constructor calls.
Keeps diary entries, Groq estimates, the smoothie importer and other UI intact.
"""
from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

path = Path("ConsciousConnection/MealJournalView.swift")
if not path.is_file():
    sys.exit("Cannot find MealJournalView.swift. Run from ~/Desktop/ConsciousConnection.")

original = path.read_text(encoding="utf-8")
updated = original
if "private func ukReferenceTarget(" not in updated:
    sys.exit("Stopped safely: UK reference helper is missing; no files changed.")

for name in ("DayMetric", "GroqDayMetric"):
    # A narrow struct match: no other part of the food diary is touched.
    pattern = re.compile(
        r"(?ms)^    private struct " + re.escape(name) +
        r": Identifiable \{\n(?P<body>.*?)^    \}"
    )
    found = list(pattern.finditer(updated))
    if len(found) != 1:
        sys.exit(f"Stopped safely: expected exactly one {name} struct, found {len(found)}.")
    match = found[0]
    block = match.group(0)
    if "let ukTarget: Double?" not in block:
        id_line = "        var id: String { title }"
        if block.count(id_line) != 1:
            sys.exit(f"Stopped safely: can't safely update {name} fields.")
        block = block.replace(id_line, "        let ukTarget: Double?\n" + id_line, 1)
        updated = updated[:match.start()] + block + updated[match.end():]

    # Supply the required argument in any metric constructor missing it.
    start_token = f"return {name}(title: label"
    if updated.count(start_token) != 1:
        sys.exit(f"Stopped safely: can't uniquely locate the {name} calculation.")
    start = updated.index(start_token)
    end = updated.find("\n        }", start)
    if end < 0:
        sys.exit(f"Stopped safely: can't determine the end of the {name} constructor.")
    call = updated[start:end]
    if "ukTarget:" not in call:
        tail = "precision: digits)"
        if call.count(tail) != 1:
            sys.exit(f"Stopped safely: unexpected {name} constructor, nothing changed.")
        call = call.replace(
            tail, "precision: digits,\n"
                  "                             ukTarget: ukReferenceTarget(for: label))", 1
        )
        updated = updated[:start] + call + updated[end:]

# Check that all declarations and call sites now agree.
for name in ("DayMetric", "GroqDayMetric"):
    start = updated.index(f"    private struct {name}: Identifiable {{")
    stop = updated.index("\n    }", start)
    assert "let ukTarget: Double?" in updated[start:stop], name
    start = updated.index(f"return {name}(title: label")
    stop = updated.index("\n        }", start)
    assert "ukTarget: ukReferenceTarget(for: label)" in updated[start:stop], name

if updated == original:
    print("Already fixed: UK reference targets are wired correctly in both metrics.")
    sys.exit(0)

swiftc = shutil.which("swiftc")
if swiftc:
    with tempfile.TemporaryDirectory(prefix="cc-uk-metric-repair-") as folder:
        candidate = Path(folder) / "MealJournalView.swift"
        candidate.write_text(updated, encoding="utf-8")
        check = subprocess.run(
            [swiftc, "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True,
        )
        if check.returncode:
            sys.exit("Swift syntax validation failed. No changes made.\n" +
                     check.stderr[-4000:])

backup = path.with_name(
    path.name + ".before-uk-metric-repair-" +
    datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak"
)
shutil.copy2(path, backup)
path.write_text(updated, encoding="utf-8")
print("Fixed: DayMetric and GroqDayMetric now both accept UK reference targets.")
print("Existing foods, estimates and other features were not changed.")
print("Backup:", backup)
print("NEXT: build again in Xcode with Cmd+B.")
