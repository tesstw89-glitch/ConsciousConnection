import AppIntents

struct OpenConsciousConnectionIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Conscious Connection"
    static let description = IntentDescription(
        "Open Conscious Connection and route to the right screen for this time of day."
    )

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.tess.ConsciousConnection")
        defaults?.set(Date().timeIntervalSince1970, forKey: "LockScreenLaunchRequest")
        return .result()
    }
}

extension OpenConsciousConnectionIntent {
    static var openAppWhenRun: Bool { true }
}
