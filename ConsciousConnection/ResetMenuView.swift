import SwiftUI
import AVKit

struct ResetMenuView: View {
    @EnvironmentObject private var router: AppRouter

    @State private var player: AVPlayer? = nil
    @State private var showingLimitingBeliefs = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem
                        )
                    ) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // States
                Button {
                    router.path = [.states]
                } label: {
                    Image("reset")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 165)
                }
                .buttonStyle(.plain)
                .position(
                    x: w * 0.50,
                    y: h * 0.16
                )

                // Spiral
                Button {
                    router.path = [.spiral]
                } label: {
                    Image("spiral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 205)
                }
                .buttonStyle(.plain)
                .position(
                    x: w * 0.50,
                    y: h * 0.40
                )

                // Limiting beliefs
                Button {
                    showingLimitingBeliefs = true
                } label: {
                    Image("limitingbeliefs")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 205)
                }
                .buttonStyle(.plain)
                .position(
                    x: w * 0.50,
                    y: h * 0.68
                )
                .accessibilityLabel("Limiting beliefs")
            }
        }
        .fullScreenCover(isPresented: $showingLimitingBeliefs) {
            NavigationStack {
                LimitingBeliefEntryView(
                    onCancel: {
                        showingLimitingBeliefs = false
                    },
                    onContinue: { belief in
                        showingLimitingBeliefs = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            router.path = [.spiralStates(belief)]
                        }
                    }
                )
            }
            .tint(.white)
        }
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(
                    forResource: "breeze",
                    withExtension: "mp4"
               ) {
                let newPlayer = AVPlayer(url: url)
                newPlayer.actionAtItemEnd = .pause
                player = newPlayer
            }
        }
        .onDisappear {
            player = nil
        }
    }
}

#Preview {
    ResetMenuView()
        .environmentObject(AppRouter())
}
