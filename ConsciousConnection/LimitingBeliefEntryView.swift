import SwiftUI

struct LimitingBeliefEntryView: View {
    let onCancel: () -> Void
    let onContinue: (String) -> Void

    @State private var belief = ""
    @FocusState private var beliefFieldIsFocused: Bool

    private var trimmedBelief: String {
        belief.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Image("prison")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.66)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.48))
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color.white.opacity(0.24),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close limiting beliefs")
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer(minLength: 260)

                beliefCard
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture {
            beliefFieldIsFocused = false
        }
    }

    private var beliefCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LIMITING BELIEFS")
                .font(.custom("Poppins-SemiBold", size: 12))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.72))

            Text("What belief is keeping you trapped?")
                .font(.custom("Poppins-SemiBold", size: 29))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Write it exactly as it appears in your mind.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundStyle(.white.opacity(0.72))

            ZStack(alignment: .topLeading) {
                if belief.isEmpty {
                    Text(
                        "For example: I will never be financially secure"
                    )
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 17)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $belief)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .scrollContentBackground(.hidden)
                    .focused($beliefFieldIsFocused)
                    .frame(minHeight: 112, maxHeight: 150)
                    .padding(10)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.13), lineWidth: 1)
            )

            Button {
                beliefFieldIsFocused = false
                onContinue(trimmedBelief)
            } label: {
                HStack(spacing: 10) {
                    Text("Continue to Spiral States")
                        .font(.custom("Poppins-SemiBold", size: 17))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.40))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(trimmedBelief.isEmpty)
            .opacity(trimmedBelief.isEmpty ? 0.45 : 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.56))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(0.34),
            radius: 18,
            x: 0,
            y: 10
        )
    }
}

#Preview {
    LimitingBeliefEntryView(
        onCancel: {},
        onContinue: { _ in }
    )
}
