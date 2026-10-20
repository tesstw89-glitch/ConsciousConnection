import SwiftUI
import SwiftData

/// StrengthLab embedded in ConsciousConnection (not a second app).
@MainActor
public struct StrengthLabRootView: View {
    private let container: ModelContainer?
    private let errorText: String?

    public init() {
        do {
            let schema = Schema([
                SetDeckExercise.self,
                SetDeckRoutine.self,
                SetDeckSet.self,
                SetDeckSetHistory.self
            ])
            let configuration = ModelConfiguration(
                "StrengthLabEmbedded",
                schema: schema,
                isStoredInMemoryOnly: false,
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
                    "StrengthLab couldn't open",
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
            let manager = ExerciseManager(context: modelContext)
            let achievements = AchievementManager(exerciseManager: manager)
            achievementManager = achievements
            exerciseManager = manager
        }
    }
}
