import Foundation
import Observation

// Programme membership only. Existing SwiftData workouts, schedules, exercises,
// video URLs, GIF URLs, and media files are not changed by this store.
struct StrengthLabProgram: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var workoutIDs: [UUID] = []
    var scheduleIDs: [UUID] = []
}

private struct StrengthLabProgramSnapshot: Codable {
    var version: Int = 1
    var activeID: UUID
    var programs: [StrengthLabProgram]
}

private enum StrengthLabProgramError: LocalizedError {
    case unavailable(String)
    case missingProgram
    case emptyName
    case duplicateName
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "The saved programme index could not be read: \(reason). No programme data has been overwritten."
        case .missingProgram:
            return "The selected programme no longer exists."
        case .emptyName:
            return "Enter a programme name."
        case .duplicateName:
            return "A programme with that name already exists."
        case .unsupportedVersion:
            return "This programme index was created by another version of StrengthLab."
        }
    }
}

@MainActor
@Observable
final class StrengthLabProgramStore {
    static let shared = StrengthLabProgramStore()

    private(set) var programs: [StrengthLabProgram] = []
    private(set) var activeID: UUID?
    private var loadFailure: String?

    private init() {
        do {
            let url = try Self.indexURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let snapshot = try JSONDecoder().decode(
                StrengthLabProgramSnapshot.self,
                from: Data(contentsOf: url)
            )
            guard snapshot.version == 1 else { throw StrengthLabProgramError.unsupportedVersion }
            programs = snapshot.programs
            activeID = snapshot.activeID
        } catch {
            loadFailure = error.localizedDescription
        }
    }

    var activeProgram: StrengthLabProgram? {
        programs.first(where: { $0.id == activeID }) ?? programs.first
    }

    func containsWorkout(_ id: UUID) -> Bool {
        activeProgram?.workoutIDs.contains(id) ?? false
    }

    func containsSchedule(_ id: UUID) -> Bool {
        activeProgram?.scheduleIDs.contains(id) ?? false
    }

    func scheduleIsReferenced(_ id: UUID) -> Bool {
        programs.contains { $0.scheduleIDs.contains(id) }
    }

    // Initial migration runs AFTER the pre-existing app V2 programme seed.
    // It captures all existing workout/schedule IDs exactly once, in place.
    func prepare(workouts: [WorkoutTemplate], schedules: [WorkoutSchedule]) throws {
        try ensureReadable()
        guard programs.isEmpty else { return }
        let initial = StrengthLabProgram(
            name: "Dumbbell Strength",
            workoutIDs: workouts.map(\.uuid),
            scheduleIDs: schedules.map(\.uuid)
        )
        try commit([initial], active: initial.id)
    }

    func create(name: String) throws {
        try ensureReadable()
        let title = try validatedName(name, excluding: nil)
        var updated = programs
        let newProgram = StrengthLabProgram(name: title)
        updated.append(newProgram)
        try commit(updated, active: newProgram.id)
    }

    func activate(_ id: UUID) throws {
        try ensureReadable()
        guard programs.contains(where: { $0.id == id }) else {
            throw StrengthLabProgramError.missingProgram
        }
        try commit(programs, active: id)
    }

    func renameActive(_ name: String) throws {
        try ensureReadable()
        guard let program = activeProgram,
              let index = programs.firstIndex(where: { $0.id == program.id }) else {
            throw StrengthLabProgramError.missingProgram
        }
        let title = try validatedName(name, excluding: program.id)
        var updated = programs
        updated[index].name = title
        try commit(updated, active: program.id)
    }

    // Existing workouts can be linked to multiple programmes without copying
    // or deleting exercise models or their imported video/GIF references.
    func addWorkout(_ id: UUID) throws {
        try editActive { program in
            if !program.workoutIDs.contains(id) { program.workoutIDs.append(id) }
        }
    }

    func removeWorkout(_ id: UUID) throws {
        try editActive { program in
            program.workoutIDs.removeAll { $0 == id }
        }
    }

    func addSchedule(_ id: UUID) throws {
        try editActive { program in
            if !program.scheduleIDs.contains(id) { program.scheduleIDs.append(id) }
        }
    }

    func removeSchedule(_ id: UUID) throws {
        try editActive { program in
            program.scheduleIDs.removeAll { $0 == id }
        }
    }

    private func editActive(_ edit: (inout StrengthLabProgram) -> Void) throws {
        try ensureReadable()
        guard let program = activeProgram,
              let index = programs.firstIndex(where: { $0.id == program.id }) else {
            throw StrengthLabProgramError.missingProgram
        }
        var updated = programs
        edit(&updated[index])
        try commit(updated, active: program.id)
    }

    private func validatedName(_ value: String, excluding id: UUID?) throws -> String {
        let title = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw StrengthLabProgramError.emptyName }
        if programs.contains(where: {
            $0.id != id && $0.name.localizedCaseInsensitiveCompare(title) == .orderedSame
        }) { throw StrengthLabProgramError.duplicateName }
        return title
    }

    private func ensureReadable() throws {
        if let loadFailure { throw StrengthLabProgramError.unavailable(loadFailure) }
    }

    private static func indexURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appendingPathComponent("StrengthLabPrograms-v1.json")
    }

    private func commit(_ updated: [StrengthLabProgram], active: UUID) throws {
        try ensureReadable()
        let url = try Self.indexURL()
        let snapshot = StrengthLabProgramSnapshot(activeID: active, programs: updated)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
        // Publish only after a successful atomic disk write.
        programs = updated
        activeID = active
    }
}
