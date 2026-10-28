#!/usr/bin/env python3
"""Safely install StrengthLab's Combine Workouts feature in a local checkout.

Run from the ConsciousConnection repository root, after fetching the latest
origin/main. Installs only the new workout-combination sheet and its hooks into
WorkoutLibraryHomeView.swift. Does not merge branches or touch other files.
"""
from __future__ import annotations

import os
import shutil
import stat
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path.cwd()
ROUTINE = Path("StrengthLabModule/Sources/StrengthLabModule/Views/Main/Routine")
HOME = ROOT / ROUTINE / "WorkoutLibraryHomeView.swift"
NEW_VIEW = ROOT / ROUTINE / "WorkoutCombineSheet.swift"
REMOTE_NEW_VIEW = (ROUTINE / "WorkoutCombineSheet.swift").as_posix()


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


if not HOME.is_file():
    fail("Run this script from the root of ~/Desktop/ConsciousConnection.")

try:
    new_view_content = subprocess.check_output(
        ["git", "show", f"FETCH_HEAD:{REMOTE_NEW_VIEW}"],
        cwd=ROOT,
        text=True,
        stderr=subprocess.PIPE,
    )
except (OSError, subprocess.CalledProcessError):
    fail("The GitHub feature file was not found. Run 'git fetch origin main' first.")

source = HOME.read_text(encoding="utf-8")
if NEW_VIEW.exists() and NEW_VIEW.read_text(encoding="utf-8") != new_view_content:
    fail(f"{NEW_VIEW.relative_to(ROOT)} already exists and differs from GitHub. Nothing changed.")

patches = [
    (
        "Combine Workouts state",
        """    @State
    private var showingCalendar = false

    @State private var programStore""",
        """    @State
    private var showingCalendar = false

    @State private var showingCombineWorkouts = false
    @State private var pendingCombinedWorkout: WorkoutTemplate?

    @State private var programStore""",
    ),
    (
        "Combine Workouts sheet",
        """        .sheet(isPresented: $showingPrograms) {
            programsSheet
        }
        .alert(""",
        """        .sheet(isPresented: $showingPrograms) {
            programsSheet
        }
        .sheet(isPresented: $showingCombineWorkouts, onDismiss: {
            // Open the new workout for editing after the picker closes.
            if let pendingCombinedWorkout {
                editingWorkout = pendingCombinedWorkout
                self.pendingCombinedWorkout = nil
            }
        }) {
            WorkoutCombineSheet(workouts: workouts) { first, second, name in
                combineWorkouts(first, second, named: name)
            }
        }
        .alert(""",
    ),
    (
        "Combine Workouts menu",
        """                Button {
                    showingCalendar = true
                } label: {
                    Label(
                        "Calendar",
                        systemImage: "calendar"
                    )
                }

                Menu {""",
        """                if workouts.count >= 2 {
                    Button {
                        showingCombineWorkouts = true
                    } label: {
                        Label(
                            "Combine Workouts",
                            systemImage: "square.on.square"
                        )
                    }
                }

                Button {
                    showingCalendar = true
                } label: {
                    Label(
                        "Calendar",
                        systemImage: "calendar"
                    )
                }

                Menu {""",
    ),
    (
        "Combine Workouts banner button",
        """            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(
            maxWidth: .infinity,
            minHeight: 288,""",
        """            }
            .buttonStyle(.plain)

            if workouts.count >= 2 {
                Button {
                    showingCombineWorkouts = true
                } label: {
                    Label("Combine Workouts", systemImage: "square.on.square")
                        .font(StrengthLabFigmaTheme.medium(16))
                        .foregroundStyle(StrengthLabFigmaTheme.coral)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .padding(24)
        .frame(
            maxWidth: .infinity,
            minHeight: 288,""",
    ),
    (
        "Combine Workouts clone action",
        """    private func removeFromProgram(_ workout: WorkoutTemplate) {""",
        """    private func combineWorkouts(
        _ first: WorkoutTemplate,
        _ second: WorkoutTemplate,
        named name: String
    ) {
        guard first.uuid != second.uuid else { return }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        // Copy models, never move them: each source retains its exercises,
        // histories, schedules and programme membership.
        let combined = WorkoutTemplate(name: title)
        modelContext.insert(combined)

        let firstExercises = cloneExercises(first.exercises ?? [])
        let secondExercises = cloneExercises(second.exercises ?? [])

        // Preserve supersets within each source, but do not accidentally
        // link copied exercises to their originals or to the other source.
        remapClonedSupersets(firstExercises)
        remapClonedSupersets(secondExercises)

        let allExercises = firstExercises + secondExercises
        for (index, exercise) in allExercises.enumerated() {
            exercise.orderIndex = index
        }
        combined.exercises = allExercises
        combined.updatedAt = Date()

        do {
            try modelContext.save()
            do {
                try programStore.addWorkout(combined.uuid)
            } catch {
                // Avoid saving an unattached workout when the programme
                // index cannot be updated.
                modelContext.delete(combined)
                try? modelContext.save()
                throw error
            }
            pendingCombinedWorkout = combined
            showingCombineWorkouts = false
        } catch {
            showProgramError(error)
        }
    }

    private func remapClonedSupersets(_ exercises: [SetDeckExercise]) {
        var groups: [UUID: UUID] = [:]
        for exercise in exercises {
            guard let oldID = exercise.supersetGroupID else { continue }
            if let newID = groups[oldID] {
                exercise.supersetGroupID = newID
            } else {
                let newID = UUID()
                groups[oldID] = newID
                exercise.supersetGroupID = newID
            }
        }
    }

    private func removeFromProgram(_ workout: WorkoutTemplate) {""",
    ),
]

# Apply changes in memory first. If the local source differs around a patch
# anchor, stop rather than overwriting or partially modifying the user's work.
modified = source
installed = []
for label, before, after in patches:
    if after in modified:
        continue  # Already installed: safe to rerun.
    count = modified.count(before)
    if count != 1:
        fail(f"Cannot safely place '{label}' (found {count} matching anchors). Nothing changed.")
    modified = modified.replace(before, after, 1)
    installed.append(label)

if modified != source:
    backup = HOME.with_name(
        HOME.name + "." + datetime.now().strftime("%Y%m%d-%H%M%S") + ".before-combine.bak"
    )
    shutil.copy2(HOME, backup)

    fd, temporary_path = tempfile.mkstemp(prefix=".workout-home-", dir=HOME.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(modified)
        os.chmod(temporary_path, stat.S_IMODE(HOME.stat().st_mode))
        os.replace(temporary_path, HOME)
    finally:
        if os.path.exists(temporary_path):
            os.unlink(temporary_path)
    print(f"Updated: {HOME.relative_to(ROOT)}")
    print(f"Backup: {backup.relative_to(ROOT)}")
else:
    print("Workout-library changes were already installed.")

if not NEW_VIEW.exists():
    NEW_VIEW.write_text(new_view_content, encoding="utf-8")
    print(f"Added: {NEW_VIEW.relative_to(ROOT)}")
else:
    print("Workout-combination sheet was already installed.")

print("\nDone! Rebuild ConsciousConnection in Xcode.")
print("No git branches were merged and no unrelated files were replaced.")
