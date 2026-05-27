import SwiftUI
import SwiftData

struct HabitFlowRootView: View {
    @AppStorage("habitFlowHasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .task {
            await authManager.checkCredentialState()
        }
    }
}

