#!/usr/bin/env python3
"""Fix Swift's Groq portion-signature type-check timeout, preserving local edits."""
from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

file = Path("ConsciousConnection/MealJournalView.swift")
if not file.is_file():
    sys.exit("MealJournalView.swift not found. Run from the ConsciousConnection project folder.")
source = file.read_text(encoding="utf-8")

start = "    var groqPortionSignature: String {\n"
if source.count(start) != 1:
    sys.exit(f"Stopped safely: found {source.count(start)} portion-signature methods. No changes made.")
i = source.index(start)
j = source.find("\n    }\n", i + len(start))
if j == -1:
    sys.exit("Stopped safely: couldn't find the end of the portion-signature method.")
j += len("\n    }\n")
old = source[i:j]

if "var fields: [String] = []" in old and "return fields.joined(separator: \"|\")" in old:
    print("Groq portion-signature fix is already installed.")
    sys.exit(0)

required = ('String(servingQuantity ?? -1)', 'String(customUnitSize ?? -1)', '].joined(separator: "|")')
if not all(part in old for part in required):
    sys.exit("Stopped safely: this method has additional changes. Nothing modified.")

replacement = '''    var groqPortionSignature: String {
        var fields: [String] = []
        fields.append(name)
        fields.append(brand ?? "")
        fields.append(barcode ?? "")
        fields.append(quantityText ?? "")
        fields.append(portionUnit ?? "")
        fields.append(servingSizeText ?? "")
        fields.append(servingQuantity.map { String($0) } ?? "-1")
        fields.append(servingQuantityUnit ?? "")
        fields.append(productQuantityUnit ?? "")
        fields.append(customUnitSize.map { String($0) } ?? "-1")
        return fields.joined(separator: "|")
    }
'''
updated = source[:i] + replacement + source[j:]

compiler = shutil.which("swiftc")
if compiler:
    with tempfile.TemporaryDirectory(prefix="groq-typecheck-") as temp:
        draft = Path(temp) / "MealJournalView.swift"
        draft.write_text(updated, encoding="utf-8")
        check = subprocess.run([compiler, "-frontend", "-parse", str(draft)],
                               capture_output=True, text=True)
        if check.returncode:
            sys.exit("Swift syntax check failed; nothing was changed.\n" + check.stderr[-4000:])

backup = file.with_name(file.name + ".before-groq-compiler-fix-" +
                        datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak")
shutil.copy2(file, backup)
file.write_text(updated, encoding="utf-8")
print("Fixed: simplified groqPortionSignature so Swift can type-check it.")
print("Backup:", backup)
print("NEXT: build again in Xcode (Cmd+B).")
