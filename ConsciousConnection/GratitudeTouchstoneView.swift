import SwiftUI

struct GratitudeTouchstoneView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draftText: String = ""
    @State private var hasSubmitted: Bool = false

    @State private var textAreaOpacity: Double = 1
    @State private var envelopeVisible: Bool = false
    @State private var envelopeOffsetY: CGFloat = 420
    @State private var envelopeScale: CGFloat = 0.82

    @FocusState private var isTextEditorFocused: Bool

    private let actionButtonX: CGFloat = 0.86
    private let actionButtonY: CGFloat = 0.90
    private let actionButtonWidth: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("GratitudeTouchstoneBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    if !hasSubmitted || textAreaOpacity > 0.01 {
                        VStack(spacing: 16) {
                            Text("Your Gratitude Touchstone")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.94))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

                                if draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Write your touchstone here...")
                                        .font(.system(size: 20, weight: .medium, design: .rounded))
                                        .foregroundStyle(.gray.opacity(0.8))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 18)
                                }

                                TextEditor(text: $draftText)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .focused($isTextEditorFocused)
                            }
                            .frame(width: min(geo.size.width * 0.82, 520), height: 170)
                        }
                        .opacity(textAreaOpacity)
                        .offset(y: -120)
                    }

                    Spacer()
                }

                if envelopeVisible {
                    Image("heartsent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geo.size.width * 0.34, 210))
                        .scaleEffect(envelopeScale)
                        .offset(y: envelopeOffsetY)
                }

                Group {
                    if hasSubmitted {
                        Button {
                            dismiss()
                        } label: {
                            Image("homeButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: actionButtonWidth)
                        }
                    } else {
                        Button {
                            submitTouchstone()
                        } label: {
                            Image("done")
                                .resizable()
                                .scaledToFit()
                                .frame(width: actionButtonWidth)
                        }
                    }
                }
                .buttonStyle(TouchstonePressStyle())
                .position(
                    x: geo.size.width * actionButtonX,
                    y: geo.size.height * actionButtonY
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextEditorFocused = false
            }
            .onAppear {
                draftText = ""
                resetAnimationState()
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private func resetAnimationState() {
        hasSubmitted = false
        textAreaOpacity = 1
        envelopeVisible = false
        envelopeOffsetY = 420
        envelopeScale = 0.82
        isTextEditorFocused = false
    }

    private func submitTouchstone() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isTextEditorFocused = false
        draftText = trimmed
        hasSubmitted = true

        withAnimation(.easeOut(duration: 0.22)) {
            textAreaOpacity = 0
        }

        envelopeVisible = true
        envelopeOffsetY = 420
        envelopeScale = 0.82

        withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
            envelopeOffsetY = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeOut(duration: 0.12)) {
                envelopeScale = 1.12
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.14)) {
                    envelopeScale = 1.0
                }
            }
        }
    }
}

private struct TouchstonePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
