import SwiftUI

struct SpiralDetailView: View {

    let trigger: String
    let rung: ScaleRung

    let onChangeState: (ScaleRung) -> Void
    let onGoEMT: (Int) -> Void
    let onReset: () -> Void

    var body: some View {

        let index = min(max(rung.r - 1, 0), SCALE.count - 1)
        let higher = stepsAbove(index: index)

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

                        Text("\(rung.r). \(rung.name)")
                            .font(.custom("Poppins-SemiBold", size: 22))
                            .foregroundStyle(tierAccent(rung.r))
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

                        if higher.isEmpty {
                            Text("Already at the top")
                                .font(.custom("Poppins-Medium", size: 17))
                                .foregroundStyle(.white.opacity(0.76))
                        } else {
                            VStack(spacing: 10) {
                                ForEach(higher) { step in
                                    Button {
                                        onChangeState(step)
                                    } label: {
                                        HStack {
                                            Text("→ \(step.r). \(step.name)")
                                                .font(.custom("Poppins-Medium", size: 17))
                                                .foregroundStyle(tierAccent(step.r))
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(tierBackground(step.r).opacity(0.58))
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

                    if let reframe = REFRAME[rung.r] {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Polarising Positive")
                                .font(.custom("Poppins-SemiBold", size: 22))
                                .foregroundStyle(.white)

                            Text(reframe)
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
                        onGoEMT(index)
                    } label: {
                        Text("Next: EMT")
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
                        onReset()
                    } label: {
                        Text("Reset Flow")
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
}
