import SwiftUI

extension AddCustomTaskSheet {
    var newTaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task").font(.headline)
            TextField("Write the task", text: $title, axis: .vertical)
                .textFieldStyle(.roundedBorder).lineLimit(2...4)
        }
    }

    var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62), spacing: 10)], spacing: 10) {
                ForEach(CustomTaskListStore.allowedDurations, id: \.self) { minutes in
                    Button { selectedMinutes = minutes } label: {
                        Text("\(minutes)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .foregroundStyle(selectedMinutes == minutes ? .white : .primary)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMinutes == minutes ? Color.accentColor : Color.secondary.opacity(0.14)))
                    }.buttonStyle(.plain)
                }
            }
            Text("minutes").font(.caption).foregroundStyle(.secondary)
        }
    }
}
