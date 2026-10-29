#!/usr/bin/env python3
"""Move the existing Groq action above the daily nutrition cards.

Works with either previous Groq button caption and either daily cards renderer.
Only changes the dayDetail UI; it does not alter diary entries or Groq calculations.
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
    sys.exit("Run this from ~/Desktop/ConsciousConnection (MealJournalView.swift missing).")
source = path.read_text(encoding="utf-8")

# Restrict changes to the day-detail view, never unrelated buttons or data.
start_anchor = "    private var dayDetail: some View {"
if source.count(start_anchor) != 1:
    sys.exit("Stopped safely: can't find the unique daily nutrition view.")
start = source.index(start_anchor)
end_candidates = [
    source.find("    private func groqEstimate(", start + len(start_anchor)),
    source.find("    private struct DayMetric:", start + len(start_anchor)),
]
end_candidates = [i for i in end_candidates if i >= 0]
if not end_candidates:
    sys.exit("Stopped safely: can't locate the end of the daily nutrition view.")
end = min(end_candidates)
day = source[start:end]

if day.count('Label("Fill gaps with AI", systemImage: "sparkles")') == 1:
    print("Already installed: Fill gaps with AI is next to your daily nutrient cards.")
    sys.exit(0)

# Find the old button by its Groq action, not by a brittle caption string.
# The original buttons use the same indentation but two different action/label forms.
pattern = re.compile(
    r'^ {16}Button \{\n'
    r'(?P<action>(?:^ {20}.*\n)+)'
    r'^ {16}\} label: \{\n'
    r'(?P<label>(?:^ {20,}.*\n)+)'
    r'^ {16}\}\n'
    r'(?P<styles>(?:^ {16}\.[^\n]*\n){1,4})',
    re.MULTILINE,
)
matches = [
    match for match in pattern.finditer(day)
    if "groqNutritionPayload = groqDayPayload(dayMeals)" in match.group("action")
    and "showingGroqNutrition = true" in match.group("action")
    and 'Label("Groq:' in match.group("label")
    and '.buttonStyle(.borderedProminent)' in match.group("styles")
    and '.tint(accent)' in match.group("styles")
]
if len(matches) != 1:
    sys.exit(
        f"Stopped safely: found {len(matches)} matching old Groq buttons, need one. "
        "No files were modified."
    )
old = matches[0].group(0)

# Reuse the EXISTING action: this preserves the calculation request even
# when the local diary was assembled by the customised merge installer.
moved = re.sub(
    r'Label\("Groq:[^"]+",\s*systemImage:\s*"sparkles"\)',
    'Label("Fill gaps with AI", systemImage: "sparkles")',
    old,
    count=1,
)
if moved == old or moved.count('Label("Fill gaps with AI"') != 1:
    sys.exit("Stopped safely: couldn't rename the old button.")
moved = moved.replace(".font(.headline)", ".font(.subheadline.weight(.semibold))")
moved = moved.replace(".padding(.vertical, 12)", ".padding(.vertical, 8)")

day_without_old = day[:matches[0].start()] + day[matches[0].end():]
# Put it immediately below the nutrition heading and before the cards.
card_match = re.search(
    r'(?m)^ {16}(?:groqEnhancedNutrientCards|dailyNutrientCards)\(dayMeals\)[ \t]*$',
    day_without_old,
)
if not card_match:
    sys.exit("Stopped safely: couldn't locate the daily nutrient cards.")
before_cards = day_without_old[:card_match.start()]
if not re.search(
    r'Text\("Daily nutrients: recorded \+ estimated"\)\s*\n\s*\.font\(\.headline\)\s*$',
    before_cards,
):
    sys.exit("Stopped safely: daily nutrient header differs from expected.")
day_updated = before_cards + moved + day_without_old[card_match.start():]

if day_updated.count('Label("Fill gaps with AI", systemImage: "sparkles")') != 1:
    sys.exit("Stopped safely: button count validation failed.")
if 'Label("Groq:' in day_updated:
    sys.exit("Stopped safely: an old Groq button is still present in daily view.")

updated = source[:start] + day_updated + source[end:]

compiler = shutil.which("swiftc")
if compiler:
    with tempfile.TemporaryDirectory(prefix="cc-ai-button-") as directory:
        candidate = Path(directory) / "MealJournalView.swift"
        candidate.write_text(updated, encoding="utf-8")
        check = subprocess.run(
            [compiler, "-frontend", "-parse", str(candidate)],
            capture_output=True, text=True,
        )
        if check.returncode:
            sys.exit("Swift syntax check failed. No files modified.\n" + check.stderr[-4000:])

backup = path.with_name(
    path.name + ".before-ai-button-" + datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak"
)
shutil.copy2(path, backup)
path.write_text(updated, encoding="utf-8")
print("Installed: Fill gaps with AI button now appears above the daily nutrition cards.")
print("Previous Groq button removed; existing Groq action and diary data preserved.")
print("Backup:", backup)
print("NEXT: build ConsciousConnection again in Xcode.")
