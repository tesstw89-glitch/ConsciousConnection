import SwiftUI

struct CustomTaskListsView: View {
    @ObservedObject var store = CustomTaskListStore.shared
    @State var showingNewList = false
    @State var listToAddTaskTo: CustomTaskList?

    var body: some View {
        ZStack {
            Image("WeeklyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.22).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    introCard
                    if store.lists.isEmpty { emptyState }
                    else { ForEach(store.lists) { listCard($0) } }
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Custom Lists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewList = true } label: {
                    Label("New list", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewList) {
            NewCustomListSheet { name in
                if let list = store.createList(named: name) { listToAddTaskTo = list }
            }
        }
        .sheet(item: $listToAddTaskTo) { AddCustomTaskSheet(list: $0) }
        .onAppear { store.ensureDailyReset() }
    }

    var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREATE YOUR OWN CUSTOM LIST")
                .font(.custom("Poppins-SemiBold", size: 12)).tracking(1.6)
                .foregroundStyle(.white.opacity(0.74))
            Text("Build a list for the day")
                .font(.custom("Poppins-SemiBold", size: 28)).foregroundStyle(.white)
            Text("Add reusable tasks, then tap their circles to tick them off for today.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(.white.opacity(0.76))
        }
        .padding(18).frame(maxWidth: 350, alignment: .leading)
        .background(customCardBackground).overlay(customCardStroke)
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 38)).foregroundStyle(.white.opacity(0.9))
            Text("No custom lists yet")
                .font(.custom("Poppins-SemiBold", size: 20)).foregroundStyle(.white)
            Button("New List") { showingNewList = true }
                .buttonStyle(CustomListPrimaryButtonStyle())
        }
        .padding(24).frame(maxWidth: 350)
        .background(customCardBackground).overlay(customCardStroke)
    }

    func listCard(_ list: CustomTaskList) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.name).font(.custom("Poppins-SemiBold", size: 21)).foregroundStyle(.white)
                    Text("\(completedCount(in: list))/\(list.tasks.count) done today")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Button { listToAddTaskTo = list } label: {
                    Image(systemName: "plus").font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black).frame(width: 38, height: 38)
                        .background(Color.white).clipShape(Circle())
                }
            }

            if list.tasks.isEmpty {
                Text("Tap + to add the first task.").foregroundStyle(.white.opacity(0.7))
            } else {
                ForEach(list.tasks) { task in taskRow(task, in: list) }
            }
        }
        .padding(18).frame(maxWidth: 350, alignment: .leading)
        .background(customCardBackground).overlay(customCardStroke)
        .contextMenu {
            Button(role: .destructive) { store.deleteList(id: list.id) } label: {
                Label("Delete list", systemImage: "trash")
            }
        }
    }

    func taskRow(_ task: CustomTask, in list: CustomTaskList) -> some View {
        let done = store.completedTaskIDs.contains(task.id)
        return HStack(spacing: 12) {
            Button { store.toggleCompletion(taskID: task.id) } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle").font(.system(size: 26))
            }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.custom("Poppins-Medium", size: 16)).strikethrough(done)
                Text("\(task.minutes) mins").font(.caption).foregroundStyle(.white.opacity(0.62))
            }.foregroundStyle(.white).opacity(done ? 0.62 : 1)
            Spacer()
            Button(role: .destructive) { store.deleteTask(task.id, from: list.id) } label: {
                Image(systemName: "trash").foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(done ? 0.10 : 0.18)))
    }

    func completedCount(in list: CustomTaskList) -> Int {
        list.tasks.filter { store.completedTaskIDs.contains($0.id) }.count
    }

    var customCardBackground: some View {
        RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.24))
    }
    var customCardStroke: some View {
        RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 1)
    }
}
