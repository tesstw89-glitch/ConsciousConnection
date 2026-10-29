#!/usr/bin/env python3
"""Install Groq nutrient estimates, preserving uncommitted local diary changes."""
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

paths = [
    Path("ConsciousConnection/MealJournalView.swift"),
    Path("ConsciousConnection/NutritionGroqInsights.swift"),
]

def git(*args):
    result = subprocess.run(["git", *args], capture_output=True)
    if result.returncode:
        sys.exit("Git error: " + result.stderr.decode(errors="replace"))
    return result.stdout

if not Path("ConsciousConnection.xcodeproj").exists():
    sys.exit("Please run this from ~/Desktop/ConsciousConnection.")
if any(not p.is_file() for p in paths):
    sys.exit("Expected Swift source files are missing; nothing was changed.")

base = git("merge-base", "origin/main", "FETCH_HEAD").decode().strip()
if not base:
    sys.exit("Couldn't find the base commit; nothing changed.")

new_files = {}
with tempfile.TemporaryDirectory(prefix="consciousconnection-groq-") as directory:
    temp = Path(directory)
    for i, path in enumerate(paths):
        local = path.read_bytes()
        original = git("show", f"{base}:{path}")
        updated = git("show", f"FETCH_HEAD:{path}")
        if local == updated:
            new_files[path] = local
            continue

        ours_file = temp / f"{i}-current.swift"
        base_file = temp / f"{i}-base.swift"
        theirs_file = temp / f"{i}-feature.swift"
        ours_file.write_bytes(local)
        base_file.write_bytes(original)
        theirs_file.write_bytes(updated)

        result = subprocess.run(
            ["git", "merge-file", "-p", str(ours_file), str(base_file), str(theirs_file)],
            capture_output=True,
        )
        if result.returncode != 0:
            sys.exit(
                f"Stopped safely: {path} has changes that conflict with the feature.\n"
                "No files were modified. Please share the Terminal output so we can resolve it."
            )
        new_files[path] = result.stdout

    if not (b"groqEstimateRequest" in new_files[paths[0]]
            and b"applyGroqEstimates" in new_files[paths[0]]):
        sys.exit("Feature checks failed for the diary. No files were changed.")
    if b"static func estimate(" not in new_files[paths[1]]:
        sys.exit("Feature checks failed for Groq service. No files were changed.")

    # Swift's parser works even when frameworks can't be linked by this command.
    swiftc = shutil.which("swiftc")
    if swiftc:
        syntax_files = []
        for i, path in enumerate(paths):
            candidate = temp / f"syntax-{i}.swift"
            candidate.write_bytes(new_files[path])
            syntax_files.append(str(candidate))
        syntax = subprocess.run([swiftc, "-frontend", "-parse", *syntax_files],
                                capture_output=True, text=True)
        if syntax.returncode:
            sys.exit("Swift syntax check failed; no files were modified.\n" + syntax.stderr)

stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
for path, data in new_files.items():
    if data != path.read_bytes():
        backup = path.with_name(path.name + ".before-groq-stats-" + stamp + ".bak")
        shutil.copy2(path, backup)
        path.write_bytes(data)
        print("Updated:", path)
        print("Backup:", backup)
    else:
        print("Already up to date:", path)

print("Installed: Groq nutrition estimates with explicit review, source-separated totals, and an undo button.")
print("NEXT: rebuild/run ConsciousConnection, open My Nutrition > Today, tap the Groq button.")
