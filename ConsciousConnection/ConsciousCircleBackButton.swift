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

// Attach the close button to the actual destination, not the entire stack.
// SwiftUI's dismiss action can pop both value-based and view-based links.
private struct ConsciousNavigationBackModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let hidesDuringPerformance: Bool
    @State private var hiddenForPerformance = false

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .overlay(alignment: .topLeading) {
                if !hiddenForPerformance {
                    ConsciousCircleBackButton { dismiss() }
                        .padding(.leading, 20)
                        .padding(.top, 18)
                        .zIndex(999)
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name("KeysStudioPerformanceVisibility")
            )) { event in
                guard hidesDuringPerformance else { return }
                hiddenForPerformance = (event.object as? Bool) == true
            }
    }
}

extension View {
    func consciousNavigationBack(hidesDuringPerformance: Bool = false) -> some View {
        modifier(ConsciousNavigationBackModifier(hidesDuringPerformance: hidesDuringPerformance))
    }
}
