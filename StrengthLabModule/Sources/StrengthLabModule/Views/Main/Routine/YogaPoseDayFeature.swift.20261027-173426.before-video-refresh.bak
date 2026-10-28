import SwiftUI
import WebKit

// MARK: - Yoga Pose a Day
// Global per-install progression. No SwiftData schema, workout, exercise or
// local media asset is read/written by this feature.

struct YogaPoseDay: Identifiable {
    let rank: Int
    let title: String
    let videoTitle: String
    let instructor: String
    let match: String
    let note: String
    let videoID: String

    var id: Int { rank }

    var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }
}


// YOGA_STUDIO_CATEGORIES_CHAKRAS_V1: audited 98-pose taxonomy.
private struct YogaPoseTags {
    let categories: [String]
    let chakras: [String]
    static let empty = YogaPoseTags(categories: [], chakras: [])
}

private enum YogaPoseDayCatalog {
    // Fixed shuffle: each of the first 91 source poses exactly once.
    // The seven advanced poses 92–98 retain their original final positions.
    static let mixedFirst91Ranks: [Int] = [
        5, 2, 86, 44, 90, 26, 35, 30, 7, 72, 74, 81, 39, 42, 70, 41, 33, 20, 80, 65, 28, 62, 68, 73, 14, 4, 31, 34, 52, 77, 8, 71, 1, 37, 91, 25, 67, 58, 40, 83, 69, 16, 48, 23, 17, 51, 79, 75, 9, 50, 18, 78, 32, 59, 19, 61, 55, 46, 29, 24, 47, 64, 88, 82, 22, 36, 21, 76, 49, 10, 3, 45, 84, 15, 85, 53, 60, 12, 27, 6, 57, 56, 66, 89, 87, 43, 11, 38, 63, 13, 54
    ]

    static let functionalCategories: [String] = ["Relax & Restore", "Release & Mobilise", "Stretch & Lengthen", "Open & Expand", "Ground & Centre", "Invigorate & Flow", "Strength & Stability", "Balance & Focus"]
    static let chakraNames: [String] = ["Root", "Sacral", "Solar Plexus", "Heart", "Throat", "Third Eye", "Crown"]

    static let tags: [Int: YogaPoseTags] = [
        1: YogaPoseTags(categories: ["Relax & Restore", "Ground & Centre"], chakras: ["Crown", "Third Eye"]),
        2: YogaPoseTags(categories: ["Relax & Restore", "Stretch & Lengthen"], chakras: ["Crown", "Third Eye"]),
        3: YogaPoseTags(categories: ["Ground & Centre", "Relax & Restore"], chakras: ["Root", "Third Eye"]),
        4: YogaPoseTags(categories: ["Relax & Restore", "Release & Mobilise"], chakras: ["Sacral", "Root"]),
        5: YogaPoseTags(categories: ["Relax & Restore", "Release & Mobilise"], chakras: ["Sacral", "Root"]),
        6: YogaPoseTags(categories: ["Release & Mobilise", "Relax & Restore"], chakras: ["Sacral", "Root"]),
        7: YogaPoseTags(categories: ["Relax & Restore", "Release & Mobilise", "Stretch & Lengthen"], chakras: ["Sacral", "Third Eye"]),
        8: YogaPoseTags(categories: ["Ground & Centre", "Strength & Stability"], chakras: ["Root", "Solar Plexus"]),
        9: YogaPoseTags(categories: ["Release & Mobilise", "Relax & Restore"], chakras: ["Throat", "Third Eye"]),
        10: YogaPoseTags(categories: ["Release & Mobilise", "Relax & Restore"], chakras: ["Throat", "Heart"]),
        11: YogaPoseTags(categories: ["Release & Mobilise", "Ground & Centre"], chakras: ["Sacral", "Solar Plexus"]),
        12: YogaPoseTags(categories: ["Release & Mobilise", "Relax & Restore"], chakras: ["Heart", "Sacral"]),
        13: YogaPoseTags(categories: ["Release & Mobilise", "Ground & Centre"], chakras: ["Heart", "Sacral", "Throat"]),
        14: YogaPoseTags(categories: ["Relax & Restore", "Stretch & Lengthen"], chakras: ["Third Eye", "Crown"]),
        15: YogaPoseTags(categories: ["Relax & Restore", "Stretch & Lengthen", "Open & Expand"], chakras: ["Third Eye", "Sacral"]),
        16: YogaPoseTags(categories: ["Ground & Centre", "Balance & Focus"], chakras: ["Root", "Crown"]),
        17: YogaPoseTags(categories: ["Open & Expand", "Invigorate & Flow", "Ground & Centre"], chakras: ["Heart", "Crown"]),
        18: YogaPoseTags(categories: ["Ground & Centre", "Strength & Stability", "Stretch & Lengthen"], chakras: ["Root", "Solar Plexus"]),
        19: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand"], chakras: ["Heart", "Throat"]),
        20: YogaPoseTags(categories: ["Release & Mobilise", "Stretch & Lengthen"], chakras: ["Solar Plexus", "Sacral"]),
        21: YogaPoseTags(categories: ["Stretch & Lengthen", "Relax & Restore"], chakras: ["Third Eye", "Sacral"]),
        22: YogaPoseTags(categories: ["Strength & Stability"], chakras: ["Solar Plexus", "Root"]),
        23: YogaPoseTags(categories: ["Stretch & Lengthen", "Relax & Restore", "Open & Expand"], chakras: ["Sacral", "Root"]),
        24: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand"], chakras: ["Sacral", "Root"]),
        25: YogaPoseTags(categories: ["Relax & Restore", "Open & Expand", "Stretch & Lengthen"], chakras: ["Sacral", "Root"]),
        26: YogaPoseTags(categories: ["Stretch & Lengthen", "Ground & Centre"], chakras: ["Root", "Solar Plexus"]),
        27: YogaPoseTags(categories: ["Stretch & Lengthen", "Relax & Restore"], chakras: ["Third Eye", "Root"]),
        28: YogaPoseTags(categories: ["Ground & Centre", "Open & Expand", "Invigorate & Flow"], chakras: ["Root", "Heart"]),
        29: YogaPoseTags(categories: ["Stretch & Lengthen", "Ground & Centre"], chakras: ["Third Eye", "Root"]),
        30: YogaPoseTags(categories: ["Release & Mobilise", "Stretch & Lengthen"], chakras: ["Sacral", "Heart"]),
        31: YogaPoseTags(categories: ["Release & Mobilise", "Stretch & Lengthen", "Relax & Restore"], chakras: ["Heart", "Throat"]),
        32: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Relax & Restore"], chakras: ["Heart", "Third Eye"]),
        33: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability"], chakras: ["Heart", "Solar Plexus"]),
        34: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability"], chakras: ["Heart", "Solar Plexus"]),
        35: YogaPoseTags(categories: ["Invigorate & Flow", "Open & Expand", "Strength & Stability"], chakras: ["Solar Plexus", "Heart"]),
        36: YogaPoseTags(categories: ["Stretch & Lengthen", "Relax & Restore"], chakras: ["Third Eye", "Root"]),
        37: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand"], chakras: ["Sacral", "Third Eye"]),
        38: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen", "Release & Mobilise"], chakras: ["Sacral", "Root"]),
        39: YogaPoseTags(categories: ["Stretch & Lengthen", "Relax & Restore"], chakras: ["Third Eye", "Sacral"]),
        40: YogaPoseTags(categories: ["Stretch & Lengthen", "Ground & Centre"], chakras: ["Root", "Sacral"]),
        41: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen", "Invigorate & Flow"], chakras: ["Sacral", "Root"]),
        42: YogaPoseTags(categories: ["Invigorate & Flow", "Open & Expand", "Strength & Stability"], chakras: ["Root", "Sacral", "Solar Plexus"]),
        43: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand"], chakras: ["Heart", "Throat"]),
        44: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen", "Invigorate & Flow"], chakras: ["Heart", "Sacral"]),
        45: YogaPoseTags(categories: ["Stretch & Lengthen"], chakras: ["Root", "Sacral"]),
        46: YogaPoseTags(categories: ["Invigorate & Flow", "Strength & Stability", "Stretch & Lengthen"], chakras: ["Third Eye", "Solar Plexus"]),
        47: YogaPoseTags(categories: ["Strength & Stability", "Ground & Centre"], chakras: ["Solar Plexus", "Root"]),
        48: YogaPoseTags(categories: ["Invigorate & Flow", "Strength & Stability", "Balance & Focus"], chakras: ["Solar Plexus", "Root"]),
        49: YogaPoseTags(categories: ["Open & Expand", "Invigorate & Flow", "Balance & Focus"], chakras: ["Sacral", "Solar Plexus"]),
        50: YogaPoseTags(categories: ["Strength & Stability", "Invigorate & Flow", "Balance & Focus"], chakras: ["Solar Plexus", "Sacral"]),
        51: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability", "Ground & Centre"], chakras: ["Solar Plexus", "Root", "Third Eye"]),
        52: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand"], chakras: ["Solar Plexus", "Heart"]),
        53: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand", "Invigorate & Flow"], chakras: ["Solar Plexus", "Heart"]),
        54: YogaPoseTags(categories: ["Invigorate & Flow", "Strength & Stability", "Balance & Focus"], chakras: ["Root", "Solar Plexus"]),
        55: YogaPoseTags(categories: ["Invigorate & Flow", "Strength & Stability", "Ground & Centre"], chakras: ["Root", "Sacral"]),
        56: YogaPoseTags(categories: ["Open & Expand", "Invigorate & Flow", "Stretch & Lengthen"], chakras: ["Heart", "Root"]),
        57: YogaPoseTags(categories: ["Stretch & Lengthen", "Balance & Focus", "Open & Expand"], chakras: ["Root", "Heart"]),
        58: YogaPoseTags(categories: ["Strength & Stability", "Stretch & Lengthen", "Invigorate & Flow"], chakras: ["Solar Plexus", "Root"]),
        59: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand", "Ground & Centre"], chakras: ["Sacral", "Root"]),
        60: YogaPoseTags(categories: ["Invigorate & Flow", "Release & Mobilise", "Strength & Stability"], chakras: ["Sacral", "Solar Plexus"]),
        61: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Ground & Centre"], chakras: ["Root", "Sacral"]),
        62: YogaPoseTags(categories: ["Stretch & Lengthen", "Balance & Focus", "Ground & Centre"], chakras: ["Root", "Third Eye"]),
        63: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Relax & Restore"], chakras: ["Sacral", "Heart"]),
        64: YogaPoseTags(categories: ["Release & Mobilise", "Stretch & Lengthen", "Ground & Centre"], chakras: ["Solar Plexus", "Sacral"]),
        65: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand"], chakras: ["Sacral", "Root"]),
        66: YogaPoseTags(categories: ["Strength & Stability", "Balance & Focus", "Invigorate & Flow"], chakras: ["Solar Plexus", "Third Eye"]),
        67: YogaPoseTags(categories: ["Balance & Focus", "Ground & Centre"], chakras: ["Root", "Third Eye"]),
        68: YogaPoseTags(categories: ["Balance & Focus", "Ground & Centre"], chakras: ["Root", "Third Eye"]),
        69: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability"], chakras: ["Root", "Third Eye"]),
        70: YogaPoseTags(categories: ["Strength & Stability", "Balance & Focus"], chakras: ["Solar Plexus", "Root"]),
        71: YogaPoseTags(categories: ["Balance & Focus", "Stretch & Lengthen"], chakras: ["Root", "Third Eye"]),
        72: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand", "Release & Mobilise"], chakras: ["Root", "Sacral"]),
        73: YogaPoseTags(categories: ["Open & Expand", "Balance & Focus", "Stretch & Lengthen"], chakras: ["Heart", "Sacral"]),
        74: YogaPoseTags(categories: ["Release & Mobilise", "Balance & Focus", "Stretch & Lengthen"], chakras: ["Solar Plexus", "Heart"]),
        75: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Release & Mobilise"], chakras: ["Solar Plexus", "Third Eye"]),
        76: YogaPoseTags(categories: ["Balance & Focus", "Invigorate & Flow", "Release & Mobilise"], chakras: ["Solar Plexus", "Root", "Third Eye"]),
        77: YogaPoseTags(categories: ["Balance & Focus", "Open & Expand", "Stretch & Lengthen"], chakras: ["Heart", "Root"]),
        78: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Balance & Focus"], chakras: ["Heart", "Root", "Third Eye"]),
        79: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen", "Strength & Stability"], chakras: ["Heart", "Solar Plexus"]),
        80: YogaPoseTags(categories: ["Stretch & Lengthen", "Open & Expand", "Relax & Restore"], chakras: ["Sacral", "Third Eye"]),
        81: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability", "Stretch & Lengthen"], chakras: ["Root", "Solar Plexus", "Third Eye"]),
        82: YogaPoseTags(categories: ["Strength & Stability", "Balance & Focus"], chakras: ["Solar Plexus", "Heart"]),
        83: YogaPoseTags(categories: ["Strength & Stability", "Invigorate & Flow"], chakras: ["Solar Plexus", "Root"]),
        84: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability", "Invigorate & Flow"], chakras: ["Heart", "Throat"]),
        85: YogaPoseTags(categories: ["Strength & Stability", "Open & Expand"], chakras: ["Heart", "Solar Plexus"]),
        86: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability", "Balance & Focus"], chakras: ["Heart", "Solar Plexus"]),
        87: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability"], chakras: ["Heart", "Solar Plexus"]),
        88: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen"], chakras: ["Heart", "Throat"]),
        89: YogaPoseTags(categories: ["Open & Expand", "Stretch & Lengthen"], chakras: ["Throat", "Heart"]),
        90: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability", "Invigorate & Flow"], chakras: ["Third Eye", "Root", "Solar Plexus"]),
        91: YogaPoseTags(categories: ["Balance & Focus", "Release & Mobilise", "Stretch & Lengthen"], chakras: ["Solar Plexus", "Third Eye", "Root"]),
        92: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability", "Balance & Focus"], chakras: ["Heart", "Solar Plexus"]),
        93: YogaPoseTags(categories: ["Ground & Centre", "Open & Expand", "Relax & Restore"], chakras: ["Crown", "Root", "Third Eye"]),
        94: YogaPoseTags(categories: ["Open & Expand", "Strength & Stability", "Invigorate & Flow"], chakras: ["Heart", "Solar Plexus"]),
        95: YogaPoseTags(categories: ["Stretch & Lengthen"], chakras: ["Crown", "Third Eye"]),
        96: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability"], chakras: ["Throat", "Crown"]),
        97: YogaPoseTags(categories: ["Stretch & Lengthen", "Strength & Stability"], chakras: ["Throat", "Third Eye"]),
        98: YogaPoseTags(categories: ["Balance & Focus", "Strength & Stability"], chakras: ["Third Eye", "Solar Plexus", "Root"]),
    ]

    static func validSavedOrder(_ saved: String) -> [Int]? {
        let ranks = saved.split(separator: ",").compactMap { Int($0) }
        guard ranks.count == 98,
              Set(ranks) == Set(1...98),
              Array(ranks.suffix(7)) == Array(92...98) else { return nil }
        return ranks
    }

    static func order(saved: String, completedCount: Int) -> [Int] {
        if let existing = validSavedOrder(saved) { return existing }

        // Preserve original positions of days already completed before this
        // update. Shuffle only the not-yet-completed part of the first cycle.
        let completed = completedCount < 98 ? min(max(completedCount, 0), 91) : 0
        let preserved = completed > 0 ? Array(1...completed) : []
        let upcoming = mixedFirst91Ranks.filter { $0 > completed }
        return preserved + upcoming + Array(92...98)
    }


    // Exactly the user's 98-row spreadsheet order, including identified
    // Variation / Sequence / Related references (not all exact tutorials).
    static let poses: [YogaPoseDay] = [
        YogaPoseDay(
            rank: 1,
            title: "Corpse Pose — Savasana",
            videoTitle: "Corpse Pose / Savasana",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "eSeRjoolN2A"
        ),
        YogaPoseDay(
            rank: 2,
            title: "Legs Up the Wall — Viparita Karani",
            videoTitle: "Legs Up the Wall",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "q8N8jkmJP6o"
        ),
        YogaPoseDay(
            rank: 3,
            title: "Easy Seated Pose — Sukhasana",
            videoTitle: "Easy Pose / Sukhasana",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "zLvJD7iKVhw"
        ),
        YogaPoseDay(
            rank: 4,
            title: "Knees-to-Chest — Apanasana",
            videoTitle: "Wind-Relieving Pose / Apanasana",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "1udKnNcPSzk"
        ),
        YogaPoseDay(
            rank: 5,
            title: "Single Knee-to-Chest",
            videoTitle: "Wind-Relieving Pose / Apanasana",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "One-knee variation of the wind-relieving pose.",
            videoID: "1udKnNcPSzk"
        ),
        YogaPoseDay(
            rank: 6,
            title: "Supine Pelvic Tilts",
            videoTitle: "Yoga for Lower Back Pain (includes pelvic tilts)",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "Pelvic tilts occur in a broader lower-back practice.",
            videoID: "XeXz8fIZDCE"
        ),
        YogaPoseDay(
            rank: 7,
            title: "Reclined Spinal Twist",
            videoTitle: "Reclined Twist",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "mKC3IeldPOc"
        ),
        YogaPoseDay(
            rank: 8,
            title: "Tabletop Pose",
            videoTitle: "Tabletop Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "PGAntbDQ6Xg"
        ),
        YogaPoseDay(
            rank: 9,
            title: "Seated Neck Rolls / Side Stretches",
            videoTitle: "Yoga for Neck, Shoulders and Upper Back",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "Neck/shoulder practice, not a standalone neck-roll tutorial.",
            videoID: "X3-gKPNyrTA"
        ),
        YogaPoseDay(
            rank: 10,
            title: "Seated Shoulder Rolls",
            videoTitle: "Yoga for Neck, Shoulders and Upper Back",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "Broader neck/shoulder practice.",
            videoID: "X3-gKPNyrTA"
        ),
        YogaPoseDay(
            rank: 11,
            title: "Seated Torso Circles",
            videoTitle: "Seated Torso Circles",
            instructor: "Yoga tutorial",
            match: "Direct",
            note: "",
            videoID: "oueMmCbusv0"
        ),
        YogaPoseDay(
            rank: 12,
            title: "Seated Cat–Cow",
            videoTitle: "Seated Cat–Cow",
            instructor: "UDAYA / Lolo Lam",
            match: "Direct",
            note: "",
            videoID: "tMSDN242J3w"
        ),
        YogaPoseDay(
            rank: 13,
            title: "Cat–Cow",
            videoTitle: "Cat–Cow",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "y39PrKY_4JM"
        ),
        YogaPoseDay(
            rank: 14,
            title: "Child's Pose",
            videoTitle: "Extended Child's Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "eqVMAPM00DM"
        ),
        YogaPoseDay(
            rank: 15,
            title: "Wide-Knee Child's Pose",
            videoTitle: "Extended Child's Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Extended/wide-knee setup.",
            videoID: "eqVMAPM00DM"
        ),
        YogaPoseDay(
            rank: 16,
            title: "Mountain Pose — Tadasana",
            videoTitle: "Mountain Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "NYhH8Gr35cI"
        ),
        YogaPoseDay(
            rank: 17,
            title: "Upward Salute",
            videoTitle: "Upward Salute",
            instructor: "Heather Kitchen",
            match: "Direct",
            note: "",
            videoID: "fLIK47yCVAI"
        ),
        YogaPoseDay(
            rank: 18,
            title: "Staff Pose — Dandasana",
            videoTitle: "Staff Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "sXz0OCjO3p4"
        ),
        YogaPoseDay(
            rank: 19,
            title: "Seated Side Bend",
            videoTitle: "Seated Side Bend",
            instructor: "Tara Stiles",
            match: "Direct",
            note: "",
            videoID: "vaVaIitmAoE"
        ),
        YogaPoseDay(
            rank: 20,
            title: "Easy Seated Spinal Twist",
            videoTitle: "Seated Spinal Twist",
            instructor: "Howcast",
            match: "Variation",
            note: "Tutor shows a more involved seated twist; keep crossed legs for the easy version.",
            videoID: "7CKr-RgOcIc"
        ),
        YogaPoseDay(
            rank: 21,
            title: "Easy Seated Forward Fold",
            videoTitle: "Bound Angle Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Forward-fold mechanics shown with soles together, not exactly crossed-leg fold.",
            videoID: "B6tb4TncKhY"
        ),
        YogaPoseDay(
            rank: 22,
            title: "Supine Legs Raised",
            videoTitle: "Legs Up the Wall",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Legs-up-wall is the supported alternative.",
            videoID: "q8N8jkmJP6o"
        ),
        YogaPoseDay(
            rank: 23,
            title: "Reclined Pigeon / Figure Four",
            videoTitle: "Reclined Figure-Four / Pigeon",
            instructor: "Garth Hewitt",
            match: "Direct",
            note: "",
            videoID: "56x59NxhnMg"
        ),
        YogaPoseDay(
            rank: 24,
            title: "Butterfly / Bound Angle Pose",
            videoTitle: "Bound Angle Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "B6tb4TncKhY"
        ),
        YogaPoseDay(
            rank: 25,
            title: "Happy Baby",
            videoTitle: "Happy Baby Pose — modifications and variations",
            instructor: "Di Hickman",
            match: "Direct",
            note: "",
            videoID: "Da4uIrGcOQE"
        ),
        YogaPoseDay(
            rank: 26,
            title: "Standing Halfway Lift",
            videoTitle: "Halfway Lift — Ardha Uttanasana",
            instructor: "YogaDownload",
            match: "Direct",
            note: "",
            videoID: "n1nqLS4U358"
        ),
        YogaPoseDay(
            rank: 27,
            title: "Standing Forward Fold",
            videoTitle: "Standing Forward Fold",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "g7Uhp5tphAs"
        ),
        YogaPoseDay(
            rank: 28,
            title: "Star Pose",
            videoTitle: "Goddess Pose",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "Star is demonstrated as transition to Goddess.",
            videoID: "wgXefCprLm0"
        ),
        YogaPoseDay(
            rank: 29,
            title: "Wide-Leg Standing Forward Fold",
            videoTitle: "Wide-Legged Forward Fold",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "F7you4Sw1o0"
        ),
        YogaPoseDay(
            rank: 30,
            title: "Kneeling Cat Stretch — hips towards heels",
            videoTitle: "Cat–Cow",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Use Cat as foundation; hips-back variant is not the central demo.",
            videoID: "y39PrKY_4JM"
        ),
        YogaPoseDay(
            rank: 31,
            title: "Thread the Needle",
            videoTitle: "Thread the Needle",
            instructor: "Yoga with Kassandra",
            match: "Direct",
            note: "",
            videoID: "vOukJVt56os"
        ),
        YogaPoseDay(
            rank: 32,
            title: "Extended Puppy Pose",
            videoTitle: "Puppy Pose Tutorial",
            instructor: "Yoga with Kassandra",
            match: "Direct",
            note: "",
            videoID: "mcwsW87rg0E"
        ),
        YogaPoseDay(
            rank: 33,
            title: "Sphinx Pose",
            videoTitle: "Sphinx Pose for Core Strength",
            instructor: "Vive Health",
            match: "Direct",
            note: "",
            videoID: "KWi1YgyxDaQ"
        ),
        YogaPoseDay(
            rank: 34,
            title: "Low Cobra",
            videoTitle: "Cobra Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "n6jrC6WeF84"
        ),
        YogaPoseDay(
            rank: 35,
            title: "Striking Cobra / Dynamic Cobra",
            videoTitle: "Cobra Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Dynamic entry from Child's Pose not the main tutorial.",
            videoID: "n6jrC6WeF84"
        ),
        YogaPoseDay(
            rank: 36,
            title: "Seated Forward Bend",
            videoTitle: "How to do Seated Forward Bend",
            instructor: "The Yoga Institute",
            match: "Direct",
            note: "",
            videoID: "E5FtZEVC424"
        ),
        YogaPoseDay(
            rank: 37,
            title: "Butterfly Forward Fold",
            videoTitle: "Bound Angle Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Forward fold from Bound Angle.",
            videoID: "B6tb4TncKhY"
        ),
        YogaPoseDay(
            rank: 38,
            title: "Deer Pose — Mrigasana",
            videoTitle: "Deer Pose / Mrigasana",
            instructor: "Black Yogi Nico Marie",
            match: "Direct",
            note: "By original chakra-series instructor.",
            videoID: "UUVhbovja8U"
        ),
        YogaPoseDay(
            rank: 39,
            title: "Head-to-Knee Forward Bend",
            videoTitle: "Janu Sirsasana — tutorial and modifications",
            instructor: "Di Hickman",
            match: "Direct",
            note: "",
            videoID: "88sbQj_JqVw"
        ),
        YogaPoseDay(
            rank: 40,
            title: "Half Splits",
            videoTitle: "Half Splits Pose tutorial",
            instructor: "YanvaYoga",
            match: "Direct",
            note: "",
            videoID: "h_wtmUMu0MU"
        ),
        YogaPoseDay(
            rank: 41,
            title: "Low Lunge",
            videoTitle: "How to do Low Lunge / Anjaneyasana",
            instructor: "Yoga by Katy",
            match: "Direct",
            note: "",
            videoID: "ADTMity2bSw"
        ),
        YogaPoseDay(
            rank: 42,
            title: "Runner's Lunge",
            videoTitle: "Runner's Lunge",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "OfJl_jhJcWw"
        ),
        YogaPoseDay(
            rank: 43,
            title: "Bridge Pose",
            videoTitle: "Bridge Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "NnbvPeAIhmA"
        ),
        YogaPoseDay(
            rank: 44,
            title: "Low Lunge with Chest Opener / Cactus Arms",
            videoTitle: "How to do Low Lunge / Anjaneyasana",
            instructor: "Yoga by Katy",
            match: "Variation",
            note: "Low lunge base; add cactus arms/chest opening.",
            videoID: "ADTMity2bSw"
        ),
        YogaPoseDay(
            rank: 45,
            title: "Supported Standing Quadriceps Stretch",
            videoTitle: "Tree Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Single-leg balance foundation, not the quad stretch itself.",
            videoID: "yVE4XXFFO70"
        ),
        YogaPoseDay(
            rank: 46,
            title: "Downward-Facing Dog",
            videoTitle: "Downward-Facing Dog",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "j97SSGsnCAQ"
        ),
        YogaPoseDay(
            rank: 47,
            title: "Plank Pose",
            videoTitle: "Plank Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "6qg3r4zZE_k"
        ),
        YogaPoseDay(
            rank: 48,
            title: "Three-Legged Dog",
            videoTitle: "Downward-Facing Dog",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Raise one leg from Down Dog.",
            videoID: "j97SSGsnCAQ"
        ),
        YogaPoseDay(
            rank: 49,
            title: "Three-Legged Dog with Bent Knee / Open Hip",
            videoTitle: "Downward-Facing Dog",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Open-hip modification of the base pose.",
            videoID: "j97SSGsnCAQ"
        ),
        YogaPoseDay(
            rank: 50,
            title: "Three-Legged Dog with Knee-to-Forehead Crunch",
            videoTitle: "Downward-Facing Dog",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Transition from Three-Legged Dog into knee-to-forehead.",
            videoID: "j97SSGsnCAQ"
        ),
        YogaPoseDay(
            rank: 51,
            title: "Balancing Table / Bird Dog",
            videoTitle: "Tabletop Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Tabletop setup only; extend opposing limbs.",
            videoID: "PGAntbDQ6Xg"
        ),
        YogaPoseDay(
            rank: 52,
            title: "Single-Leg Locust Pose",
            videoTitle: "Locust Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Alternate-leg prep for Locust.",
            videoID: "0kxczNm1xF4"
        ),
        YogaPoseDay(
            rank: 53,
            title: "Locust Pose",
            videoTitle: "Locust Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "0kxczNm1xF4"
        ),
        YogaPoseDay(
            rank: 54,
            title: "High Lunge / Crescent Lunge",
            videoTitle: "Crescent / High Lunge",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "eXupg3oNGJY"
        ),
        YogaPoseDay(
            rank: 55,
            title: "Warrior II",
            videoTitle: "Warrior II",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "4Ejz7IgODlU"
        ),
        YogaPoseDay(
            rank: 56,
            title: "Reverse Warrior",
            videoTitle: "Reverse Warrior",
            instructor: "Yoga International",
            match: "Direct",
            note: "",
            videoID: "h_iHFVf-1J4"
        ),
        YogaPoseDay(
            rank: 57,
            title: "Triangle Pose",
            videoTitle: "Triangle Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "upFYlxZHif0"
        ),
        YogaPoseDay(
            rank: 58,
            title: "Extended Side Angle",
            videoTitle: "Extended Side Angle",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "0lfzG9jH6cM"
        ),
        YogaPoseDay(
            rank: 59,
            title: "Goddess Pose",
            videoTitle: "Goddess Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "wgXefCprLm0"
        ),
        YogaPoseDay(
            rank: 60,
            title: "Goddess Pose with Torso Twists",
            videoTitle: "Goddess Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Hands-on-thighs torso twists from Goddess.",
            videoID: "wgXefCprLm0"
        ),
        YogaPoseDay(
            rank: 61,
            title: "Garland Pose / Yogi Squat",
            videoTitle: "Garland Pose / Malasana",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "IXpJEqssze8"
        ),
        YogaPoseDay(
            rank: 62,
            title: "Pyramid Pose",
            videoTitle: "Pyramid Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "LTe3CO7Vtxs"
        ),
        YogaPoseDay(
            rank: 63,
            title: "Pigeon Pose",
            videoTitle: "Pigeon Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "0_zPqA65Nok"
        ),
        YogaPoseDay(
            rank: 64,
            title: "Seated Spinal Twist — Ardha Matsyendrasana",
            videoTitle: "Seated Spinal Twist",
            instructor: "Howcast",
            match: "Direct",
            note: "",
            videoID: "7CKr-RgOcIc"
        ),
        YogaPoseDay(
            rank: 65,
            title: "Cow Face Legs",
            videoTitle: "Cow Face Pose (including forward-fold progression)",
            instructor: "Howcast",
            match: "Direct",
            note: "",
            videoID: "-acLT1lsMYo"
        ),
        YogaPoseDay(
            rank: 66,
            title: "Half Boat Pose",
            videoTitle: "Half Boat Pose / Ardha Navasana",
            instructor: "Yoga With Gagan",
            match: "Direct",
            note: "",
            videoID: "rZK6SYbsPqU"
        ),
        YogaPoseDay(
            rank: 67,
            title: "Supported Tree Pose — toes resting on floor",
            videoTitle: "Tree Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Basic Tree progression.",
            videoID: "yVE4XXFFO70"
        ),
        YogaPoseDay(
            rank: 68,
            title: "Tree Pose — foot on calf or thigh",
            videoTitle: "Tree Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "yVE4XXFFO70"
        ),
        YogaPoseDay(
            rank: 69,
            title: "Standing Knee Raise / Single-Leg Balance",
            videoTitle: "Tree Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Balance foundation; raised-knee variation differs.",
            videoID: "yVE4XXFFO70"
        ),
        YogaPoseDay(
            rank: 70,
            title: "Modified Side Plank — knee supported",
            videoTitle: "Side Plank",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Knee-supported progression.",
            videoID: "dFCrqn0RzJA"
        ),
        YogaPoseDay(
            rank: 71,
            title: "Forward Fold on Tiptoes",
            videoTitle: "Standing Forward Fold",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Base fold; advanced heel lift not central demo.",
            videoID: "g7Uhp5tphAs"
        ),
        YogaPoseDay(
            rank: 72,
            title: "Side Lunge — Skandasana",
            videoTitle: "Skandasana tutorial, all levels",
            instructor: "Yoga is the Answer",
            match: "Direct",
            note: "Four levels shown.",
            videoID: "VuyIfGmNPhM"
        ),
        YogaPoseDay(
            rank: 73,
            title: "Low Lunge with Back-Foot Hold",
            videoTitle: "Runner's Lunge",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Base lunge only; back-foot quad bind is additional.",
            videoID: "OfJl_jhJcWw"
        ),
        YogaPoseDay(
            rank: 74,
            title: "Revolved Gate Pose variation",
            videoTitle: "Half Splits Pose tutorial",
            instructor: "YanvaYoga",
            match: "Related",
            note: "Base Half Split; revolved side opening not covered.",
            videoID: "h_wtmUMu0MU"
        ),
        YogaPoseDay(
            rank: 75,
            title: "Revolved Head-to-Knee Pose",
            videoTitle: "Staff Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Seated setup only; this variation needs dedicated tutoring.",
            videoID: "sXz0OCjO3p4"
        ),
        YogaPoseDay(
            rank: 76,
            title: "Revolved High Lunge / Crescent Lunge Twist",
            videoTitle: "Crescent / High Lunge",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "High Lunge setup; add twist.",
            videoID: "eXupg3oNGJY"
        ),
        YogaPoseDay(
            rank: 77,
            title: "Triangle Pose with Arm Bind",
            videoTitle: "Triangle Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Triangle alignment; arm bind not central demo.",
            videoID: "upFYlxZHif0"
        ),
        YogaPoseDay(
            rank: 78,
            title: "Pyramid Pose with Hands Clasped Behind",
            videoTitle: "Pyramid Pose",
            instructor: "Yoga With Adriene",
            match: "Variation",
            note: "Clasp behind back before forward fold.",
            videoID: "LTe3CO7Vtxs"
        ),
        YogaPoseDay(
            rank: 79,
            title: "Humble Warrior",
            videoTitle: "Warrior II",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Warrior II is starting position; humble bound forward fold differs.",
            videoID: "4Ejz7IgODlU"
        ),
        YogaPoseDay(
            rank: 80,
            title: "Cow Face Seated Forward Fold",
            videoTitle: "Cow Face Pose (including forward-fold progression)",
            instructor: "Howcast",
            match: "Direct",
            note: "Forward fold included in Howcast tutorial.",
            videoID: "-acLT1lsMYo"
        ),
        YogaPoseDay(
            rank: 81,
            title: "Straight-Leg Standing Lunge with Forward Hinge and Raised Arm",
            videoTitle: "Pyramid Pose",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Pyramid foundation, not precise single-arm variation.",
            videoID: "LTe3CO7Vtxs"
        ),
        YogaPoseDay(
            rank: 82,
            title: "Full Side Plank",
            videoTitle: "Side Plank",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "dFCrqn0RzJA"
        ),
        YogaPoseDay(
            rank: 83,
            title: "Four-Limbed Staff Pose — Chaturanga",
            videoTitle: "Chaturanga Dandasana",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "D3DXO4REdQI"
        ),
        YogaPoseDay(
            rank: 84,
            title: "Upward-Facing Dog",
            videoTitle: "Upward-Facing Dog / Foundations of Flow",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "From Chaturanga in Vinyasa foundations; check dedicated Up Dog tutorials.",
            videoID: "D3DXO4REdQI"
        ),
        YogaPoseDay(
            rank: 85,
            title: "Reverse Plank",
            videoTitle: "Reverse Plank / Purvottanasana",
            instructor: "Yoga with Shvasa",
            match: "Direct",
            note: "",
            videoID: "8caO_TgkcX0"
        ),
        YogaPoseDay(
            rank: 86,
            title: "Half Bow Pose",
            videoTitle: "Bow Pose with Half-Bow modification",
            instructor: "Di Hickman",
            match: "Direct",
            note: "Single-leg preparation demonstrated in Bow video.",
            videoID: "uxRdqDD4dJE"
        ),
        YogaPoseDay(
            rank: 87,
            title: "Bow Pose",
            videoTitle: "Bow Pose with Half-Bow modification",
            instructor: "Di Hickman",
            match: "Direct",
            note: "",
            videoID: "uxRdqDD4dJE"
        ),
        YogaPoseDay(
            rank: 88,
            title: "Camel Pose",
            videoTitle: "Camel Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "AigVwIFvmAQ"
        ),
        YogaPoseDay(
            rank: 89,
            title: "Fish Pose",
            videoTitle: "Fish Pose — four variations",
            instructor: "Yoga & You",
            match: "Direct",
            note: "",
            videoID: "2tWJ1TqjfFQ"
        ),
        YogaPoseDay(
            rank: 90,
            title: "Warrior III",
            videoTitle: "Warrior III",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "",
            videoID: "HuETB2HA2FM"
        ),
        YogaPoseDay(
            rank: 91,
            title: "Revolved Triangle",
            videoTitle: "Revolved Triangle with modifications",
            instructor: "Yoga International",
            match: "Direct",
            note: "",
            videoID: "q7gPEtWsZco"
        ),
        YogaPoseDay(
            rank: 92,
            title: "Wild Thing — Camatkarasana",
            videoTitle: "How to Wild Thing / Camatkarasana",
            instructor: "Janet Stone",
            match: "Direct",
            note: "Exact Janet Stone tutorial from original playlist.",
            videoID: "1O3mSq2GHGA"
        ),
        YogaPoseDay(
            rank: 93,
            title: "Full Lotus — Padmasana",
            videoTitle: "How to Do the Lotus Pose",
            instructor: "Howcast",
            match: "Direct",
            note: "Do not force through knee.",
            videoID: "odKi0b2K4LY"
        ),
        YogaPoseDay(
            rank: 94,
            title: "Wheel Pose",
            videoTitle: "Wheel Pose — complete tutorial",
            instructor: "Fernanda Yoga",
            match: "Direct",
            note: "",
            videoID: "g1Pyp8AAMes"
        ),
        YogaPoseDay(
            rank: 95,
            title: "Rabbit Pose",
            videoTitle: "Rabbit Pose",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "Cervical loading: practice with qualified instruction.",
            videoID: "lKudYLA1k5k"
        ),
        YogaPoseDay(
            rank: 96,
            title: "Shoulderstand",
            videoTitle: "Foundations of Shoulderstand (includes Plow/Fish)",
            instructor: "Yoga With Adriene",
            match: "Direct",
            note: "Includes alternatives and adjacent poses.",
            videoID: "SOHsI7XI0mg"
        ),
        YogaPoseDay(
            rank: 97,
            title: "Plow Pose",
            videoTitle: "Foundations of Shoulderstand (includes Plow/Fish)",
            instructor: "Yoga With Adriene",
            match: "Sequence",
            note: "Included in Foundations of Shoulderstand.",
            videoID: "SOHsI7XI0mg"
        ),
        YogaPoseDay(
            rank: 98,
            title: "Crane / Crow variation (head-supported in original class)",
            videoTitle: "Crow Pose / Bakasana (standard freestanding variant)",
            instructor: "Yoga With Adriene",
            match: "Related",
            note: "Standard freestanding Crow differs from Nico's head-supported variation.",
            videoID: "DgvjvwPGLPY"
        )
    ]
}

// YOGA_STUDIO_SWAP_FILTERS_V1
// The banner remains on StrengthLab's main page; the sheet handles swapping.
struct YogaPoseDayBanner: View {
    @AppStorage("strengthlab.yogaPoseDay.completedCount.v1")
    private var completedCount = 0

    @AppStorage("strengthlab.yogaPoseDay.fixedOrder.v2")
    private var savedPoseOrder = ""

    @State private var showingStudio = false

    private var normalizedCount: Int { max(0, completedCount) }
    private var dayNumber: Int { normalizedCount + 1 }
    private var orderedRanks: [Int] {
        YogaPoseDayCatalog.order(saved: savedPoseOrder, completedCount: normalizedCount)
    }
    private var pose: YogaPoseDay {
        YogaPoseDayCatalog.poses[orderedRanks[normalizedCount % 98] - 1]
    }

    var body: some View {
        Button {
            saveInitialOrderIfNeeded()
            showingStudio = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 23, weight: .semibold))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Yoga Pose a Day - Day \(dayNumber)")
                        .font(StrengthLabFigmaTheme.bold(15))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(pose.title)
                        .font(StrengthLabFigmaTheme.medium(12))
                        .lineLimit(1)
                        .opacity(0.93)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                StrengthLabFigmaTheme.coralGradient,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Yoga Pose a Day. Day \(dayNumber). \(pose.title). Open yoga studio")
        .onAppear { saveInitialOrderIfNeeded() }
        .sheet(isPresented: $showingStudio) {
            YogaPoseDayStudioView(dayNumber: dayNumber)
        }
    }

    private func saveInitialOrderIfNeeded() {
        guard YogaPoseDayCatalog.validSavedOrder(savedPoseOrder) == nil else { return }
        savedPoseOrder = YogaPoseDayCatalog.order(
            saved: "", completedCount: normalizedCount
        ).map(String.init).joined(separator: ",")
    }
}

private struct YogaPoseDayStudioView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("strengthlab.yogaPoseDay.completedCount.v1")
    private var completedCount = 0

    @AppStorage("strengthlab.yogaPoseDay.fixedOrder.v2")
    private var savedPoseOrder = ""

    let dayNumber: Int

    @State private var showingChoices = false
    @State private var previewIndex: Int?
    @State private var categoryFilters: Set<String> = []
    @State private var chakraFilters: Set<String> = []

    private var cycleIndex: Int { (dayNumber - 1) % 98 }
    private var order: [Int] {
        YogaPoseDayCatalog.order(saved: savedPoseOrder, completedCount: max(0, completedCount))
    }
    private var pose: YogaPoseDay {
        YogaPoseDayCatalog.poses[order[cycleIndex] - 1]
    }
    private var canSwap: Bool {
        cycleIndex < 90 && completedCount == dayNumber - 1
    }
    private var futureIndices: [Int] {
        guard canSwap else { return [] }
        return Array((cycleIndex + 1)..<91)
    }
    private var matchingIndices: [Int] {
        futureIndices.filter { index in
            let tags = YogaPoseDayCatalog.tags[order[index]] ?? .empty
            let categoryMatch = categoryFilters.isEmpty ||
                !categoryFilters.isDisjoint(with: tags.categories)
            let chakraMatch = chakraFilters.isEmpty ||
                !chakraFilters.isDisjoint(with: tags.chakras)
            return categoryMatch && chakraMatch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let index = previewIndex {
                    candidatePreview(at: index)
                } else if showingChoices {
                    swapChoices
                } else {
                    todayScreen
                }
            }
            .navigationTitle(previewIndex != nil ? "Preview pose" :
                             showingChoices ? "Swap out" : "Yoga Pose a Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if previewIndex != nil {
                            previewIndex = nil
                        } else if showingChoices {
                            showingChoices = false
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: previewIndex != nil || showingChoices
                              ? "chevron.left" : "xmark")
                    }
                    .accessibilityLabel(previewIndex != nil ? "Back to filters" :
                                        showingChoices ? "Back to today's pose" : "Close")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !showingChoices && previewIndex == nil {
                    completionBar
                }
            }
            .background(Color.white.ignoresSafeArea())
            .preferredColorScheme(.light)
            .tint(StrengthLabFigmaTheme.coral)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var todayScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("YOGA POSE A DAY · DAY \(dayNumber)")
                    .font(StrengthLabFigmaTheme.bold(12))
                    .foregroundStyle(StrengthLabFigmaTheme.coral)
                Text(pose.title)
                    .font(StrengthLabFigmaTheme.bold(24))
                    .foregroundStyle(StrengthLabFigmaTheme.ink)
                yogaVideo(for: pose)
                Text("Tutorial: \(pose.videoTitle) · \(pose.instructor)")
                    .font(StrengthLabFigmaTheme.regular(13))
                    .foregroundStyle(StrengthLabFigmaTheme.muted)

                poseTags(rank: pose.rank)

                if pose.match != "Direct" {
                    Label("\(pose.match) reference — \(pose.note.isEmpty ? "Tutorial may demonstrate a related variation." : pose.note)", systemImage: "info.circle")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .padding(12)
                        .background(StrengthLabFigmaTheme.blush,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                if let url = pose.watchURL {
                    Link(destination: url) {
                        Label("Watch on YouTube if embedding is unavailable",
                              systemImage: "play.rectangle")
                            .font(StrengthLabFigmaTheme.medium(13))
                    }
                }

                if canSwap {
                    Button {
                        showingChoices = true
                    } label: {
                        Label("Swap out", systemImage: "arrow.left.arrow.right")
                            .font(StrengthLabFigmaTheme.bold(16))
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    Text("Choose an upcoming pose. The two poses exchange days; neither is lost.")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .foregroundStyle(StrengthLabFigmaTheme.muted)
                } else {
                    Text("The seven advanced poses stay in Days 92–98. Completed days are locked to protect your progress.")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .foregroundStyle(StrengthLabFigmaTheme.muted)
                }
            }
            .padding(22)
        }
    }

    private var completionBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                // Don't allow a stale sheet to skip a day.
                guard completedCount == dayNumber - 1 else {
                    dismiss()
                    return
                }
                completedCount = dayNumber
                dismiss()
            } label: {
                Label("Mark Day \(dayNumber) Complete", systemImage: "checkmark.circle.fill")
                    .font(StrengthLabFigmaTheme.bold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(StrengthLabFigmaTheme.coralGradient,
                                in: RoundedRectangle(cornerRadius: 16))
            }
            .disabled(completedCount != dayNumber - 1)
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    private var swapChoices: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Swap out \(pose.title)")
                    .font(StrengthLabFigmaTheme.bold(21))
                Text("Filter upcoming poses by how you want to feel, the chakra you want to work with, or both.")
                    .font(StrengthLabFigmaTheme.regular(13))
                    .foregroundStyle(StrengthLabFigmaTheme.muted)

                HStack {
                    Text("Categories").font(StrengthLabFigmaTheme.bold(16))
                    Spacer()
                    if !categoryFilters.isEmpty {
                        Button("Clear") { categoryFilters.removeAll() }
                    }
                }
                filterButtons(YogaPoseDayCatalog.functionalCategories,
                              selection: $categoryFilters)

                HStack {
                    Text("Chakras").font(StrengthLabFigmaTheme.bold(16))
                    Spacer()
                    if !chakraFilters.isEmpty {
                        Button("Clear") { chakraFilters.removeAll() }
                    }
                }
                filterButtons(YogaPoseDayCatalog.chakraNames,
                              selection: $chakraFilters)

                Text("\(matchingIndices.count) available pose\(matchingIndices.count == 1 ? "" : "s")")
                    .font(StrengthLabFigmaTheme.bold(14))
                    .foregroundStyle(StrengthLabFigmaTheme.ink)

                if matchingIndices.isEmpty {
                    ContentUnavailableView("No matching poses",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Remove one or more filters to see more options."))
                } else {
                    LazyVStack(spacing: 9) {
                        ForEach(matchingIndices, id: \.self) { index in
                            let option = YogaPoseDayCatalog.poses[order[index] - 1]
                            Button {
                                previewIndex = index
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(option.title)
                                            .font(StrengthLabFigmaTheme.bold(15))
                                            .foregroundStyle(StrengthLabFigmaTheme.ink)
                                            .multilineTextAlignment(.leading)
                                        Text("Currently Day \(index + 1) · \((YogaPoseDayCatalog.tags[option.rank] ?? .empty).categories.first ?? "Yoga")")
                                            .font(StrengthLabFigmaTheme.regular(12))
                                            .foregroundStyle(StrengthLabFigmaTheme.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                }
                                .padding(14)
                                .background(StrengthLabFigmaTheme.blush,
                                            in: RoundedRectangle(cornerRadius: 15))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func filterButtons(_ options: [String], selection: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 138), spacing: 7)], spacing: 8) {
            ForEach(options, id: \.self) { value in
                let isSelected = selection.wrappedValue.contains(value)
                Button {
                    var updated = selection.wrappedValue
                    if isSelected { updated.remove(value) }
                    else { updated.insert(value) }
                    selection.wrappedValue = updated
                } label: {
                    Text(value)
                        .font(StrengthLabFigmaTheme.medium(12))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(.horizontal, 5)
                        .foregroundStyle(isSelected ? Color.white : StrengthLabFigmaTheme.ink)
                        .background(isSelected ? StrengthLabFigmaTheme.coral : StrengthLabFigmaTheme.blush,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func candidatePreview(at index: Int) -> some View {
        let candidate = YogaPoseDayCatalog.poses[order[index] - 1]
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("DAY \(dayNumber) · SWAP PREVIEW")
                    .font(StrengthLabFigmaTheme.bold(12))
                    .foregroundStyle(StrengthLabFigmaTheme.coral)
                Text(candidate.title)
                    .font(StrengthLabFigmaTheme.bold(24))
                    .foregroundStyle(StrengthLabFigmaTheme.ink)

                // Confirm / cancel sit to the right of the video.
                HStack(alignment: .top, spacing: 10) {
                    yogaVideo(for: candidate)
                        .frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        Button {
                            confirmSwap(with: index)
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 23, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(Color.green, in: Circle())
                        }
                        .accessibilityLabel("Confirm pose swap")

                        Button {
                            previewIndex = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(StrengthLabFigmaTheme.ink)
                                .frame(width: 54, height: 54)
                                .background(StrengthLabFigmaTheme.blush, in: Circle())
                        }
                        .accessibilityLabel("Back to filtered poses")
                    }
                    .buttonStyle(.plain)
                }

                Text("Tutorial: \(candidate.videoTitle) · \(candidate.instructor)")
                    .font(StrengthLabFigmaTheme.regular(13))
                    .foregroundStyle(StrengthLabFigmaTheme.muted)
                poseTags(rank: candidate.rank)
                if candidate.match != "Direct" {
                    Label("\(candidate.match) reference — \(candidate.note.isEmpty ? "This video may show a related variation." : candidate.note)", systemImage: "info.circle")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .padding(12)
                        .background(StrengthLabFigmaTheme.blush,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                Text("✓ moves this pose to today. \(pose.title) moves to Day \(index + 1). X returns to your filters.")
                    .font(StrengthLabFigmaTheme.regular(13))
                    .foregroundStyle(StrengthLabFigmaTheme.muted)
            }
            .padding(20)
        }
    }

    private func yogaVideo(for candidate: YogaPoseDay) -> some View {
        YogaPoseYouTubePlayer(videoID: candidate.videoID)
            .frame(height: 215)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .id(candidate.rank)
    }

    private func poseTags(rank: Int) -> some View {
        let tags = YogaPoseDayCatalog.tags[rank] ?? .empty
        return VStack(alignment: .leading, spacing: 6) {
            Text("Categories: \(tags.categories.joined(separator: " · "))")
            Text("Chakras: \(tags.chakras.joined(separator: " · "))")
        }
        .font(StrengthLabFigmaTheme.regular(12))
        .foregroundStyle(StrengthLabFigmaTheme.muted)
    }

    private func confirmSwap(with index: Int) {
        // Don't allow edits to completed positions or the reserved advanced week.
        guard completedCount == dayNumber - 1,
              cycleIndex < 91,
              index > cycleIndex, index < 91 else { return }
        var updated = order
        updated.swapAt(cycleIndex, index)
        guard Set(updated) == Set(1...98),
              Array(updated.suffix(7)) == Array(92...98) else { return }
        savedPoseOrder = updated.map(String.init).joined(separator: ",")
        previewIndex = nil
        showingChoices = false
    }
}

private struct YogaPoseYouTubePlayer: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.allowsPictureInPictureMediaPlayback = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        loadVideo(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // The day is immutable while this player is displayed; do not
        // reload the iframe on incidental SwiftUI state updates.
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: ()) {
        uiView.stopLoading()
        uiView.loadHTMLString("", baseURL: nil)
    }

    private func loadVideo(into webView: WKWebView) {
        // The app-bundle identifier is used as the HTTP Referer identity,
        // following YouTube's published WKWebView embedding guidance.
        guard let bundleID = Bundle.main.bundleIdentifier,
              let baseURL = URL(string: "https://\(bundleID.lowercased())/")
        else { return }

        let html = """
        <!doctype html>
        <html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>
          html, body { margin:0; padding:0; width:100%; height:100%; overflow:hidden; background:#000; }
          iframe { border:0; width:100%; height:100%; display:block; }
        </style>
        </head><body>
          <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&amp;rel=0"
            title="Yoga tutorial" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </body></html>
        """

        webView.loadHTMLString(html, baseURL: baseURL)
    }
}
