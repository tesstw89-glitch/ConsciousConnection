import SwiftUI

struct WorkoutScreenBackground: View {
    var body: some View {
        Image("workoutbackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

struct WorkoutPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct WorkoutMenuButton: View {
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.black.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(WorkoutPressStyle())
    }
}
