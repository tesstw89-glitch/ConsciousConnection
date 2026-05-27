import Foundation

final class WorkoutStore: ObservableObject {
    @Published private(set) var logs: [WorkoutLogEntry] = []
    @Published private(set) var templates: [WorkoutTemplateModel] = []

    private let logsStorageKey = "cc_workout_logs_v2"
    private let templatesStorageKey = "cc_workout_templates_v1"

    init() {
        loadLogs()
        loadTemplates()
    }

    func saveWorkout(day: WorkoutDay, blocks: [WorkoutBlockSessionState], endedEarly: Bool) {
        let entry = WorkoutLogEntry(
            date: Date(),
            scheduledDay: day,
            customTitle: nil,
            endedEarly: endedEarly,
            blocks: mapBlocksToLogs(blocks)
        )

        logs.insert(entry, at: 0)
        persistLogs()
    }

    func saveTemplateWorkout(templateName: String, blocks: [WorkoutBlockSessionState], endedEarly: Bool) {
        let entry = WorkoutLogEntry(
            date: Date(),
            scheduledDay: nil,
            customTitle: templateName,
            endedEarly: endedEarly,
            blocks: mapBlocksToLogs(blocks)
        )

        logs.insert(entry, at: 0)
        persistLogs()
    }

    func workouts(on date: Date) -> [WorkoutLogEntry] {
        logs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func hasWorkout(on date: Date) -> Bool {
        workouts(on: date).isEmpty == false
    }

    func addTemplate(_ template: WorkoutTemplateModel) {
        templates.insert(template, at: 0)
        persistTemplates()
    }

    func updateTemplate(_ template: WorkoutTemplateModel) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
        persistTemplates()
    }

    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        persistTemplates()
    }

    func template(with id: UUID) -> WorkoutTemplateModel? {
        templates.first { $0.id == id }
    }

    private func mapBlocksToLogs(_ blocks: [WorkoutBlockSessionState]) -> [WorkoutBlockLog] {
        blocks.map { block in
            WorkoutBlockLog(
                title: block.title,
                exercises: block.exercises.map { exercise in
                    WorkoutExerciseLog(
                        title: exercise.title,
                        skipped: exercise.skipped,
                        sets: exercise.sets.map { set in
                            WorkoutSetLog(
                                targetText: set.targetText,
                                metric: set.metric,
                                actualValue: set.actualValue,
                                completed: set.completed,
                                skipped: set.skipped
                            )
                        }
                    )
                }
            )
        }
    }

    private func persistLogs() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: logsStorageKey)
        } catch {
            print("Failed to save workout logs: \(error)")
        }
    }

    private func persistTemplates() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: templatesStorageKey)
        } catch {
            print("Failed to save workout templates: \(error)")
        }
    }

    private func loadLogs() {
        guard let data = UserDefaults.standard.data(forKey: logsStorageKey) else { return }

        do {
            logs = try JSONDecoder().decode([WorkoutLogEntry].self, from: data)
        } catch {
            print("Failed to load workout logs: \(error)")
        }
    }

    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: templatesStorageKey) else { return }

        do {
            templates = try JSONDecoder().decode([WorkoutTemplateModel].self, from: data)
        } catch {
            print("Failed to load workout templates: \(error)")
        }
    }
}
