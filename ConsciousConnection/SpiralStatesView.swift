import SwiftUI

struct SpiralStatesView: View {

    @EnvironmentObject private var router: AppRouter

    let trigger: String
    let onPickStateIndex: (Int) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("statesBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spiral States")
                            .font(.custom("Poppins-SemiBold", size: 30))
                            .foregroundStyle(.white)

                        Text("Choose your current state")
                            .font(.custom("Poppins-Regular", size: 17))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(.top, 8)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Text("Trigger")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                        .textCase(.uppercase)
                        .listRowBackground(Color.clear)

                    Text(trigger)
                        .font(.custom("Poppins-Medium", size: 17))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .listRowBackground(Color.clear)
                }

                ForEach(SCALE) { rung in
                    Button {
                        onPickStateIndex(rung.r - 1)
                    } label: {
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
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)

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
}
