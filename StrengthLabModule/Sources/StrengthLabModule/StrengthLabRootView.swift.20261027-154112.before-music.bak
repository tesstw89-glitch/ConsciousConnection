import SwiftUI
import SwiftData

/// StrengthLab embedded in ConsciousConnection (not a second app).
@MainActor
public struct StrengthLabRootView: View {
    private let container: ModelContainer?
    private let errorText: String?

    public init() {
        // A separate on-disk store protects ConsciousConnection's habit data.
        // Never create an empty replacement database before the backed-up data arrives.
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        for folder in [
            "StrengthLab/ExerciseDemos",
            "StrengthLab/ExerciseGIFs",
            "StrengthLab/ImportedVideos",
            "StrengthLab/EditedGIFs",
            "WorkoutCovers"
        ] {
            try? fm.createDirectory(at: support.appendingPathComponent(folder),
                                    withIntermediateDirectories: true)
        }
        let storeURL = support.appendingPathComponent("StrengthLabImported.store")
        guard fm.fileExists(atPath: storeURL.path) else {
            container = nil
            errorText = "Your workout backup is prepared but not yet installed. Keep the original StrengthLab app and follow the migration transfer instructions."
            return
        }

        do {
            let schema = Schema([
                SetDeckExercise.self,
                SetDeckRoutine.self,
                SetDeckSet.self,
                SetDeckSetHistory.self,
                WorkoutTemplate.self,
                WorkoutSchedule.self
            ])
            let configuration = ModelConfiguration(
                "StrengthLabImported",
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
            errorText = nil
        } catch {
            container = nil
            errorText = error.localizedDescription
        }
    }

    public var body: some View {
        Group {
            if let container {
                StrengthLabEmbeddedHome()
                    .modelContainer(container)
            } else {
                ContentUnavailableView(
                    errorText?.contains("not yet installed") == true ? "StrengthLab migration pending" : "StrengthLab couldn't open",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorText ?? "Unable to open the workout database.")
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

@MainActor
private struct StrengthLabEmbeddedHome: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exerciseManager: ExerciseManager?
    @State private var achievementManager: AchievementManager?
    @State private var healthManager = HealthManager()
    @State private var cloudSyncManager = CloudSyncManager()
    @State private var pendingDeepLink: DeepLink?

    var body: some View {
        Group {
            if let exerciseManager {
                MainView(pendingDeepLink: $pendingDeepLink)
                    .environment(exerciseManager)
                    .environment(healthManager)
                    .environment(cloudSyncManager)
                    .environment(achievementManager)
            } else {
                ProgressView("Preparing StrengthLab…")
            }
        }
        .task {
            guard exerciseManager == nil else { return }
            StrengthLabMigrationPreferences.applyIfNeeded()
            StrengthLabMediaPaths.relinkStoredMedia(in: modelContext)
            let manager = ExerciseManager(context: modelContext)
            let achievements = AchievementManager(exerciseManager: manager)
            achievementManager = achievements
            exerciseManager = manager
        }
    }
}


/// Restore only StrengthLab-specific preferences, once, from the original app.
/// Deliberately don't carry across LAN media-server URLs or unrelated settings.
@MainActor
private enum StrengthLabMigrationPreferences {
    static func applyIfNeeded() {
        let defaults = UserDefaults.standard
        let marker = "strengthlab.embedded.didRestorePreferencesV1"
        guard !defaults.bool(forKey: marker) else { return }
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                     in: .userDomainMask).first else { return }
        let url = support.appendingPathComponent("StrengthLabImportPreferences.plist")
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = plist as? [String: Any] else { return }

        for key in [
            "useMetricUnits", "useDayMonthYearDates", "isSetDeckOnboardingComplete",
            "strengthlab.didMigrateDayRoutinesToWorkoutTemplatesV1",
            "strengthlab.didSeedHomeDumbbellProgrammeV1",
            "strengthlab.didReprogramHomeDumbbellProgrammeV2",
            "celebratedAchievements"
        ] {
            if let value = dictionary[key] {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(true, forKey: marker)
        print("[StrengthLab Migration] Restored supported original app preferences.")
    }
}
