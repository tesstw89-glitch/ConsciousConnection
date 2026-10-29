#!/usr/bin/env python3
"""Safely install Groq diary stats, including in locally customised food diaries.

Tries Git three-way merge first. If that conflicts, adds new Groq helpers
and UI hooks without replacing existing diary methods or smoothie patches.
Checks BOTH resulting Swift files before writing either. Backs up each.
"""
from datetime import datetime
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

MEAL = Path("ConsciousConnection/MealJournalView.swift")
GROQ = Path("ConsciousConnection/NutritionGroqInsights.swift")
PATHS = [MEAL, GROQ]


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True)
    if result.returncode:
        raise RuntimeError("Git error: " + result.stderr.decode(errors="replace"))
    return result.stdout


def exact_replace(text, old, new, context):
    count = text.count(old)
    if count != 1:
        raise ValueError(
            f"{context}: expected one matching insertion point, found {count}. "
            "Nothing was modified."
        )
    return text.replace(old, new, 1)


def extract(text, start, end, context):
    i = text.find(start)
    if i < 0 or text.find(start, i + 1) >= 0:
        raise ValueError(f"{context}: can't identify unique starting boundary")
    j = text.find(end, i + len(start))
    if j < 0:
        raise ValueError(f"{context}: can't identify ending boundary")
    return text[i:j]


def semantic_meal(local, feature):
    if "nutrition.groqIngredientEstimates.v1" in local:
        raise ValueError("Groq state partially exists in your local diary; need to inspect it before editing.")
    needed = [
        "struct MealJournalView: View", "private struct JournalIngredient",
        "private struct JournalMeal", "private func loadSavedMeals()",
        "private func dailyMetrics(", "private func dailyNutrientCards(",
        "private func loadTemplates()", "groqNutritionPayload = groqDayPayload(dayMeals)",
        "private func groqDayPayload("
    ]
    missing = [x for x in needed if x not in local]
    if missing:
        raise ValueError("Local diary has a different structure: " + ", ".join(missing))

    # Add one new property to JournalIngredient without altering its stored data.
    signature = extract(
        feature,
        "    // Changing the food or its portion invalidates stored AI estimates.\n",
        "    var nutrientSummary: String {",
        "food portion signature",
    )
    local = exact_replace(local, "    var nutrientSummary: String {",
                          signature + "    var nutrientSummary: String {",
                          "ingredient extension")

    # Store AI values SEPARATELY from logged meals and product label values.
    local = exact_replace(
        local,
        '    @AppStorage("nutrition.loggedMeals.v1") private var savedMealsJSON = ""\n',
        '    @AppStorage("nutrition.loggedMeals.v1") private var savedMealsJSON = ""\n'
        '    @AppStorage("nutrition.groqIngredientEstimates.v1") private var storedGroqJSON = ""\n',
        "Groq storage")
    local = exact_replace(
        local, '    @State private var groqNutritionPayload = ""\n',
        '    @State private var groqNutritionPayload = ""\n'
        '    @State private var groqEstimatePayload = ""\n'
        '    @State private var groqEstimates: [NutritionGroqStoredEstimate] = []\n',
        "Groq view state")

    # Works even if loadSavedMeals() has a one-time smoothie defer hook inside it.
    matches = list(re.finditer(r"(?m)^([ \t]*)loadSavedMeals\(\)[ \t]*$", local))
    if len(matches) != 1:
        raise ValueError("Can't uniquely find the existing onAppear diary loader.")
    m = matches[0]
    local = local[:m.start()] + m.group(1) + "loadStoredGroqEstimates()\n" + local[m.start():]
    local = exact_replace(
        local,
        "NutritionGroqReviewView(payload: groqNutritionPayload)",
        "NutritionGroqReviewView(payload: groqNutritionPayload,\n"
        "                    estimatePayload: groqEstimatePayload,\n"
        "                    onApplyEstimates: applyGroqEstimates)",
        "Groq review sheet")

    # Preserve the user's original dailyMetrics/dailyNutrientCards. Rather than
    # replacing either, ADD a new enhanced renderer and switch one call site.
    local = exact_replace(local,
                          "dailyNutrientCards(dayMeals)",
                          "groqEnhancedNutrientCards(dayMeals)",
                          "daily nutrient summary")
    if 'Text("Recorded nutrients")' in local:
        local = local.replace('Text("Recorded nutrients")',
                              'Text("Daily nutrients: recorded + estimated")', 1)

    m = list(re.finditer(
        r"(?m)^([ \t]*)groqNutritionPayload = groqDayPayload\(dayMeals\)[ \t]*$",
        local))
    if len(m) != 1:
        raise ValueError("Can't find the Groq button's current-day action.")
    hit = m[0]
    local = local[:hit.end()] + "\n" + hit.group(1) + \
        "groqEstimatePayload = groqEstimateRequest(dayMeals)" + local[hit.end():]

    # Create a per-day undo button, sourced from the feature branch.
    undo = extract(
        feature, "                if dayMeals.contains(where: { meal in",
        "                Button {\n                    groqNutritionPayload = groqDayPayload(dayMeals)",
        "clear estimates button")
    local = exact_replace(
        local, "                groqEnhancedNutrientCards(dayMeals)\n",
        "                groqEnhancedNutrientCards(dayMeals)\n" + undo,
        "clear button location")

    # New methods from feature, with renamed statistic methods so we never
    # replace local stats logic or delete other customisations.
    new_helpers = extract(
        feature, "    private func groqEstimate(for meal:",
        "    // Only send edible amounts", "Groq stats helpers")
    new_helpers = new_helpers.replace("DayMetric", "GroqDayMetric")
    new_helpers = new_helpers.replace("dailyMetrics", "groqEnhancedMetrics")
    new_helpers = new_helpers.replace("dailyNutrientCards", "groqEnhancedNutrientCards")
    new_request = extract(
        feature, "    // Only send edible amounts",
        "    // Use measured per-portion", "structured Groq request")
    local = exact_replace(
        local, "    private func groqDayPayload(",
        new_helpers + new_request + "    private func groqDayPayload(",
        "new Groq stats methods")

    # The new persistence helpers can be placed near loadTemplates, without
    # touching the body of loadSavedMeals (which may include a smoothie patch).
    new_storage = extract(
        feature, "    private func loadStoredGroqEstimates()",
        "    private func loadTemplates()", "Groq persistence")
    local = exact_replace(
        local, "    private func loadTemplates()",
        new_storage + "    private func loadTemplates()",
        "new local storage methods")

    for required in (
        "groqEnhancedNutrientCards(dayMeals)",
        "private func applyGroqEstimates(",
        "private func removeGroqEstimates(",
        "private func groqEstimateRequest(",
        "nutrition.groqIngredientEstimates.v1",
    ):
        if required not in local:
            raise ValueError("Incomplete diary patch: " + required)
    return local


def semantic_groq(local, feature):
    if "struct NutritionGroqIngredientEstimate" in local:
        raise ValueError("Groq estimates partially exist in your local service; need to inspect before editing.")
    if "private enum NutritionGroqService {" not in local or \
       "struct NutritionGroqReviewView: View {" not in local:
        raise ValueError("Local Groq service has a different structure.")

    types = extract(
        feature, "// Groq numbers refer to the consumed portion",
        "private enum NutritionGroqService {", "Groq response models")
    local = exact_replace(
        local, "private enum NutritionGroqService {",
        types + "private enum NutritionGroqService {",
        "response model placement")

    # Insert new API method while retaining existing written-review method.
    api = extract(
        feature, "    // Use Groq's strict structured outputs",
        "\n}\n\nstruct NutritionGroqReviewView: View {",
        "structured Groq endpoint")
    local = exact_replace(
        local, "\n}\n\nstruct NutritionGroqReviewView: View {",
        "\n" + api + "\n}\n\nstruct NutritionGroqReviewView: View {",
        "Groq endpoint placement")

    local = exact_replace(
        local, "    let payload: String\n",
        "    let payload: String\n"
        "    var estimatePayload: String = \"\"\n"
        "    var onApplyEstimates: (([NutritionGroqIngredientEstimate]) -> Int)? = nil\n",
        "Groq sheet parameters")
    local = exact_replace(
        local, '    @State private var resultText = ""\n',
        '    @State private var resultText = ""\n'
        '    @State private var estimates: NutritionGroqEstimateResponse? = nil\n'
        '    @State private var applied = false\n'
        '    @State private var appliedCount = 0\n',
        "Groq state")

    ui = extract(
        feature, "                    if !estimatePayload.isEmpty && onApplyEstimates != nil {",
        "                    if let feedback {", "Groq review controls")
    local = exact_replace(
        local, "                    if let feedback {\n",
        ui + "                    if let feedback {\n",
        "Groq controls insertion")
    if "                    if appliedCount > 0 {" not in local:
        status = extract(
            feature, "                    if appliedCount > 0 {",
            "                    if let feedback {", "estimate confirmation")
        local = exact_replace(
            local, "                    if let feedback {\n",
            status + "                    if let feedback {\n",
            "Groq confirmation insertion")

    methods = extract(
        feature, "    private func estimateSummary(",
        "    @MainActor\n    private func analyse() async {",
        "Groq review actions")
    local = exact_replace(
        local, "    @MainActor\n    private func analyse() async {",
        methods + "    @MainActor\n    private func analyse() async {",
        "Groq action insertion")

    # Documentation of what is shared with Groq changes with the extra button.
    local = local.replace(
        "Privacy: only when you tap **Summarise with Groq** will this day's meal names, portions, recorded nutrient contributions and your checked kitchen items be sent to Groq. No calorie data is sent.",
        "Privacy: day details are sent to Groq only when you tap a Groq button. Your checked kitchen items are only sent for the written review. No calories are shared.",
        1)
    return local


def install():
    if not Path("ConsciousConnection.xcodeproj").exists():
        sys.exit("Run this command from ~/Desktop/ConsciousConnection.")
    if any(not p.is_file() for p in PATHS):
        sys.exit("Expected diary and Groq Swift files were not found. No changes made.")

    try:
        base = git("merge-base", "origin/main", "FETCH_HEAD").decode().strip()
        remote = {p: git("show", f"FETCH_HEAD:{p}").decode("utf-8") for p in PATHS}
        base_files = {p: git("show", f"{base}:{p}") for p in PATHS}
    except Exception as error:
        sys.exit(str(error))

    new_files = {}
    with tempfile.TemporaryDirectory(prefix="consciousconnection-groq-") as folder:
        temp = Path(folder)
        for index, path in enumerate(PATHS):
            original = path.read_bytes()
            desired = remote[path].encode("utf-8")
            if original == desired:
                new_files[path] = original
                print("Already matches the Groq feature:", path)
                continue

            ours = temp / f"current-{index}.swift"
            ancestor = temp / f"base-{index}.swift"
            theirs = temp / f"feature-{index}.swift"
            ours.write_bytes(original)
            ancestor.write_bytes(base_files[path])
            theirs.write_bytes(desired)

            merge = subprocess.run(
                ["git", "merge-file", "-p", str(ours), str(ancestor), str(theirs)],
                capture_output=True)
            if merge.returncode == 0:
                new_files[path] = merge.stdout
                print("Merged existing changes:", path)
                continue
            if merge.returncode > 1:
                sys.exit("Git merge error for " + str(path) + "; nothing changed.")

            # Only this file conflicted. Add small, verified changes instead.
            print("Found overlapping edits in", path, "— using safe targeted integration.")
            try:
                local_text = original.decode("utf-8")
                if path == MEAL:
                    result = semantic_meal(local_text, remote[path])
                else:
                    result = semantic_groq(local_text, remote[path])
                new_files[path] = result.encode("utf-8")
            except (ValueError, UnicodeError) as error:
                sys.exit(f"Stopped safely for {path}: {error}\n"
                         "No files were modified. Share this error for a tailored fix.")

        if b"groqEnhancedNutrientCards" not in new_files[MEAL] and \
           b"private func applyGroqEstimates(" not in new_files[MEAL]:
            sys.exit("Groq diary integration checks failed. Nothing modified.")
        if b"static func estimate(" not in new_files[GROQ]:
            sys.exit("Groq service integration checks failed. Nothing modified.")

        compiler = shutil.which("swiftc")
        if compiler:
            drafts = []
            for i, path in enumerate(PATHS):
                dest = temp / f"validate-{i}.swift"
                dest.write_bytes(new_files[path])
                drafts.append(str(dest))
            check = subprocess.run(
                [compiler, "-frontend", "-parse", *drafts],
                capture_output=True, text=True)
            if check.returncode:
                sys.exit("Swift syntax check failed: nothing was modified.\n"
                         + check.stderr[-6000:])
            print("Swift syntax validation passed.")

    # All validation completes before ANY file is changed; create backups first.
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    pending = [(p, new_files[p]) for p in PATHS if p.read_bytes() != new_files[p]]
    for path, _ in pending:
        backup = path.with_name(path.name + ".before-groq-stats-" + timestamp + ".bak")
        shutil.copy2(path, backup)
        print("Backup:", backup)
    for path, data in pending:
        path.write_bytes(data)
        print("Updated:", path)
    if not pending:
        print("Groq estimate feature is already installed. No modifications needed.")
    else:
        print("Installed Groq nutrient estimates without discarding existing diary customisations.")
    print("NEXT: rebuild ConsciousConnection and open My Nutrition > Today.")


if __name__ == "__main__":
    install()
