import Foundation

struct ExerciseCatalogItem: Identifiable, Hashable {
    let name: String
    let category: String
    let equipment: String
    let gifURL: URL?

    var id: String { name }
}

enum ExerciseCatalog {
    static let all: [ExerciseCatalogItem] = [
        // Chest
        .init(name: "Barbell Bench Press", category: "Chest", equipment: "Barbell", gifURL: nil),
        .init(name: "Dumbbell Bench Press", category: "Chest", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Incline Dumbbell Press", category: "Chest", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Incline Barbell Press", category: "Chest", equipment: "Barbell", gifURL: nil),
        .init(name: "Chest Press", category: "Chest", equipment: "Machine", gifURL: nil),
        .init(name: "Cable Fly", category: "Chest", equipment: "Cable", gifURL: nil),
        .init(name: "Pec Deck", category: "Chest", equipment: "Machine", gifURL: nil),
        .init(name: "Push-Up", category: "Chest", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Dip", category: "Chest", equipment: "Bodyweight", gifURL: nil),

        // Back
        .init(name: "Lat Pulldown", category: "Back", equipment: "Cable", gifURL: nil),
        .init(name: "Pull-Up", category: "Back", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Assisted Pull-Up", category: "Back", equipment: "Machine", gifURL: nil),
        .init(name: "Chin-Up", category: "Back", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Barbell Row", category: "Back", equipment: "Barbell", gifURL: nil),
        .init(name: "Dumbbell Row", category: "Back", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Seated Cable Row", category: "Back", equipment: "Cable", gifURL: nil),
        .init(name: "Chest-Supported Row", category: "Back", equipment: "Machine", gifURL: nil),
        .init(name: "Straight-Arm Pulldown", category: "Back", equipment: "Cable", gifURL: nil),
        .init(name: "Face Pull", category: "Back", equipment: "Cable", gifURL: nil),

        // Shoulders
        .init(
            name: "Dumbbell Shoulder Press",
            category: "Shoulders",
            equipment: "Dumbbells",
            gifURL: URL(string: "https://raw.githubusercontent.com/tesstw89-glitch/StrengthLabMedia/main/shoulder-press-full.gif")
        ),
        .init(name: "Barbell Overhead Press", category: "Shoulders", equipment: "Barbell", gifURL: nil),
        .init(name: "Machine Shoulder Press", category: "Shoulders", equipment: "Machine", gifURL: nil),
        .init(name: "Arnold Press", category: "Shoulders", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Lateral Raise", category: "Shoulders", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Cable Lateral Raise", category: "Shoulders", equipment: "Cable", gifURL: nil),
        .init(name: "Front Raise", category: "Shoulders", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Reverse Fly", category: "Shoulders", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Rear Delt Fly", category: "Shoulders", equipment: "Machine", gifURL: nil),

        // Quads / legs
        .init(name: "Back Squat", category: "Legs", equipment: "Barbell", gifURL: nil),
        .init(name: "Front Squat", category: "Legs", equipment: "Barbell", gifURL: nil),
        .init(name: "Goblet Squat", category: "Legs", equipment: "Dumbbell", gifURL: nil),
        .init(name: "Leg Press", category: "Legs", equipment: "Machine", gifURL: nil),
        .init(name: "Hack Squat", category: "Legs", equipment: "Machine", gifURL: nil),
        .init(name: "Leg Extension", category: "Legs", equipment: "Machine", gifURL: nil),
        .init(name: "Walking Lunge", category: "Legs", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Reverse Lunge", category: "Legs", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Bulgarian Split Squat", category: "Legs", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Step-Up", category: "Legs", equipment: "Dumbbells", gifURL: nil),

        // Glutes / hamstrings
        .init(name: "Romanian Deadlift", category: "Glutes & Hamstrings", equipment: "Barbell", gifURL: nil),
        .init(name: "Dumbbell Romanian Deadlift", category: "Glutes & Hamstrings", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Conventional Deadlift", category: "Glutes & Hamstrings", equipment: "Barbell", gifURL: nil),
        .init(name: "Hip Thrust", category: "Glutes & Hamstrings", equipment: "Barbell", gifURL: nil),
        .init(name: "Glute Bridge", category: "Glutes & Hamstrings", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Seated Leg Curl", category: "Glutes & Hamstrings", equipment: "Machine", gifURL: nil),
        .init(name: "Lying Leg Curl", category: "Glutes & Hamstrings", equipment: "Machine", gifURL: nil),
        .init(name: "Cable Kickback", category: "Glutes & Hamstrings", equipment: "Cable", gifURL: nil),
        .init(name: "Hip Abduction", category: "Glutes & Hamstrings", equipment: "Machine", gifURL: nil),

        // Arms
        .init(name: "Barbell Curl", category: "Arms", equipment: "Barbell", gifURL: nil),
        .init(name: "Dumbbell Curl", category: "Arms", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Hammer Curl", category: "Arms", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Preacher Curl", category: "Arms", equipment: "Machine", gifURL: nil),
        .init(name: "Cable Curl", category: "Arms", equipment: "Cable", gifURL: nil),
        .init(name: "Triceps Pushdown", category: "Arms", equipment: "Cable", gifURL: nil),
        .init(name: "Overhead Triceps Extension", category: "Arms", equipment: "Cable", gifURL: nil),
        .init(name: "Skull Crusher", category: "Arms", equipment: "Barbell", gifURL: nil),
        .init(name: "Triceps Dip", category: "Arms", equipment: "Bodyweight", gifURL: nil),

        // Core
        .init(name: "Plank", category: "Core", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Side Plank", category: "Core", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Dead Bug", category: "Core", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Bird Dog", category: "Core", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Hanging Leg Raise", category: "Core", equipment: "Bodyweight", gifURL: nil),
        .init(name: "Cable Crunch", category: "Core", equipment: "Cable", gifURL: nil),
        .init(name: "Pallof Press", category: "Core", equipment: "Cable", gifURL: nil),
        .init(name: "Russian Twist", category: "Core", equipment: "Plate", gifURL: nil),

        // Calves / full body
        .init(name: "Standing Calf Raise", category: "Calves", equipment: "Machine", gifURL: nil),
        .init(name: "Seated Calf Raise", category: "Calves", equipment: "Machine", gifURL: nil),
        .init(name: "Farmer's Carry", category: "Full Body", equipment: "Dumbbells", gifURL: nil),
        .init(name: "Kettlebell Swing", category: "Full Body", equipment: "Kettlebell", gifURL: nil),
        .init(name: "Sled Push", category: "Full Body", equipment: "Sled", gifURL: nil)
    ]

    static let categories = [
        "All",
        "Chest",
        "Back",
        "Shoulders",
        "Legs",
        "Glutes & Hamstrings",
        "Arms",
        "Core",
        "Calves",
        "Full Body"
    ]
}
