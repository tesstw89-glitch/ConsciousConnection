import Foundation

enum TaskScope: String, Codable {
    case daily, weekly, monthly
}

enum TaskWeekday: Int, Codable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var isWorkday: Bool {
        self == .monday || self == .friday
    }

    static func from(_ date: Date, calendar: Calendar = .current) -> TaskWeekday? {
        let weekdayNumber = calendar.component(.weekday, from: date)
        return TaskWeekday(rawValue: weekdayNumber)
    }
}

enum TaskWorkdayRule: String, Codable, Hashable {
    case nonWorkdayOnly   // default
    case anyDay           // can appear on workdays too
    case workdayOnly      // Monday / Friday only
}

struct TaskTimeWindow: Codable, Hashable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int

    init(startHour: Int, startMinute: Int = 0, endHour: Int, endMinute: Int = 0) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }

        return nowMinutes >= startMinutes || nowMinutes < endMinutes
    }
}

struct FlexTask: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let minutes: Int
    let scope: TaskScope
    let target: Int
    let timeWindows: [TaskTimeWindow]
    let weekdays: [TaskWeekday]
    let workdayRule: TaskWorkdayRule

    init(
        id: String,
        title: String,
        minutes: Int,
        scope: TaskScope,
        target: Int,
        timeWindows: [TaskTimeWindow] = [],
        weekdays: [TaskWeekday] = [],
        workdayRule: TaskWorkdayRule = .nonWorkdayOnly
    ) {
        self.id = id
        self.title = title
        self.minutes = minutes
        self.scope = scope
        self.target = target
        self.timeWindows = timeWindows
        self.weekdays = weekdays
        self.workdayRule = workdayRule
    }

    func isAvailable(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let timeOK: Bool = {
            guard !timeWindows.isEmpty else { return true }
            return timeWindows.contains { $0.contains(date, calendar: calendar) }
        }()

        let weekdayOK: Bool = {
            guard !weekdays.isEmpty else { return true }
            guard let today = TaskWeekday.from(date, calendar: calendar) else { return false }
            return weekdays.contains(today)
        }()

        let workdayOK: Bool = {
            guard let today = TaskWeekday.from(date, calendar: calendar) else { return false }

            switch workdayRule {
            case .anyDay:
                return true
            case .nonWorkdayOnly:
                return !today.isWorkday
            case .workdayOnly:
                return today.isWorkday
            }
        }()

        return timeOK && weekdayOK && workdayOK
    }
}

// Keep the name TASKS so the rest of your app can use it
let TASKS: [FlexTask] = [

    // MARK: - Daily

    // I'm awake
    FlexTask(id: "awake_gratitude3", title: "Gratitude — write 3 things", minutes: 2, scope: .daily, target: 1),
    FlexTask(id: "awake_dance", title: "Put on music and DANCE!", minutes: 5, scope: .daily, target: 1),
    FlexTask(id: "awake_breakfast", title: "Breakfast", minutes: 15, scope: .daily, target: 1),
    FlexTask(id: "awake_make_bed", title: "Make the bed", minutes: 5, scope: .daily, target: 1),

    // Work day morning
    FlexTask(
        id: "workday_gratitude_meditation",
        title: "Gratitude meditation",
        minutes: 5,
        scope: .daily,
        target: 1,
        workdayRule: .workdayOnly
    ),

    // 2-minute tasks
    FlexTask(id: "water_drink", title: "Drink Water", minutes: 2, scope: .daily, target: 8),
    FlexTask(id: "quick_stretch", title: "Quick Stretch", minutes: 2, scope: .daily, target: 3),


    // 5-minute tasks
    FlexTask(id: "rearrange_cushions", title: "Rearrange cushions (living room)", minutes: 5, scope: .daily, target: 1),

    FlexTask(
        id: "gratitude_touchtone_1",
        title: "Gratitude Touch stone (10–11am)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 10, endHour: 11)]
    ),

    FlexTask(
        id: "gratitude_touchtone_2",
        title: "Gratitude Touch stone (2–3pm)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 14, endHour: 15)]
    ),

    FlexTask(
        id: "gratitude_touchtone_3",
        title: "Gratitude Touch stone (6–7pm)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 18, endHour: 19)]
    ),

    FlexTask(id: "clear_bedroom_floor", title: "Clear bedroom floor", minutes: 5, scope: .daily, target: 1),

    FlexTask(
        id: "put_on_load_am",
        title: "Put on a load of washing (AM)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 0, endHour: 12)]
    ),

    FlexTask(
        id: "vitamins_pm",
        title: "Take Vitamins & Drink Water (PM)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 12, endHour: 24)],
        workdayRule: .anyDay
    ),

    FlexTask(
        id: "clean_highchair_1",
        title: "Clean highchair (10–12)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 10, endHour: 12)]
    ),

    FlexTask(
        id: "clean_highchair_2",
        title: "Clean highchair (19:30–20:30)",
        minutes: 5,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 19, startMinute: 30, endHour: 20, endMinute: 30)],
        workdayRule: .anyDay
    ),

    // 10-minute tasks
    FlexTask(
        id: "dining_table_am",
        title: "Clear & clean dining table (AM)",
        minutes: 10,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 0, endHour: 12)]
    ),

    FlexTask(
        id: "dining_table_pm",
        title: "Clear & clean dining table (PM)",
        minutes: 10,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 12, endHour: 24)],
        workdayRule: .anyDay
    ),

    FlexTask(
        id: "kitchen_surface",
        title: "Clean kitchen work surface + hob",
        minutes: 10,
        scope: .daily,
        target: 1,
        workdayRule: .anyDay
    ),

    FlexTask(
        id: "french_vocab",
        title: "French vocab review",
        minutes: 10,
        scope: .daily,
        target: 1,
        workdayRule: .anyDay
    ),

    FlexTask(
        id: "spanish_phrase",
        title: "Spanish phrase review",
        minutes: 10,
        scope: .daily,
        target: 1,
        workdayRule: .anyDay
    ),

    FlexTask(id: "music_riff", title: "Practice one music riff / groove", minutes: 10, scope: .daily, target: 1),

    FlexTask(
        id: "clean_toilet_sink",
        title: "Clean toilet & bathroom sink",
        minutes: 10,
        scope: .daily,
        target: 1,
        workdayRule: .anyDay
    ),

    FlexTask(id: "clean_bath", title: "Clean bath", minutes: 10, scope: .daily, target: 1),

    // 15-minute tasks
    FlexTask(id: "declutter_hallway", title: "Declutter the hallway", minutes: 15, scope: .daily, target: 1),
    FlexTask(
        id: "put_away_yday",
        title: "Put away yesterday’s laundry",
        minutes: 15,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 0, endHour: 15)]
    ),
    FlexTask(id: "splice_loops", title: "15-minute music Splice loop session", minutes: 15, scope: .daily, target: 1),
    FlexTask(id: "french_podcast", title: "Listen to 15 mins of a French podcast", minutes: 15, scope: .daily, target: 1),
    FlexTask(id: "spanish_podcast", title: "Listen to 15 mins of a Spanish podcast", minutes: 15, scope: .daily, target: 1),

    FlexTask(
        id: "wash_dishes_15",
        title: "Wash Dishes",
        minutes: 15,
        scope: .daily,
        target: 2,
        workdayRule: .anyDay
    ),

    // 20-minute daily
    FlexTask(
        id: "hang_wet_laundry_after3",
        title: "Put out the wet laundry",
        minutes: 20,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 15, endHour: 24)]
    ),    FlexTask(id: "hoover_quick", title: "Quick Hoover - Bedroom, Landing, Hallway, & Bathroom", minutes: 20, scope: .daily, target: 1),
    
    FlexTask(
        id: "otis_toys",
        title: "Clear Otis's Toys",
        minutes: 20,
        scope: .daily,
        target: 1,
        timeWindows: [TaskTimeWindow(startHour: 20, endHour: 24)],
        workdayRule: .anyDay
    ),

    // 30-minute daily
    FlexTask(id: "fold_laundry_putaway", title: "Fold laundry + put away clothes", minutes: 30, scope: .daily, target: 1),



    FlexTask(id: "workout_full", title: "Workout: push/pull/core", minutes: 60, scope: .daily, target: 1),

    // MARK: - Weekly

    FlexTask(id: "hoover_under_sofa", title: "Hoover under sofa cushions", minutes: 15, scope: .weekly, target: 1),
    FlexTask(id: "clear_bathroom_ledge", title: "Clear Bathroom ledge", minutes: 15, scope: .weekly, target: 1),

    FlexTask(
        id: "wipe_cupboards",
        title: "Wipe Bottom Kitchen Cupboards",
        minutes: 20,
        scope: .weekly,
        target: 1,
        weekdays: [.tuesday]
    ),
    FlexTask(
        id: "mop_kitchenfloor",
        title: "Mop Kitchen floor",
        minutes: 20,
        scope: .weekly,
        target: 1,
        weekdays: [.tuesday]
    ),
    FlexTask(
        id: "mop_bathroomfloor",
        title: "Mop Bathroom Floor",
        minutes: 20,
        scope: .weekly,
        target: 1,
        weekdays: [.wednesday]
    ),
    FlexTask(id: "clean_bathroom_mirror", title: "Clean bathroom mirror", minutes: 20, scope: .weekly, target: 1),

    FlexTask(
        id: "hoover_house",
        title: "Hoover the house",
        minutes: 30,
        scope: .weekly,
        target: 2,
        weekdays: [.sunday]
    ),
    
    FlexTask(
        id: "clean_kitchenwall",
        title: "Clean Kitchen wall",
        minutes: 20,
        scope: .weekly,
        target: 1,
        weekdays: [.tuesday]
    ),
    
    FlexTask(
        id: "clean_airfryer",
        title: "Clean Airfryer",
        minutes: 10,
        scope: .weekly,
        target: 1,
        weekdays: [.tuesday]
    ),
    
    FlexTask(
        id: "clean_microwave",
        title: "Clean Microwave",
        minutes: 10,
        scope: .weekly,
        target: 1,
        weekdays: [.tuesday]
    ),
    
    FlexTask(
        id: "clear_side",
        title: "Tidy on top of hallway cupboard",
        minutes: 10,
        scope: .weekly,
        target: 2
    ),
    
    FlexTask(id: "clean_windows", title: "Clean windows", minutes: 30, scope: .weekly, target: 1),
    FlexTask(id: "clean_bin", title: "Clean Outside of bin", minutes: 20, scope: .weekly, target: 1),

    FlexTask(
        id: "dust_house",
        title: "Dust the house & mantlepiece",
        minutes: 45,
        scope: .weekly,
        target: 1,
        weekdays: [.wednesday]
    ),

    // MARK: - Monthly

    FlexTask(id: "saturday_focus", title: "Saturday Focus", minutes: 60, scope: .monthly, target: 1),
]

// MARK: - Preset groups used by picker logic

let AWAKE_IDS: [String] = [
    "awake_gratitude3",
    "awake_dance",
    "awake_breakfast",
    "awake_make_bed"
]

let AWAKE_WORK_IDS: [String] = [
    "workday_gratitude_meditation"
]

// MARK: - Work day config
// Monday + Friday logic can use this to limit options by minute bucket

let WORKDAY_WHITELIST: [Int: [String]] = [
    2: [],
    5: [
        "workday_gratitude_meditation",
        "vitamins_pm",
        "clean_highchair_2"
    ],
    10: [
        "dining_table_pm",
        "kitchen_surface",
        "french_vocab",
        "spanish_phrase",
        "clean_toilet_sink"
    ],
    15: [
        "wash_dishes_15"
    ],
    20: [],
    30: [],
    45: [],
    60: []
]

// If your current picker expects combo patterns, keep them here
let WORKDAY_COMBO_PATTERNS: [Int: [[Int]]] = [
    2: [[2]],
    5: [[5]],
    10: [[10]],
    15: [[15]],
    20: [[20]],
    30: [[30]],
    45: [[45]],
    60: [[60]]
]

// MARK: - Saturday Focus

struct SaturdayFocusRoom: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let tasks: [String]
}

let SATURDAY_FOCUS_ROOMS: [SaturdayFocusRoom] = [
    SaturdayFocusRoom(
        id: "living_room",
        title: "Living Room",
        tasks: [
            "Declutter visible surfaces",
            "Wash skirting boards",
            "Vacuum under furniture",
            "Clear out fireplace",
            "Mop floor",
            "Clean windows"
        ]
    ),
    SaturdayFocusRoom(
        id: "kitchen",
        title: "Kitchen",
        tasks: [
            "Declutter cupboards",
            "Clean microwave",
            "Clear & clean window sill",
            "Wash window",
            "Clean the oven",
            "Clean backsplash",
            "Clean the kickboards",
            "Clean inside bin"
        ]
    ),
    SaturdayFocusRoom(
        id: "bathroom",
        title: "Bathroom",
        tasks: [
            "Tackle limescale",
            "Wash window",
            "Clean cabinet / storage",
            "Tackle grout",
            "Deep-clean the floors"
        ]
    ),
    SaturdayFocusRoom(
        id: "hallway_stairs",
        title: "Hallway & Stairs",
        tasks: [
            "Wash Doors",
            "Hoover downstairs"
        ]
    ),
    SaturdayFocusRoom(
        id: "childrens_room",
        title: "Otis",
        tasks: [
            "Toy cull",
            "Cull outgrown clothes",
            "Straighten shelves / books"
        ]
    ),
    SaturdayFocusRoom(
        id: "master_bedroom",
        title: "Master Bedroom",
        tasks: [
            "Clean window",
            "Dust skirting boards",
            "Vacuum under furniture"
        ]
    ),
    SaturdayFocusRoom(
        id: "room_of_choice",
        title: "Spare Room",
        tasks: [
            "Declutter anything out of place",
            "Clean windows",
            "Dust skirting boards"
        ]
    )
]
