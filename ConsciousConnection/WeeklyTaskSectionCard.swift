import SwiftUI

struct WeeklyTaskSectionCard: View {
    let title: String
    let tasks: [FlexTask]
    @ObservedObject var store: TimeFlexStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.custom("Poppins-SemiBold", size: 20)).foregroundStyle(.white)
            VStack(spacing: 12) { ForEach(tasks) { taskRow($0) } }
        }
        .padding(18).frame(maxWidth: 350, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    func taskRow(_ task: FlexTask) -> some View {
        let count = TimeFlexEngine.getCount(task, data: store.data)
        return VStack(alignment: .leading, spacing: 12) {
            Text(task.title).font(.custom("Poppins-Medium", size: 17)).foregroundStyle(.white)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<task.target, id: \.self) { index in
                    BEMAnimatedCheckbox(
                        isOn: Binding(
                            get: { index < TimeFlexEngine.getCount(task, data: store.data) },
                            set: { setCount(task, to: $0 ? index + 1 : index) }
                        ), size: 26
                    ).frame(width: 26, height: 26)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(count)/\(task.target)").font(.caption).foregroundStyle(.white.opacity(0.68))
                    if let hint = weekdayHint(task) {
                        Text(hint).font(.caption2).foregroundStyle(.white.opacity(0.52))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.18)))
    }

    func setCount(_ task: FlexTask, to value: Int) {
        let newValue = max(0, min(value, task.target))
        switch task.scope {
        case .daily: store.data.dailyCounts[task.id] = newValue
        case .weekly: store.data.weeklyCounts[task.id] = newValue
        case .monthly: store.data.monthlyCounts[task.id] = newValue
        }
        store.save(); store.ensureResets()
    }

    func weekdayHint(_ task: FlexTask) -> String? {
        guard !task.weekdays.isEmpty else { return nil }
        let names = task.weekdays.map {
            [1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday", 5: "Thursday", 6: "Friday", 7: "Saturday"][$0.rawValue]!
        }
        return names.count == 1 ? "usually on a \(names[0])" : "usually on \(names.joined(separator: " & "))"
    }
}
