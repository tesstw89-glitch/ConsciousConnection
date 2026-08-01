import SwiftUI

struct SpiralTriggerView: View {

    let onPick: (String) -> Void

    private let triggers: [String] = [
        "Feeling alone / emotionally untethered",
        "Criticism, rejection, or “I’m not valued”",
        "Time pressure + high responsibility (NHS midwife mode)",
        "Not meeting your own impossible standards",
        "Powerlessness around security + home"
    ]

    var body: some View {
        ZStack {
            Image("spiralBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SPIRAL")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.72))

                        Text("What’s active right now?")
                            .font(.custom("Poppins-SemiBold", size: 31))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Choose the pain-body theme first, then choose your state.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    // Trigger cards
                    VStack(spacing: 14) {
                        ForEach(Array(triggers.enumerated()), id: \.offset) { index, trigger in
                            Button {
                                onPick(trigger)
                            } label: {
                                HStack(alignment: .center, spacing: 14) {

                                    Text(String(format: "%02d", index + 1))
                                        .font(.custom("Poppins-SemiBold", size: 12))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.10))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                        )

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(trigger)
                                            .font(.custom("Poppins-Medium", size: 18))
                                            .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.28))
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text("Tap to choose")
                                            .font(.custom("Poppins-Regular", size: 12))
                                            .foregroundStyle(.white.opacity(0.58))
                                    }

                                    Spacer(minLength: 8)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.65))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.08))
                                        )
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color.black.opacity(0.26))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
                            }
                            .buttonStyle(SpiralCardPressStyle())
                        }
                    }

                    // Tip
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TIP")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.70))

                        Text("Pick the one that’s most active right now — even if it’s only 1%.")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SpiralCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        Color.white.opacity(configuration.isPressed ? 0.18 : 0),
                        lineWidth: 1.2
                    )
            )
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    SpiralTriggerView { _ in }
}
