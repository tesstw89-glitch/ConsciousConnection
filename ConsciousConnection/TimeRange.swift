import Foundation

struct TimeRange: Hashable, Codable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0

        let now = h * 60 + m
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute

        return now >= start && now <= end
    }
}
