import SwiftUI
import AVKit

struct BreatheVideoView: View {

    // Defaults keep your original morning flow working:
    // breathe.mp4 -> gratitude
    let videoName: String
    let nextRoute: Route

    @State private var player: AVPlayer? = nil

    init(
        videoName: String = "breathe",
        nextRoute: Route = .gratitude
    ) {
        self.videoName = videoName
        self.nextRoute = nextRoute
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            } else {
                Color.black.ignoresSafeArea()

                Text("Loading…")
                    .foregroundColor(.white)
            }

            // NEXT -> configurable route
            NavigationLink(value: nextRoute) {
                Image("nextButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, -18)
        }
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
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
        BreatheVideoView()
    }
}
