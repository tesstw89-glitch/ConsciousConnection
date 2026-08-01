import SwiftUI

struct WeeklyTasksView: View {
    @StateObject var store = TimeFlexStore()
    @ObservedObject var customStore = CustomTaskListStore.shared
    @State var showingCustomListPicker = false

    var dailyTasks: [FlexTask] { TASKS.filter { $0.scope == .daily && $0.id != "saturday_focus" } }
    var weeklyTasks: [FlexTask] { TASKS.filter { $0.scope == .weekly && $0.id != "saturday_focus" } }

    var body: some View {
        ZStack {
            Image("WeeklyBackground").resizable().scaledToFill().ignoresSafeArea()
            LinearGradient(colors: [.black.opacity(0.22), .black.opacity(0.12), .black.opacity(0.28)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerCard
                    customListSwitchButton
                    WeeklyTaskSectionCard(title: "Daily Tasks", tasks: dailyTasks, store: store)
                    WeeklyTaskSectionCard(title: "Weekly Tasks", tasks: weeklyTasks, store: store)
                    SaturdayFocusCard(store: store)
                }
                .frame(maxWidth: .infinity).padding(.top, 88)
                .padding(.horizontal, 16).padding(.bottom, 36)
            }
        }
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Create your own custom list") { CustomTaskListsView() }
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .sheet(isPresented: $showingCustomListPicker) { CustomListPickerSheet() }
        .onAppear { store.ensureResets(); customStore.ensureDailyReset() }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEKLY TASKS").font(.custom("Poppins-SemiBold", size: 12)).tracking(2)
            Text("Keep the rhythm going").font(.custom("Poppins-SemiBold", size: 30))
            Text("Tap the circles to tick things off.")
                .font(.custom("Poppins-Regular", size: 14)).foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white).padding(18).frame(maxWidth: 350, alignment: .leading)
        .background(weeklyCardBackground).overlay(weeklyCardStroke)
    }

    var customListSwitchButton: some View {
        Button {
            if customStore.isCustomListActive { customStore.deactivate() }
            else { showingCustomListPicker = true }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: customStore.isCustomListActive ? "xmark.circle.fill" : "arrow.triangle.2.circlepath")
                VStack(alignment: .leading, spacing: 2) {
                    Text(customStore.isCustomListActive ? "Switch off custom list" : "Switch to custom list")
                        .font(.custom("Poppins-SemiBold", size: 16))
                    if let active = customStore.activeList {
                        Text("Currently using: \(active.name)").font(.caption).foregroundStyle(.white.opacity(0.68))
                    }
                }
                Spacer()
                if !customStore.isCustomListActive { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(.white).padding(16).frame(maxWidth: 350)
            .background(RoundedRectangle(cornerRadius: 18)
                .fill(customStore.isCustomListActive ? Color.white.opacity(0.20) : Color.black.opacity(0.24)))
        }.buttonStyle(.plain)
    }

    var weeklyCardBackground: some View {
        RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.22))
    }
    var weeklyCardStroke: some View {
        RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 1)
    }
}
