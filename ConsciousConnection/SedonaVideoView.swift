import SwiftUI
import AVKit

struct SedonaVideoView: View {

    @EnvironmentObject private var router: AppRouter

    @State private var player: AVPlayer?
    @State private var finished = false

    @State private var endObserver: Any?   // ✅ keep token

    var body: some View {
        ZStack(alignment: .bottom) {

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                Text("Loading…")
                    .foregroundColor(.white)
            }

            if finished {
                Button {
                    router.goHome()
                } label: {
                    Image("homeButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            finished = false

            guard let url = Bundle.main.url(forResource: "sedona", withExtension: "mp4") else {
                print("Sedona video not found")
                return
            }

            let p = AVPlayer(url: url)
            player = p

            // ✅ Remove any previous observer just in case
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }

            // ✅ Store observer token so we can remove it
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                finished = true
            }

            p.play()
        }
        .onDisappear {
            // ✅ Clean up observer safely
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }

            player?.pause()
            player = nil
        }
    }
}
