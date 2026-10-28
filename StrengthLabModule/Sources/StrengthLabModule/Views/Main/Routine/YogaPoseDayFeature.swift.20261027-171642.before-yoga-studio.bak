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

private enum YogaPoseDayCatalog {
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

struct YogaPoseDayBanner: View {
    @AppStorage("strengthlab.yogaPoseDay.completedCount.v1")
    private var completedCount = 0

    @State private var selectedPose: YogaPoseDay?
    @State private var selectedDayNumber = 1

    private var normalizedCount: Int { max(0, completedCount) }
    private var dayNumber: Int { normalizedCount + 1 }
    private var pose: YogaPoseDay {
        YogaPoseDayCatalog.poses[normalizedCount % YogaPoseDayCatalog.poses.count]
    }

    var body: some View {
        Button {
            // Freeze this day's tutorial for the duration of the sheet.
            selectedDayNumber = dayNumber
            selectedPose = pose
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
        .accessibilityLabel("Yoga Pose a Day. Day \(dayNumber). \(pose.title). Open video")
        .sheet(item: $selectedPose) { pose in
            YogaPoseDayPlayerView(
                dayNumber: selectedDayNumber,
                pose: pose
            )
        }
    }
}

private struct YogaPoseDayPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("strengthlab.yogaPoseDay.completedCount.v1")
    private var completedCount = 0

    let dayNumber: Int
    let pose: YogaPoseDay

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("YOGA POSE A DAY · DAY \(dayNumber)")
                            .font(StrengthLabFigmaTheme.bold(12))
                            .foregroundStyle(StrengthLabFigmaTheme.coral)
                        Text(pose.title)
                            .font(StrengthLabFigmaTheme.bold(23))
                            .foregroundStyle(StrengthLabFigmaTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Tutorial: \(pose.videoTitle) · \(pose.instructor)")
                            .font(StrengthLabFigmaTheme.regular(13))
                            .foregroundStyle(StrengthLabFigmaTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    YogaPoseYouTubePlayer(videoID: pose.videoID)
                        .frame(height: 230)
                        .background(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .accessibilityLabel("Embedded YouTube tutorial for \(pose.title)")

                    Text("Use the player’s full-screen button if you like. Exit full screen to return to your completion tick below.")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .foregroundStyle(StrengthLabFigmaTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    if pose.match != "Direct" {
                        Label("\(pose.match) reference — \(pose.note.isEmpty ? "This video is not an exact standalone tutorial for this variation." : pose.note)", systemImage: "info.circle")
                            .font(StrengthLabFigmaTheme.regular(12))
                            .foregroundStyle(StrengthLabFigmaTheme.ink)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(StrengthLabFigmaTheme.blush, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let watchURL = pose.watchURL {
                        Link(destination: watchURL) {
                            Label("Watch on YouTube if embedding is unavailable", systemImage: "play.rectangle")
                                .font(StrengthLabFigmaTheme.medium(13))
                                .foregroundStyle(StrengthLabFigmaTheme.coral)
                        }
                    }

                    Text("You can tick this at any time. Watching to the end is not required. After Day 98 the sequence repeats, continuing as Day 99.")
                        .font(StrengthLabFigmaTheme.regular(12))
                        .foregroundStyle(StrengthLabFigmaTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    Button {
                        // Only the currently presented day may advance progress.
                        // Double taps, stale sheets and repeat presentations cannot
                        // accidentally skip a pose.
                        guard completedCount == dayNumber - 1 else {
                            dismiss()
                            return
                        }
                        completedCount = dayNumber
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 26, weight: .semibold))
                            Text("Mark Day \(dayNumber) Complete")
                                .font(StrengthLabFigmaTheme.bold(16))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(
                            StrengthLabFigmaTheme.coralGradient,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(completedCount != dayNumber - 1)
                    .accessibilityHint("Complete this pose and immediately advance the global banner to the next day")

                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Yoga Pose a Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(.light)
            .tint(StrengthLabFigmaTheme.coral)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
