import SwiftUI

struct SaturdayFocusCard: View {
    @ObservedObject var store: TimeFlexStore

    var currentRoom: SaturdayFocusRoom? {
        guard !SATURDAY_FOCUS_ROOMS.isEmpty else { return nil }
        return SATURDAY_FOCUS_ROOMS[store.data.satFocusIndex % SATURDAY_FOCUS_ROOMS.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saturday Focus").font(.custom("Poppins-SemiBold", size: 20)).foregroundStyle(.white)
            if let task = TASKS.first(where: { $0.id == "saturday_focus" }), let room = currentRoom {
                let done = TimeFlexEngine.getCount(task, data: store.data) > 0
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        BEMAnimatedCheckbox(isOn: Binding(
                            get: { TimeFlexEngine.getCount(task, data: store.data) > 0 },
                            set: { setDone(task, $0) }
                        ), size: 30).frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            Text(room.title).font(.custom("Poppins-SemiBold", size: 18))
                            Text(done ? "Done this week" : "Not done yet").font(.caption)
                        }.foregroundStyle(.white)
                        Spacer()
                    }
                    ForEach(room.tasks, id: \.self) { Text("• \($0)").foregroundStyle(.white.opacity(0.78)) }
                    HStack {
                        Button("Next room") { advanceRoom() }
                            .buttonStyle(.bordered).tint(.white)
                        Button("Mark done") { if !done { setDone(task, true) } }
                            .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                    }
                }
                .padding(16).background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.18)))
            }
        }
        .padding(18).frame(maxWidth: 350, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    func setDone(_ task: FlexTask, _ done: Bool) {
        store.data.monthlyCounts[task.id] = done ? task.target : 0
        if done { advanceRoom(save: false) }
        store.save()
    }
    func advanceRoom(save: Bool = true) {
        store.data.satFocusIndex = (store.data.satFocusIndex + 1) % SATURDAY_FOCUS_ROOMS.count
        if save { store.save() }
    }
}
