import SwiftUI
import UIKit

struct ContentView: View {

    @EnvironmentObject private var router: AppRouter
    @State private var showingHabitFlow = false
    @State private var showingMagickPortal = false

    private let timeButtons: [TimeButtonConfig] = [
        .init(asset: "button02", minutes: 2,  x: 0.64, y: 0.10, width: 72),
        .init(asset: "button05", minutes: 5,  x: 0.51, y: 0.21, width: 90),
        .init(asset: "button10", minutes: 10, x: 0.30, y: 0.10, width: 150),
        .init(asset: "button15", minutes: 15, x: 0.80, y: 0.19, width: 110),
        .init(asset: "button20", minutes: 20, x: 0.84, y: 0.37, width: 100),
        .init(asset: "button30", minutes: 30, x: 0.20, y: 0.25, width: 110),
        .init(asset: "button45", minutes: 45, x: 0.84, y: 0.05, width: 80),
        .init(asset: "button60", minutes: 60, x: 0.20, y: 0.37, width: 70)
    ]

    private let gratitudeTouchstoneX: CGFloat = 0.70
    private let gratitudeTouchstoneY: CGFloat = 0.72
    private let gratitudeTouchstoneWidth: CGFloat = 95

    private let workoutIconX: CGFloat = 0.10
    private let workoutIconY: CGFloat = 0.76
    private let workoutIconWidth: CGFloat = 70

    private let habitIconX: CGFloat = 0.10
    private let habitIconY: CGFloat = 0.54
    private let habitIconWidth: CGFloat = 70

    private let workIconX: CGFloat = 0.10
    private let workIconY: CGFloat = 0.65
    private let workIconWidth: CGFloat = 75

    private let magickIconX: CGFloat = 0.30
    private let magickIconY: CGFloat = 0.55
    private let magickIconWidth: CGFloat = 68

    private let diceX: CGFloat = 0.52
    private let diceY: CGFloat = 0.53
    private let diceWidth: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("homeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ForEach(timeButtons) { item in
                    Button {
                        makeTapFeelGood()
                        router.goToTime(item.minutes)
                    } label: {
                        Image(item.asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: item.width)
                    }
                    .buttonStyle(SatisfyingPressStyle())
                    .position(
                        x: geo.size.width * item.x,
                        y: geo.size.height * item.y
                    )
                }

                leftButtons(in: geo)

                Button {
                    makeTapFeelGood()
                    router.path.append(.gratitudeTouchstone)
                } label: {
                    Image("GratitudeTouchstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: gratitudeTouchstoneWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * gratitudeTouchstoneX,
                    y: geo.size.height * gratitudeTouchstoneY
                )

                Button {
                    makeTapFeelGood()
                    router.path.append(.workoutMenu)
                } label: {
                    Image("workout")
                        .resizable()
                        .scaledToFit()
                        .frame(width: workoutIconWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * workoutIconX,
                    y: geo.size.height * workoutIconY
                )

                Button {
                    makeTapFeelGood()
                    showingHabitFlow = true
                } label: {
                    Image("HabitIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: habitIconWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * habitIconX,
                    y: geo.size.height * habitIconY
                )

                Button {
                    makeTapFeelGood()
                    handleWorkMorningIconTap()
                } label: {
                    Image("work_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: workIconWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * workIconX,
                    y: geo.size.height * workIconY
                )

                Button {
                    makeTapFeelGood()
                    showingMagickPortal = true
                } label: {
                    Image("Magickicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: magickIconWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * magickIconX,
                    y: geo.size.height * magickIconY
                )
                .accessibilityLabel("Open the Magick Portal")

                Button {
                    makeTapFeelGood()
                    router.goToTime(0)
                } label: {
                    Image("dice")
                        .resizable()
                        .scaledToFit()
                        .frame(width: diceWidth)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(
                    x: geo.size.width * diceX,
                    y: geo.size.height * diceY
                )

                Button {
                    makeTapFeelGood()
                    router.path.append(.breatheYouAreHere)
                } label: {
                    Image("youAreHere")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(x: geo.size.width * 0.82, y: geo.size.height * 0.55)

                Button {
                    makeTapFeelGood()
                    router.path = [.resetMenu]
                } label: {
                    Image("resetButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                }
                .buttonStyle(SatisfyingPressStyle())
                .position(x: geo.size.width * 0.80, y: geo.size.height * 0.90)
            }
        }
        .fullScreenCover(isPresented: $showingHabitFlow) {
            NavigationStack {
                HabitFlowRootView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") {
                                showingHabitFlow = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showingMagickPortal) {
            MagickPortalRootView {
                showingMagickPortal = false
            }
        }
    }

    @ViewBuilder
    private func leftButtons(in geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                Button {
                    makeTapFeelGood()
                    router.path.append(.goodMorning)
                } label: {
                    Image("morning")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90)
                }
                .buttonStyle(SatisfyingPressStyle())

                Button {
                    makeTapFeelGood()
                    router.path.append(.nightVideo1)
                } label: {
                    Image("night")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90)
                }
                .buttonStyle(SatisfyingPressStyle())
            }

            Button {
                makeTapFeelGood()
                router.goToWeekly()
            } label: {
                HStack(spacing: 10) {
                    Text("Weekly Tasks")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(width: 180)
                .background(Color.black.opacity(0.35))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(SatisfyingPressStyle())
        }
        .position(x: 130, y: geo.size.height * 0.913)
    }

    private func handleWorkMorningIconTap() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        guard hour < 10 else {
            router.goHome()
            return
        }

        if weekday == 2 || weekday == 6 {
            router.path.append(.workMorningIntro)
        } else {
            router.path.append(.goodMorning)
        }
    }

    private func makeTapFeelGood() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

private struct TimeButtonConfig: Identifiable {
    let id = UUID()
    let asset: String
    let minutes: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
}

private struct SatisfyingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter())
}
