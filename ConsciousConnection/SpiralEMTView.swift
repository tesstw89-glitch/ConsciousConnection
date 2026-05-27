import SwiftUI

struct SpiralEMTView: View {

    @EnvironmentObject private var router: AppRouter

    let trigger: String
    let index: Int
    let onNext: () -> Void

    @State private var speaker = SpeechHelper()

    var body: some View {

        let safeIndex = min(max(index, 0), SCALE.count - 1)
        let rung = SCALE[safeIndex]

        ZStack(alignment: .topTrailing) {
            Image("EMTbackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMT")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.72))

                        Text("Eye movements")
                            .font(.custom("Poppins-SemiBold", size: 30))
                            .foregroundStyle(.white)

                        Text("Step 2: gentle eye movements only. No analysis, no fixing.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TRIGGER")
                                .font(.custom("Poppins-SemiBold", size: 11))
                                .tracking(1.4)
                                .foregroundStyle(.white.opacity(0.58))

                            Text(trigger)
                                .font(.custom("Poppins-Medium", size: 18))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.24))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.20), radius: 16, x: 0, y: 8)

                    stepCard(
                        number: "01",
                        title: "Up & Down",
                        body: "Head still. Eyes only.\nLook up and down slowly 10–20 times.\nPause. Notice your body."
                    )

                    stepCard(
                        number: "02",
                        title: "Side to Side",
                        body: "Head still. Eyes only.\nLook left and right slowly 10–20 times.\nPause. Notice your body."
                    )

                    stepCard(
                        number: "03",
                        title: "Repeat if needed",
                        body: "Do 2–4 gentle rounds.\nStop if you feel worse or spaced-out.\nThen just breathe and feel your feet."
                    )

                    Button {
                        speaker.speak(emtSpeech(trigger: trigger, rung: rung))
                    } label: {
                        Text("Speak EMT")
                            .font(.custom("Poppins-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.black.opacity(0.28))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Button {
                        onNext()
                    } label: {
                        Text("Move on to Sedona")
                            .font(.custom("Poppins-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.black.opacity(0.34))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Text("Even 1% is enough.")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
                .padding(18)
                .padding(.bottom, 28)
            }

            Button {
                router.goHome()
            } label: {
                Image("homeButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 95)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - UI bits

    private func stepCard(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {

            Text(number)
                .font(.custom("Poppins-SemiBold", size: 11))
                .foregroundStyle(.white.opacity(0.90))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.10))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 19))
                    .foregroundStyle(.white)

                Text(body)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }

    // MARK: - Speech

    private func emtSpeech(trigger: String, rung: ScaleRung) -> String {
        let text =
        "EMT. Trigger: \(trigger). " +
        "Notice \(rung.name) as sensation in the body. " +
        "Keep your head still. Move your eyes up and down slowly ten to twenty times. Pause and notice. " +
        "Then move your eyes side to side slowly ten to twenty times. Pause and notice. " +
        "Repeat for two to four rounds if you want. Stop if you feel worse or spaced out. " +
        "Then breathe and feel your feet."
        return text
    }
}
