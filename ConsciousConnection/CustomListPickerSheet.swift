import SwiftUI

struct CustomListPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store = CustomTaskListStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if store.lists.isEmpty {
                    ContentUnavailableView("No custom lists", systemImage: "list.bullet.rectangle",
                        description: Text("Create a list first, then return here to switch it on."))
                } else {
                    List(store.lists) { list in
                        Button { store.activate(list.id); dismiss() } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(list.name).font(.headline)
                                    Text("\(list.tasks.count) \(list.tasks.count == 1 ? "task" : "tasks")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if store.activeListID == list.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                        }.disabled(list.tasks.isEmpty)
                    }
                }
            }
            .navigationTitle("Choose a custom list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }.presentationDetents([.medium, .large])
    }
}
