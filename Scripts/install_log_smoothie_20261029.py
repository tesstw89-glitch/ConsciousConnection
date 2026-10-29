#!/usr/bin/env python3
"""Log the 29 October 2026 smoothie once in ConsciousConnection's on-device meal diary."""
from datetime import datetime
from pathlib import Path
import shutil
import sys

path = Path("ConsciousConnection/MealJournalView.swift")
if not path.is_file():
    sys.exit("Cannot find ConsciousConnection/MealJournalView.swift. Run from your ConsciousConnection project folder.")

original = path.read_text(encoding="utf-8")
marker = "OCT29_SMOOTHIE_LOG_2026"
if marker in original:
    print("Already installed: the 29 October smoothie importer is present.")
    sys.exit(0)

flag_anchor = '    @AppStorage("nutrition.packdTropicalSmoothieSeeded.v1") private var didSeedPackdSmoothie = false\n'
load_anchor = '''        guard let bytes = savedMealsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([JournalMeal].self, from: bytes) else { return }
        meals = decoded
'''
method_anchor = "    private func storeTemplates() {\n"

for name, anchor in [("storage", flag_anchor), ("meal loading", load_anchor), ("method placement", method_anchor)]:
    if original.count(anchor) != 1:
        sys.exit(f"Stopped safely: expected exactly one {name} anchor, found {original.count(anchor)}. No files were modified.")

updated = original.replace(flag_anchor, flag_anchor +
    '    @AppStorage("nutrition.smoothie20261029Logged.v1") private var didLogOctober29Smoothie = false\n')
updated = updated.replace(load_anchor, '''        // An empty diary is valid, but a damaged stored diary must never be overwritten.
        if savedMealsJSON.isEmpty {
            meals = []
        } else {
            guard let bytes = savedMealsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([JournalMeal].self, from: bytes) else { return }
            meals = decoded
        }
        logOctober29SmoothieIfNeeded()
''')

method = '''    // OCT29_SMOOTHIE_LOG_2026: one-time entry, added on opening My Nutrition.
    // Keep the dated record on this device; no existing meals or favourites are changed.
    private func logOctober29SmoothieIfNeeded() {
        guard !didLogOctober29Smoothie else { return }
        guard let eatenAt = dayCalendar.date(from: DateComponents(
            year: 2026, month: 10, day: 29, hour: 10, minute: 0
        )) else { return }

        let title = "PACK'D Tropical Smoothie"
        if meals.contains(where: {
            dayCalendar.isDate($0.eatenAt, inSameDayAs: eatenAt) &&
            $0.name.caseInsensitiveCompare(title) == .orderedSame
        }) {
            didLogOctober29Smoothie = true
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
        let entry = JournalMeal(id: UUID(), name: title, mealType: "Breakfast",
                                eatenAt: eatenAt, ingredients: ingredients)
        meals.append(entry)
        storeMeals()
        // Do not mark complete unless it really reached local storage.
        if let bytes = savedMealsJSON.data(using: .utf8),
           let stored = try? JSONDecoder().decode([JournalMeal].self, from: bytes),
           stored.contains(where: { $0.id == entry.id }) {
            didLogOctober29Smoothie = true
        }
    }

'''
updated = updated.replace(method_anchor, method + method_anchor)
if updated.count(marker) != 1:
    sys.exit("Stopped safely: final patch verification failed.")

backup = path.with_name(path.name + ".before-smoothie-20261029-" + datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak")
shutil.copy2(path, backup)
path.write_text(updated, encoding="utf-8")
print("Installed: log PACK'D Tropical Smoothie as breakfast on 29 October 2026.")
print("All 7 ingredients and quantities are included. It will log only once when you open My Nutrition.")
print("Existing diary data is preserved. Backup:", backup)
print("NEXT: rebuild and run ConsciousConnection on your device, then open My Nutrition.")
