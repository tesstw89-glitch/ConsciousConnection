import SwiftUI
import AVFoundation

// ✅ IMPORTANT: no NavigationStack in here.
// This view is pushed by the ONE NavigationStack in ConsciousConnectionApp.

struct StatesView: View {

    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            Image("statesBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("States")
                            .font(.custom("Poppins-SemiBold", size: 30))
                            .foregroundStyle(.white)

                        Text("How do you feel?")
                            .font(.custom("Poppins-Regular", size: 17))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(.top, 8)
                    .listRowBackground(Color.clear)
                }

                sectionHeader("High (1–14)")
                ForEach(SCALE.filter { $0.r <= 14 }) { rung in
                    Button {
                        router.path.append(.stateDetail(rung.r - 1))
                    } label: {
                        rungRow(rung)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }

                sectionHeader("Mid (15–28)")
                ForEach(SCALE.filter { $0.r >= 15 && $0.r <= 28 }) { rung in
                    Button {
                        router.path.append(.stateDetail(rung.r - 1))
                    } label: {
                        rungRow(rung)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }

                sectionHeader("Low (29–43)")
                ForEach(SCALE.filter { $0.r >= 29 }) { rung in
                    Button {
                        router.path.append(.stateDetail(rung.r - 1))
                    } label: {
                        rungRow(rung)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        router.goHome()
                    } label: {
                        Text("Home")
                            .font(.custom("Poppins-Medium", size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.22))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.custom("Poppins-SemiBold", size: 12))
            .foregroundStyle(.white.opacity(0.62))
            .listRowBackground(Color.clear)
    }

    private func rungRow(_ rung: ScaleRung) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(rung.r). \(rung.name)")
                .font(.custom("Poppins-Medium", size: 17))
                .foregroundStyle(tierAccent(rung.r))
                .multilineTextAlignment(.leading)

            if rung.r >= 15, let ref = REFRAME[rung.r] {
                Text(ref)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tierBackground(rung.r).opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Detail screen

struct StateDetailView: View {

    @EnvironmentObject private var router: AppRouter

    let index: Int
    let onClimbTo: (Int) -> Void

    @State private var speaker = SpeechHelper()

    var body: some View {
        let cur = SCALE[index]
        let up = stepsAbove(index: index)

        ZStack {
            Image("statesBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.20)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    VStack(alignment: .leading, spacing: 10) {
                        Text("You chose")
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundStyle(.white.opacity(0.78))

                        Text("\(cur.r). \(cur.name)")
                            .font(.custom("Poppins-SemiBold", size: 22))
                            .foregroundStyle(tierAccent(cur.r))
                    }
                    .padding(18)
                    .background(Color.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Can we move to…")
                            .font(.custom("Poppins-SemiBold", size: 22))
                            .foregroundStyle(.white)

                        if up.isEmpty {
                            Text("Already at the top")
                                .font(.custom("Poppins-Medium", size: 17))
                                .foregroundStyle(.white.opacity(0.76))
                        } else {
                            VStack(spacing: 10) {
                                ForEach(up) { s in
                                    Button {
                                        onClimbTo(s.r - 1)
                                    } label: {
                                        HStack {
                                            Text("→ \(s.r). \(s.name)")
                                                .font(.custom("Poppins-Medium", size: 17))
                                                .foregroundStyle(tierAccent(s.r))
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(tierBackground(s.r).opacity(0.58))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(20)

                    if cur.r >= 15, let ref = REFRAME[cur.r] {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Polarising Positive")
                                .font(.custom("Poppins-SemiBold", size: 22))
                                .foregroundStyle(.white)

                            Text(ref)
                                .font(.custom("Poppins-Regular", size: 17))
                                .foregroundStyle(.white.opacity(0.88))
                        }
                        .padding(18)
                        .background(Color.black.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .cornerRadius(20)
                    }

                    Button {
                        speaker.speak(detailSpeechText(cur: cur, up: up))
                    } label: {
                        Text("Speak")
                            .font(.custom("Poppins-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.30))
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Button {
                        router.goHome()
                    } label: {
                        Text("Home")
                            .font(.custom("Poppins-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.22))
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(18)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailSpeechText(cur: ScaleRung, up: [ScaleRung]) -> String {
        var text = "You chose: \(cur.name). "
        if !up.isEmpty {
            let list = up.map { $0.name }.joined(separator: ", ")
            text += "Can we move to: \(list). "
        } else {
            text += "You're already at the highest state. "
        }
        if cur.r >= 15, let ref = REFRAME[cur.r] {
            text += "Polarising positive: \(ref)."
        }
        return text
    }
}
