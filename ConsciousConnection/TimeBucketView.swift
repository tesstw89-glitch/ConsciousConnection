import SwiftUI

struct TimeBucketView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject var store = TimeFlexStore()
    @ObservedObject var customStore = CustomTaskListStore.shared
    @State var currentIndex = 0

    let minutes: Int
    var isRandomMode: Bool { minutes == 0 }
    var suggestionKey: String { isRandomMode ? "timeRandomIds" : "time\(minutes)Ids" }
    var usesCustomList: Bool { customStore.isCustomListActive }
    var hasCurrentTask: Bool {
        usesCustomList ? !currentCustomTasks().isEmpty : !currentTasks().isEmpty
    }

    var body: some View {
        ZStack {
            Image("TimeBucketBackground").resizable().scaledToFill().ignoresSafeArea()
            Color.black.opacity(0.14).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer(minLength: 30)
                heading
                taskContent
                Button("Done") { markDone() }
                    .buttonStyle(TimeBucketMainButtonStyle())
                    .disabled(!hasCurrentTask).opacity(hasCurrentTask ? 1 : 0.45)
                Button("Home") { router.goHome() }.buttonStyle(TimeBucketGhostButtonStyle())
                Spacer()
            }
        }
        .onAppear { ensureSuggestion() }
        .onChange(of: customStore.activeListID) { _, _ in ensureSuggestion() }
        .navigationBarBackButtonHidden(true)
    }

    func currentTasks() -> [FlexTask] {
        let ids = store.data.currentSuggestions[suggestionKey] ?? []
        return ids.compactMap { id in TASKS.first(where: { $0.id == id }) }
    }
    func currentCustomTasks() -> [CustomTask] { customStore.tasks(for: suggestionKey) }
}
