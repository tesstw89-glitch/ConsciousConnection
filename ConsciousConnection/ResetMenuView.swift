import SwiftUI
import AVKit

struct ResetMenuView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
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
                Color.black.ignoresSafeArea()
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Button {
                    router.path = [.states]   // ✅ go straight to States from Reset menu
                } label: {
                    Image("reset")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                }
                .buttonStyle(.plain)
                .position(x: w * 0.50, y: h * 0.30)

                Button {
                    router.path = [.spiral]   // ✅ go straight to Spiral
                } label: {
                    Image("spiral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220)
                }
                .buttonStyle(.plain)
                .position(x: w * 0.50, y: h * 0.62)
            }
        }
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(forResource: "breeze", withExtension: "mp4") {
                let p = AVPlayer(url: url)
                p.actionAtItemEnd = .pause
                player = p
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
