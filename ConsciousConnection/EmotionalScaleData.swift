import SwiftUI

// ====== Settings ======
let MAX_UP_STEPS = 10 // keep identical to Scriptable

struct ScaleRung: Identifiable, Hashable {
    let r: Int
    let name: String
    var id: Int { r }
}

// ====== Data (43 rungs) ======
let SCALE: [ScaleRung] = [
    .init(r: 1,  name: "Joy / Appreciation / Empowerment / Freedom / Love"),
    .init(r: 2,  name: "Acceptance / Trust"),
    .init(r: 3,  name: "Passion"),
    .init(r: 4,  name: "Excitement / Purpose"),
    .init(r: 5,  name: "Enthusiasm / Eagerness / Happiness"),
    .init(r: 6,  name: "Worthiness / Courage"),
    .init(r: 7,  name: "Positive Expectation / Belief"),
    .init(r: 8,  name: "Faith / Confidence / Responsibility"),
    .init(r: 9,  name: "Optimism"),
    .init(r: 10, name: "Cheerfulness / Playfulness"),
    .init(r: 11, name: "Hopefulness"),
    .init(r: 12, name: "Curiosity / Connection / Compassion"),
    .init(r: 13, name: "Contentment"),
    .init(r: 14, name: "Stillness / Inner Quiet"),
    .init(r: 15, name: "Boredom"),
    .init(r: 16, name: "Stability / Indifference"),
    .init(r: 17, name: "Pessimism"),
    .init(r: 18, name: "Doubt"),
    .init(r: 19, name: "Frustration / Irritation / Impatience"),
    .init(r: 20, name: "Restlessness"),
    .init(r: 21, name: "Overwhelm"),
    .init(r: 22, name: "Confusion"),
    .init(r: 23, name: "Disappointment"),
    .init(r: 24, name: "Sadness"),
    .init(r: 25, name: "Doubt"),
    .init(r: 26, name: "Discouragement / Fatigue"),
    .init(r: 27, name: "Worry"),
    .init(r: 28, name: "Concern / Nervousness"),
    .init(r: 29, name: "Blame"),
    .init(r: 30, name: "Resentment"),
    .init(r: 31, name: "Discouragement"),
    .init(r: 32, name: "Hopelessness"),
    .init(r: 33, name: "Anger"),
    .init(r: 34, name: "Defiance"),
    .init(r: 35, name: "Revenge"),
    .init(r: 36, name: "Spite / Vindication"),
    .init(r: 37, name: "Hatred / Rage"),
    .init(r: 38, name: "Contempt / Bitterness"),
    .init(r: 39, name: "Jealousy"),
    .init(r: 40, name: "Envy"),
    .init(r: 41, name: "Insecurity / Guilt / Unworthiness"),
    .init(r: 42, name: "Shame / Inadequacy"),
    .init(r: 43, name: "Fear / Grief / Depression / Despair / Powerlessness")
]

// Polarising positive reframes for lower half (rank >= 15) — UNCHANGED TEXT
let REFRAME: [Int:String] = [
    15: "Boredom means stability—there’s space for gentle curiosity now.",
    16: "Indifference is a pause—an empty canvas waiting for color.",
    17: "Pessimism is your risk radar—use it to plan one safe, small step.",
    18: "Doubt shows you’re thinking—now choose one kind thought.",
    19: "Frustration shows you care—this energy can fuel constructive change.",
    20: "Restlessness means energy is building—direct it with purpose.",
    21: "Overwhelm means many options—choose just one next tiny action.",
    22: "Confusion clears when you breathe—clarity comes in stillness.",
    23: "Disappointment clarifies what you don’t want—now you know what you do want.",
    24: "Sadness softens the heart—feel it, then let light in again.",
    25: "Doubt invites curiosity—ask one gentle question.",
    26: "Fatigue is your cue to rest—energy returns after stillness.",
    27: "Worry is imagination—turn it toward creative solutions.",
    28: "Concern means you care—balance it with trust.",
    29: "Blame sees causality—reclaim your power to choose the next move.",
    30: "Resentment is stuck passion—use it to define your boundaries.",
    31: "Discouragement invites restoration—rest refills momentum.",
    32: "Hopelessness is quiet—space to listen for guidance.",
    33: "Anger marks a boundary—channel it into determination and focus.",
    34: "Defiance says 'I matter'—now turn it into creative will.",
    35: "Revenge wants power back—redirect it into self-respect and standards.",
    36: "Vindication wants justice—start by giving fairness to yourself.",
    37: "Hatred shows intense energy—breathe it into safety and ground it.",
    38: "Bitterness hides pain—acknowledge it and release slowly.",
    39: "Jealousy points to desire—proof you want this too; let it inspire action.",
    40: "Envy mirrors your capacity—what you see, you can become.",
    41: "Insecurity/Guilt shows you value goodness—practice self-forgiveness.",
    42: "Shame means you care about integrity—offer compassion to yourself.",
    43: "Fear/Grief/Despair are signals to receive support—breath and care carry you."
]

// ====== Color tiering (same logic as Scriptable tiers) ======
enum ScaleTier { case high, mid, low }

func rankTier(_ r: Int) -> ScaleTier {
    if r <= 14 { return .high }
    if r <= 28 { return .mid }
    return .low
}

func tierBackground(_ r: Int) -> Color {
    switch rankTier(r) {
    case .high: return Color(red: 0.09, green: 0.24, blue: 0.24) // teal-ish
    case .mid:  return Color(red: 0.23, green: 0.18, blue: 0.10) // amber-brown
    case .low:  return Color(red: 0.24, green: 0.12, blue: 0.14) // wine-red
    }
}

func tierAccent(_ r: Int) -> Color {
    switch rankTier(r) {
    case .high: return Color(red: 0.49, green: 0.77, blue: 0.71)
    case .mid:  return Color(red: 0.97, green: 0.77, blue: 0.33)
    case .low:  return Color(red: 1.00, green: 0.56, blue: 0.66)
    }
}

// ====== Logic (identical to Scriptable stepsAbove) ======
func stepsAbove(index: Int, maxSteps: Int = MAX_UP_STEPS) -> [ScaleRung] {
    let start = Swift.max(0, index - maxSteps)
    let slice = SCALE[start..<index]
    return Array(slice).reversed() // nearest first
}
