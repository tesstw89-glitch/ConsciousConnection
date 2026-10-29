#!/usr/bin/env python3
"""Safely log the user's 29 October 2026 smoothie once in the on-device food diary.

Unlike the first installer, this does not depend on a particular existing @AppStorage
line, exact loader implementation, or existing saved-meal template.
"""
from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap

path = Path("ConsciousConnection/MealJournalView.swift")
if not path.is_file():
    sys.exit("Cannot find the food diary. Run this from ~/Desktop/ConsciousConnection.")

original = path.read_text(encoding="utf-8")
marker = "OCT29_SMOOTHIE_LOG_2026"
if marker in original:
    print("Already installed: the smoothie diary importer is present; nothing changed.")
    sys.exit(0)

# Check the actual model shape, rather than demanding a particular previous patch.
checks = {
    "JournalIngredient model": r"\bstruct\s+JournalIngredient\s*:",
    "JournalMeal model": r"\bstruct\s+JournalMeal\s*:",
    "MealJournalView": r"\bstruct\s+MealJournalView\s*:",
    "meal diary storage": r"\bvar\s+savedMealsJSON\b",
    "meal entries": r"\bvar\s+meals\s*:\s*\[JournalMeal\]",
    "food portion text": r"\bvar\s+quantityText\b",
    "portion unit": r"\bvar\s+portionUnit\b",
    "product quantity unit": r"\bvar\s+productQuantityUnit\b",
    "dated meals": r"\bvar\s+eatenAt\s*:\s*Date\b",
}
missing = [label for label, pattern in checks.items() if not re.search(pattern, original)]
if missing:
    sys.exit("Stopped safely: this local diary uses a different model (" +
             ", ".join(missing) + "). No files were modified.")

# Hook on the loader itself: its defer executes even if today's diary is empty,
# and the importer independently checks that any existing JSON is valid.
loader = re.compile(
    r"(?m)^([ \t]*)(?:(?:private|fileprivate)\s+)?func[ \t]+loadSavedMeals[ \t]*\(\s*\)[ \t]*\{[ \t]*$"
)
matches = list(loader.finditer(original))
if len(matches) != 1:
    sys.exit(
        f"Stopped safely: found {len(matches)} loadSavedMeals() implementations; "
        "need exactly one. No files were modified. "
        "Please share this message if it occurs."
    )

method = r'''// OCT29_SMOOTHIE_LOG_2026: one-time on-device import, no other diary changes.
private func logOctober29SmoothieIfNeeded() {
    let key = "nutrition.smoothie20261029Logged.v2"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    let calendar = Calendar.current
    guard let eatenAt = calendar.date(from: DateComponents(
        year: 2026, month: 10, day: 29, hour: 10, minute: 0
    )) else { return }

    // Read the stored diary independently; never destroy malformed stored data.
    let existing: [JournalMeal]
    if savedMealsJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        existing = []
    } else {
        guard let data = savedMealsJSON.data(using: .utf8),
              let stored = try? JSONDecoder().decode([JournalMeal].self, from: data)
        else {
            print("Smoothie import skipped: existing meal JSON could not be read.")
            return
        }
        existing = stored
    }

    let title = "PACK'D Tropical Smoothie"
    if existing.contains(where: {
        calendar.isDate($0.eatenAt, inSameDayAs: eatenAt) &&
        $0.name.caseInsensitiveCompare(title) == .orderedSame
    }) {
        meals = existing
        UserDefaults.standard.set(true, forKey: key)
        return
    }

    let ingredients: [JournalIngredient] = [
        JournalIngredient(name: "Banana", quantityText: "50", portionUnit: "g"),
        JournalIngredient(name: "Frozen avocado", brand: "PACK'D", quantityText: "30", portionUnit: "g"),
        JournalIngredient(name: "Frozen mango", brand: "PACK'D", quantityText: "45", portionUnit: "g"),
        JournalIngredient(name: "Frozen pineapple", brand: "Sainsbury's", quantityText: "30", portionUnit: "g"),
        JournalIngredient(name: "Milk", quantityText: "250", portionUnit: "ml", productQuantityUnit: "ml"),
        JournalIngredient(name: "Chia seeds", quantityText: "5", portionUnit: "g"),
        JournalIngredient(name: "Honey", quantityText: "21", portionUnit: "g")
    ]
    let entry = JournalMeal(id: UUID(), name: title,
                            mealType: "Breakfast", eatenAt: eatenAt,
                            ingredients: ingredients)
    var updated = existing
    updated.append(entry)
    guard let data = try? JSONEncoder().encode(updated),
          let json = String(data: data, encoding: .utf8) else { return }
    savedMealsJSON = json

    // Only mark complete after confirming the updated storage decoded correctly.
    guard let storedData = savedMealsJSON.data(using: .utf8),
          let confirmed = try? JSONDecoder().decode([JournalMeal].self, from: storedData),
          confirmed.contains(where: { $0.id == entry.id }) else { return }
    meals = confirmed
    UserDefaults.standard.set(true, forKey: key)
}
'''

match = matches[0]
indent = match.group(1)
injected = textwrap.indent(method, indent) + "\n"
# Insert before the loader and then add a defer at the start of its body.
updated = (original[:match.start()] + injected +
           original[match.start():match.end()] +
           "\n" + indent + "    defer { logOctober29SmoothieIfNeeded() }" +
           original[match.end():])
if updated.count(marker) != 1 or updated.count("defer { logOctober29SmoothieIfNeeded() }") != 1:
    sys.exit("Internal patch validation failed. Nothing was changed.")

swiftc = shutil.which("swiftc")
if swiftc:
    with tempfile.TemporaryDirectory(prefix="smoothie-swift-check-") as folder:
        draft = Path(folder) / "MealJournalView.swift"
        draft.write_text(updated, encoding="utf-8")
        result = subprocess.run(
            [swiftc, "-frontend", "-parse", str(draft)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            sys.exit("Swift syntax check failed; nothing was changed.\n" +
                     result.stderr[-4000:])

backup = path.with_name(path.name + ".before-smoothie-20261029-" +
                        datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak")
shutil.copy2(path, backup)
path.write_text(updated, encoding="utf-8")
print("Installed! Your 7-ingredient smoothie will be logged once for 29 October 2026.")
print("Saved as Breakfast at approximately 10:00 am; existing entries remain untouched.")
print("Backup:", backup)
print("NEXT: rebuild and run the app, then open My Nutrition.")
