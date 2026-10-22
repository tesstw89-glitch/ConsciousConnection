import SwiftUI

/// Consistent 44-point circular X for navigation and modal dismissal.
struct ConsciousCircleBackButton: View {
    var accessibilityLabel: String
    let action: () -> Void

    init(accessibilityLabel: String = "Back", action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.48), in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.55), lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Returns to the previous screen or closes this section")
    }
}
