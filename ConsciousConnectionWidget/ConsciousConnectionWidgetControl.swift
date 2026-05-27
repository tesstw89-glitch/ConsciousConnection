import AppIntents
import SwiftUI
import WidgetKit

struct ConsciousConnectionWidgetControl: ControlWidget {
    static let kind = "com.tess.ConsciousConnection.ConsciousConnectionWidgetControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenConsciousConnectionIntent()) {
                Label("Conscious Connection", systemImage: "sparkles")
            }
        }
        .displayName("Conscious Connection")
        .description("Open the right screen for this time of day.")
    }
}
