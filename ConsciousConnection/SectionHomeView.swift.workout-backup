import SwiftUI
import UIKit
import StrengthLabModule

enum SectionHomeMode {
    case ground
    case live
    case create
    case become
    case timeOnly
}


struct SectionHomeView: View {

    @EnvironmentObject private var router: AppRouter

    @State private var showingHabitFlow = false
    @State private var showingStrengthLab = false
    @State private var showingMagickPortal = false

    let mode: SectionHomeMode


    private let timeButtons: [SectionTimeButton] = [
        .init(asset: "button02", minutes: 2,  x: 0.64, y: 0.10, width: 72),
        .init(asset: "button05", minutes: 5,  x: 0.51, y: 0.21, width: 90),
        .init(asset: "button10", minutes: 10, x: 0.30, y: 0.10, width: 150),
        .init(asset: "button15", minutes: 15, x: 0.80, y: 0.19, width: 110),
        .init(asset: "button20", minutes: 20, x: 0.84, y: 0.37, width: 100),
        .init(asset: "button30", minutes: 30, x: 0.20, y: 0.25, width: 110),
        .init(asset: "button45", minutes: 45, x: 0.84, y: 0.05, width: 80),
        .init(asset: "button60", minutes: 60, x: 0.20, y: 0.37, width: 70)
    ]


    private var showsTimeTools: Bool {
        mode == .live || mode == .timeOnly
    }

    private var showsWeekly: Bool {
        mode == .live || mode == .timeOnly
    }

    private var showsGround: Bool {
        mode == .ground
    }

    private var showsWorkout: Bool {
        mode == .live
    }

    private var showsHabits: Bool {
        mode == .become
    }


    var body: some View {

        GeometryReader { geo in

            ZStack {

                // EXACT same home artwork.
                Image("homeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()


                // ==================================================
                // LIVE / FLOWER:
                // DAISIES
                // ==================================================

                if showsTimeTools {

                    ForEach(timeButtons) { item in

                        Button {
                            tap()
                            router.goToTime(item.minutes)
                        } label: {

                            Image(item.asset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: item.width)
                        }
                        .buttonStyle(SectionPressStyle())
                        .position(
                            x: geo.size.width * item.x,
                            y: geo.size.height * item.y
                        )
                    }


                    // Dice

                    Button {
                        tap()
                        router.goToTime(0)
                    } label: {

                        Image("dice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.52,
                        y: geo.size.height * 0.53
                    )
                }


                // ==================================================
                // GROUND
                // ==================================================

                if showsGround {

                    // Gratitude

                    Button {
                        tap()
                        router.path.append(.gratitudeTouchstone)
                    } label: {

                        Image("GratitudeTouchstone")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 95)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.70,
                        y: geo.size.height * 0.72
                    )


                    // You Are Here / breathing

                    Button {
                        tap()
                        router.path.append(.breatheYouAreHere)
                    } label: {

                        Image("youAreHere")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.32,
                        y: geo.size.height * 0.13
                    )


                    // Reset

                    Button {
                        tap()
                        router.path = [.resetMenu]
                    } label: {

                        Image("resetButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.68,
                        y: geo.size.height * 0.13
                    )


                    // Magick — provisional home!

                    Button {
                        tap()
                        showingMagickPortal = true
                    } label: {

                        Image("Magickicon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 68)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.78,
                        y: geo.size.height * 0.48
                    )
                    .accessibilityLabel("Magick")


                    // Morning + Night stay where they were.

                    HStack(spacing: 6) {

                        Button {
                            tap()
                            router.path.append(.goodMorning)
                        } label: {

                            Image("morning")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90)
                        }
                        .buttonStyle(SectionPressStyle())


                        Button {
                            tap()
                            router.path.append(.nightVideo1)
                        } label: {

                            Image("night")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90)
                        }
                        .buttonStyle(SectionPressStyle())
                    }
                    .position(
                        x: 130,
                        y: geo.size.height * 0.913
                    )
                }


                // ==================================================
                // LIVE:
                // WORKOUT
                // ==================================================

                if showsWorkout {

                    Button {
                        tap()
                        showingStrengthLab = true
                    } label: {

                        Image("workout")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.10,
                        y: geo.size.height * 0.76
                    )
                }


                // ==================================================
                // BECOME:
                // HABIT TRACKER
                // ==================================================

                if showsHabits {

                    Button {
                        tap()
                        showingHabitFlow = true
                    } label: {

                        Image("HabitIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: geo.size.width * 0.10,
                        y: geo.size.height * 0.54
                    )
                }


                // ==================================================
                // LIVE + FLOWER:
                // WEEKLY TASKS
                // ==================================================

                if showsWeekly {

                    Button {
                        tap()
                        router.goToWeekly()
                    } label: {

                        HStack(spacing: 10) {

                            Text("Weekly Tasks")
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .frame(width: 180)
                        .background(
                            Color.black.opacity(0.35)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .buttonStyle(SectionPressStyle())
                    .position(
                        x: 130,
                        y: geo.size.height * 0.913
                    )
                }


                // ==================================================
                // CREATE
                // Blank deliberately.
                // ==================================================
            }
        }

        // Embedded StrengthLab: opens inside ConsciousConnection, not by URL.
        .fullScreenCover(isPresented: $showingStrengthLab) {
            VStack(spacing: 0) {
                HStack {
                    Text("StrengthLab")
                        .font(.headline)
                    Spacer()
                    Button("Done") {
                        showingStrengthLab = false
                    }
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)

                StrengthLabRootView()
            }
        }

        // Habit tracker retains its existing full-screen flow.
        .fullScreenCover(
            isPresented: $showingHabitFlow
        ) {

            NavigationStack {

                HabitFlowRootView()
                    .toolbar {

                        ToolbarItem(
                            placement: .topBarLeading
                        ) {

                            Button("Close") {
                                showingHabitFlow = false
                            }
                        }
                    }
            }
        }


        // Magick retains its existing portal.
        .fullScreenCover(
            isPresented: $showingMagickPortal
        ) {

            MagickPortalRootView {
                showingMagickPortal = false
            }
        }
    }





    private func tap() {
        let generator = UIImpactFeedbackGenerator(
            style: .medium
        )

        generator.prepare()
        generator.impactOccurred()
    }
}


// MARK: - Time Button

private struct SectionTimeButton: Identifiable {

    let id = UUID()

    let asset: String
    let minutes: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
}


// MARK: - Press style

private struct SectionPressStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .scaleEffect(
                configuration.isPressed ? 0.93 : 1.0
            )
            .opacity(
                configuration.isPressed ? 0.88 : 1.0
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
