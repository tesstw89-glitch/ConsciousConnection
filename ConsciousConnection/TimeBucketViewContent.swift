import SwiftUI

extension TimeBucketView {
    var heading: some View {
        VStack(spacing: 6) {
            if isRandomMode {
                Text("Random").font(.custom("Didot", size: 52))
                Text(usesCustomList ? "custom task" : "task").font(.custom("Didot", size: 26))
            } else {
                Text("\(minutes)").font(.custom("Didot", size: 58))
                Text(minutes == 1 ? "minute" : "minutes").font(.custom("Didot", size: 26))
            }
            if let active = customStore.activeList {
                Text(active.name).font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }.foregroundStyle(.white)
    }

    @ViewBuilder var taskContent: some View {
        if usesCustomList {
            if let task = currentCustomTasks().first {
                taskCard(title: task.title) { swap(customTask: task) }
            } else {
                emptyCard(isRandomMode ? "There are no unfinished tasks left in this custom list."
                          : "There are no unfinished \(minutes)-minute tasks in this custom list.")
            }
        } else {
            let tasks = currentTasks()
            if tasks.isEmpty { emptyCard("You’ve worked hard enough.") }
            else if tasks.indices.contains(currentIndex) {
                taskCard(title: tasks[currentIndex].title) { swap(task: tasks[currentIndex]) }
            }
        }
    }

    func taskCard(title: String, onSwap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("YOUR TASK").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.72))
            Text(title).font(.system(size: 30, weight: .medium, design: .rounded)).foregroundStyle(.white)
            HStack { Spacer(); Button("Swap", action: onSwap).buttonStyle(TimeBucketGhostButtonStyle()) }
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 30).fill(Color.black.opacity(0.26)))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.16), lineWidth: 1))
        .padding(.horizontal, 22)
    }

    func emptyCard(_ message: String) -> some View {
        VStack(spacing: 10) {
            Text("None for today").font(.custom("Didot", size: 34))
            Text(message).font(.system(size: 20, design: .rounded)).multilineTextAlignment(.center)
        }
        .foregroundStyle(.white).padding(26).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color.black.opacity(0.24)))
        .padding(.horizontal, 22)
    }
}

struct TimeBucketMainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 19, weight: .semibold, design: .rounded))
            .foregroundStyle(.white).padding(.vertical, 14).padding(.horizontal, 24)
            .frame(minWidth: 140)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.32)))
    }
}

struct TimeBucketGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.white).padding(.vertical, 12).padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.22)))
    }
}
