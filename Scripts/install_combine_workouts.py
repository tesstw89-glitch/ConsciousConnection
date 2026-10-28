#!/usr/bin/env python3
"""Safely install StrengthLab's Combine Workouts feature in a local checkout.

Run from the ConsciousConnection repository root, after fetching the latest
origin/main. Installs the workout picker into WorkoutLibraryHomeView.swift
rather than as a new Swift source file (which some cached Xcode/SwiftPM
project graphs fail to detect). Does not merge branches or touch other files.
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
REMOTE_HOME = (ROUTINE / "WorkoutLibraryHomeView.swift").as_posix()
SHEET_MARKER = "// MARK: - Combine Workouts (kept in this compiled file for Xcode/SPM)"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


if not HOME.is_file():
    fail("Run this script from the root of ~/Desktop/ConsciousConnection.")

try:
    latest_home = subprocess.check_output(
        ["git", "show", f"FETCH_HEAD:{REMOTE_HOME}"],
        cwd=ROOT,
        text=True,
        stderr=subprocess.PIPE,
    )
except (OSError, subprocess.CalledProcessError):
    fail("The GitHub feature source was not found. Run 'git fetch origin main' first.")

if latest_home.count(SHEET_MARKER) != 1:
    fail("The fetched GitHub source is missing the embedded workout picker. Nothing changed.")
sheet_source = latest_home.split(SHEET_MARKER, 1)[1].strip()
if sheet_source.count("struct WorkoutCombineSheet: View {") != 1:
    fail("Unexpected workout picker source. Nothing changed.")

source = HOME.read_text(encoding="utf-8")
if NEW_VIEW.exists():
    original_sheet = NEW_VIEW.read_text(encoding="utf-8").strip()
    if original_sheet != ("import SwiftUI\n\n" + sheet_source).strip():
        fail(f"{NEW_VIEW.relative_to(ROOT)} has local changes; not moving it automatically.")

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

if SHEET_MARKER not in modified:
    modified = modified.rstrip() + "\n\n" + SHEET_MARKER + "\n\n" + sheet_source + "\n"

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

if NEW_VIEW.exists():
    # Keep a backup of the old standalone source, but remove its .swift
    # extension to avoid duplicate declarations if Xcode rescans sources.
    archived = NEW_VIEW.with_name(NEW_VIEW.name + ".before-inline.bak")
    if archived.exists():
        archived = NEW_VIEW.with_name(
            NEW_VIEW.name + "." + datetime.now().strftime("%Y%m%d-%H%M%S") + ".bak"
        )
    NEW_VIEW.rename(archived)
    print(f"Archived old standalone sheet: {archived.relative_to(ROOT)}")

print("\nDone! Rebuild ConsciousConnection in Xcode.")
print("No git branches were merged and no unrelated files were replaced.")
