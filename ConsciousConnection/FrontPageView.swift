import SwiftUI
import UIKit

struct FrontPageView: View {

    @EnvironmentObject private var router: AppRouter

    @State private var isGettingReady = true

    // MARK: - Front page background controls
    // Change ONLY these numbers to reposition the artwork.
    private let backgroundScale: CGFloat = 1.1
    private let backgroundX: CGFloat = 0
    private let backgroundY: CGFloat = 0

    // MARK: - Front flower controls
    // Neutral values = exactly the current position/size.
    private let flowerScale: CGFloat = 1.0
    private let flowerX: CGFloat = 0
    private let flowerY: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // Your new artwork
                // The controls above affect ONLY this background image.
                Color(red: 0.11, green: 0.11, blue: 0.11)
                    .ignoresSafeArea()

                Image("Front_Page")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(backgroundScale)
                    .offset(
                        x: backgroundX,
                        y: backgroundY
                    )
                    .ignoresSafeArea()

                // MARK: Front Flower
                //
                // Opens the pure time/task page:
                // daisies + dice + weekly tasks.

                Button {
                    makeTapFeelGood()
                    router.path.append(.timeOnlyHome)
                } label: {
                    Image("Front_Flower")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78)
                        .scaleEffect(flowerScale)
                        .offset(
                            x: flowerX,
                            y: flowerY
                        )
                }
                .buttonStyle(FrontHubPressStyle())
                .position(
                    x: geo.size.width * 0.80,
                    y: geo.size.height * 0.285
                )
                .accessibilityLabel("Open time suggestions")


                // MARK: Main four buttons

                HStack(spacing: 11) {

                    frontButton(asset: "Ground") {
                        router.path.append(.groundHome)
                    }

                    frontButton(asset: "Create") {
                        router.path.append(.createHome)
                    }

                    frontButton(asset: "Live") {
                        router.path.append(.liveHome)
                    }

                    frontButton(asset: "Become") {
                        router.path.append(.becomeHome)
                    }
                }
                .position(
                    x: geo.size.width * 0.50,
                    y: geo.size.height * 0.635
                )
            }
        }
        .navigationBarBackButtonHidden(true)

        // Keep your existing little startup experience.
        .overlay {
            if isGettingReady {
                FrontPageStartupView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isGettingReady = false
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }


    // MARK: - Front button

    private func frontButton(
        asset: String,
        action: @escaping () -> Void
    ) -> some View {

        Button {
            makeTapFeelGood()
            action()
        } label: {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 76)
        }
        .buttonStyle(FrontHubPressStyle())
        .accessibilityLabel(asset)
    }


    private func makeTapFeelGood() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}


// MARK: - Startup screen

private struct FrontPageStartupView: View {

    let onComplete: () -> Void

    @State private var statusMessage = "Preparing your space"

    var body: some View {
        ZStack {

            Image("Wallpaper3")
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .clipped()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.58)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                VStack(spacing: 14) {

                    Image(systemName: "sparkles")
                        .font(
                            .system(
                                size: 30,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(
                            width: 68,
                            height: 68
                        )
                        .background(
                            Color.white.opacity(0.15),
                            in: Circle()
                        )

                    Text("Conscious Connection is getting ready")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    TimelineView(
                        .periodic(
                            from: .now,
                            by: 0.45
                        )
                    ) { context in

                        Text(
                            statusMessage
                            + animatedDots(at: context.date)
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            Color.white.opacity(0.82)
                        )
                        .contentTransition(.numericText())
                        .multilineTextAlignment(.center)
                        .frame(
                            maxWidth: 300,
                            minHeight: 24
                        )
                    }
                }

                Spacer()

                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                    .padding(.bottom, 54)
            }
            .padding(.horizontal, 24)
        }
        .task {
            await runStartupSequence()
        }
    }


    private func animatedDots(at date: Date) -> String {
        let phase = Int(
            date.timeIntervalSinceReferenceDate / 0.45
        ) % 4

        return String(
            repeating: ".",
            count: phase
        )
    }


    @MainActor
    private func runStartupSequence() async {

        statusMessage = "Preparing your space"

        try? await Task.sleep(
            nanoseconds: 700_000_000
        )

        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            statusMessage = "Loading your routines"
        }

        try? await Task.sleep(
            nanoseconds: 700_000_000
        )

        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            statusMessage = "Almost ready"
        }

        try? await Task.sleep(
            nanoseconds: 600_000_000
        )

        guard !Task.isCancelled else { return }

        onComplete()
    }
}


// MARK: - Front-page press

private struct FrontHubPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed ? 0.92 : 1.0
            )
            .opacity(
                configuration.isPressed ? 0.86 : 1.0
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
