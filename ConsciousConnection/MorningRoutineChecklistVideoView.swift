import SwiftUI
import AVKit

struct MorningRoutineChecklistVideoView: View {

    @EnvironmentObject private var router: AppRouter
    @State private var player: AVPlayer? = nil

    private var todayItems: [String] {
        switch Calendar.current.component(.weekday, from: Date()) {
        case 2, 6: // Monday, Friday
            return [
                "Make Breakfast",
                "Take Vitamins",
                "Remember Lunch"
            ]

        case 3: // Tuesday
            return [
                "Put on Feelgood music",
                "Make Otis' Breakfast",
                "Make Coffee",
                "Wash Sheets & Remake bed",
                "Shower & Dress",
                "Eat Breakfast"
            ]

        case 4: // Wednesday
            return [
                "Put on Feelgood music",
                "Make Otis' Breakfast",
                "Make Coffee",
                "Put on a Wash",
                "Shower & Dress",
                "Eat Breakfast"
            ]

        case 5: // Thursday
            return [
                "Put on Feelgood music",
                "Make Otis' Breakfast",
                "Make Coffee",
                "Put on a Wash",
                "Shower & Dress",
                "Eat Breakfast"
            ]

        case 7: // Saturday
            return [
                "Put on Feelgood music",
                "Make Bed",
                "Shower & Dress"
            ]

        case 1: // Sunday
            return [
                "Put on Feelgood music",
                "Make Bed",
                "Put on a Wash",
                "Shower & Dress"
            ]

        default:
            return []
        }
    }

    var body: some View {
        ZStack {

            // VIDEO
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
            } else {
                Color.black.ignoresSafeArea()
                Text("Loading…")
                    .foregroundColor(.white)
            }

            // CHECKLIST
            VStack {
                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(todayItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Text("•")
                                    .font(.custom("Mukti", size: 40))
                                    .foregroundColor(.white)

                                Text(item)
                                    .font(.custom("Mukti", size: 28))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.leading, 28)
                    .padding(.trailing, 28)
                    .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: 2)

                    Spacer()
                }
                .offset(y: 150)   // <- move list down
                Spacer()
            }

            // HOME BUTTON
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        router.goHome()
                    } label: {
                        Image("homeButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(forResource: "morningRoutineChecklist", withExtension: "mp4") {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        MorningRoutineChecklistVideoView()
            .environmentObject(AppRouter())
    }
}
