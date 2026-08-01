import SwiftUI

extension AddCustomTaskSheet {
    var existingTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose from your usual tasks").font(.headline)
            TextField("Search tasks", text: $existingTaskSearch).textFieldStyle(.roundedBorder)
            LazyVStack(spacing: 8) {
                ForEach(filteredBuiltInTasks) { task in
                    let selected = selectedBuiltInTaskIDs.contains(task.id)
                    Button {
                        selectedBuiltInTaskIDs.insert(task.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title).foregroundStyle(.primary)
                                Text("\(task.minutes) mins").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
