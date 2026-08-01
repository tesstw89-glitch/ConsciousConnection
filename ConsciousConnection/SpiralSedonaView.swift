import SwiftUI

struct SpiralSedonaView: View {

    @EnvironmentObject private var router: AppRouter

    let trigger: String
    let index: Int   // 0-based

    @State private var speaker = SpeechHelper()

    enum WantMode: String, CaseIterable {
        case basic = "Basic want"
        case fear = "Fear-as-want"
    }

    @State private var mode: WantMode = .basic

    private let wants: [String] = [
        "Control / wanting to be controlled",
        "Security / Safety (or danger-ending-it-all)",
        "Approval / Disapproval",
        "Oneness / Separation"
    ]

    @State private var selectedWant: String = "Approval / Disapproval"
    @State private var customWant: String = ""
    @State private var fearText: String = ""
    @State private var showQuestions = false

    var body: some View {
        let safeIndex = min(max(index, 0), SCALE.count - 1)
        let rung = SCALE[safeIndex]

        ZStack(alignment: .bottomTrailing) {
            Image("sedonaBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.26)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("SEDONA")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.74))

                        Text(showQuestions ? "The questions" : "Choose the frame")
                            .font(.custom("Poppins-SemiBold", size: 30))
                            .foregroundStyle(.white)

                        Text("Move gently through the frame, then the release questions.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundStyle(.white.opacity(0.76))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TRIGGER")
                                .font(.custom("Poppins-SemiBold", size: 11))
                                .tracking(1.4)
                                .foregroundStyle(.white.opacity(0.60))

                            Text(trigger)
                                .font(.custom("Poppins-Medium", size: 18))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)

                    if !showQuestions {
                        framePickerCard()

                        primaryButton("Speak Sedona") {
                            speaker.speak(sedonaScript(trigger: trigger, rung: rung))
                        }
                    } else {
                        questionsCard(trigger: trigger, rung: rung)

                        primaryButton("Speak this") {
                            speaker.speak(sedonaScript(trigger: trigger, rung: rung))
                        }

                        secondaryButton("Change frame / want") {
                            showQuestions = false
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 140)
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
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Main cards

    @ViewBuilder
    private func framePickerCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose the frame")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(.white)

            modeSwitch

            if mode == .fear {
                fieldCard(
                    title: "Name the fear",
                    subtitle: "One short sentence.",
                    placeholder: "e.g. I fear messing up",
                    text: $fearText
                )
            }

            wantPickerCard()

            if mode == .fear {
                fieldCard(
                    title: "Optional custom want",
                    subtitle: "Only if none of the options fit.",
                    placeholder: "e.g. certainty / approval / safety",
                    text: $customWant
                )
            }

            primaryButton("Continue to questions") {
                showQuestions = true
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }

    private var modeSwitch: some View {
        HStack(spacing: 8) {
            modeButton(.basic)
            modeButton(.fear)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func modeButton(_ buttonMode: WantMode) -> some View {
        Button {
            mode = buttonMode
        } label: {
            Text(buttonMode.rawValue)
                .font(.custom("Poppins-Medium", size: 15))
                .foregroundStyle(mode == buttonMode ? Color.black : Color.white.opacity(0.82))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(mode == buttonMode ? Color.white.opacity(0.92) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func wantPickerCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mode == .basic ? "Pick the basic want" : "Pick the want under the fear")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundStyle(.white)

            Picker("Want", selection: $selectedWant) {
                ForEach(wants, id: \.self) { w in
                    Text(w).tag(w)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)

            Text("Chosen: \(finalWant())")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func fieldCard(
        title: String,
        subtitle: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.65))

            TextField(placeholder, text: text, axis: .vertical)
                .font(.custom("Poppins-Regular", size: 15))
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func questionsCard(trigger: String, rung: ScaleRung) -> some View {
        let want = finalWant()

        return VStack(alignment: .leading, spacing: 14) {
            Text("Context")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundStyle(.white)

            Text(
                "Trigger: \(trigger)\nState: \(rung.r). \(rung.name)\(mode == .fear ? "\nFear: \(fearText.isEmpty ? "(not set)" : fearText)" : "")\nWant: \(want)"
            )
            .font(.custom("Poppins-Regular", size: 13))
            .foregroundStyle(.white.opacity(0.76))
            .fixedSize(horizontal: false, vertical: true)

            Divider()
                .overlay(Color.white.opacity(0.10))

            if mode == .fear {
                qRow(
                    number: "01",
                    title: "Could I welcome wanting this fear to happen, just for now?",
                    subtitle: "Let the sensation be here without fixing it."
                )

                qRow(
                    number: "02",
                    title: "Could I let go of wanting this fear to happen?",
                    subtitle: "Even a tiny bit. Even for a moment."
                )
            } else {
                qRow(
                    number: "01",
                    title: "Could I welcome this, just for now?",
                    subtitle: "Let the sensation be here without fixing it."
                )

                qRow(
                    number: "02",
                    title: "Could I let go of wanting \(want)?",
                    subtitle: "Even a tiny bit. Even for a moment."
                )
            }

            qRow(
                number: "03",
                title: "Would I?",
                subtitle: "If yes: softly. If no: that’s okay—just notice the resistance."
            )

            qRow(
                number: "04",
                title: "When?",
                subtitle: "Now… or later. If you can, choose now."
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }

    private func qRow(number: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.custom("Poppins-SemiBold", size: 11))
                .foregroundStyle(.white.opacity(0.90))
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(Color.white.opacity(0.10))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Buttons

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 17))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Medium", size: 16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func finalWant() -> String {
        let trimmed = customWant.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .fear, !trimmed.isEmpty {
            return trimmed
        }
        return selectedWant
    }

    private func sedonaScript(trigger: String, rung: ScaleRung) -> String {
        let want = finalWant()

        if mode == .fear {
            let fear = fearText.trimmingCharacters(in: .whitespacesAndNewlines)
            let f = fear.isEmpty ? "this fear" : fear

            return """
            Sedona. Trigger: \(trigger). Notice \(rung.name) as sensation.
            Could I welcome wanting this fear to happen… just for now?
            The fear is: \(f).
            The want underneath is: \(want).
            Could I let go of wanting this fear to happen?
            Would I?
            When?
            Now check your body.
            """
        }

        return """
        Sedona. Trigger: \(trigger). Notice \(rung.name) as sensation.
        Can I welcome this, just for now?
        Your chosen want is: \(want).
        Could I let go of wanting \(want), even a little?
        Would I?
        When?
        Now check your body.
        """
    }
}
