import Foundation

struct TimeFlexData: Codable {
    var dailyDate: String = ""
    var weekKey: String = ""
    var monthKey: String = ""

    var dailyCounts: [String:Int] = [:]
    var weeklyCounts: [String:Int] = [:]
    var monthlyCounts: [String:Int] = [:]

    // suggestions cache (like data.current[...] in Scriptable)
    var currentSuggestions: [String:[String]] = [:] // e.g. "time10Ids" -> ["id1","id2"]
    var currentSingle: [String:String] = [:]        // e.g. "time2Id" -> "water_drink"

    var satFocusIndex: Int = 0
    var saturdayFocusRoomIndex: Int = 0
    var saturdayFocusDoneWeekKey: String = ""

}

final class TimeFlexStore: ObservableObject {
    @Published var data: TimeFlexData
    private let url: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.url = docs.appendingPathComponent("timeflex.json")
        self.data = Self.load(from: url)
        ensureResets()
    }

    func ensureResets() {
        var d = data
        let tKey = Self.todayKey()
        let wKey = Self.isoWeekKey()
        let mKey = Self.monthKey()

        if d.dailyDate != tKey { d.dailyDate = tKey; d.dailyCounts = [:]; d.currentSuggestions = [:]; d.currentSingle = [:] }
        if d.weekKey  != wKey { d.weekKey  = wKey;  d.weeklyCounts = [:] }
        if d.monthKey != mKey { d.monthKey = mKey; d.monthlyCounts = [:] }

        data = d
        save()
    }

    func save() {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url, options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    private static func load(from url: URL) -> TimeFlexData {
        guard let raw = try? Data(contentsOf: url) else { return TimeFlexData() }
        return (try? JSONDecoder().decode(TimeFlexData.self, from: raw)) ?? TimeFlexData()
    }

    static func todayKey(_ date: Date = Date()) -> String {
        // like JS `toDateString()`
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "EEE MMM dd yyyy"
        return f.string(from: date)
    }

    static func monthKey(_ date: Date = Date()) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return "\(y)-" + String(format: "%02d", m)
    }

    // ISO week key like "2026-W07"
    static func isoWeekKey(_ date: Date = Date()) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let y = cal.component(.yearForWeekOfYear, from: date)
        let w = cal.component(.weekOfYear, from: date)
        return "\(y)-W" + String(format: "%02d", w)
    }
}
