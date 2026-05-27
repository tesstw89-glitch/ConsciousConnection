import SwiftUI
import AVKit

struct ExerciseVideoPlayerView: View {
    @StateObject private var holder: LocalVideoPlayerHolder

    init(fileName: String) {
        _holder = StateObject(wrappedValue: LocalVideoPlayerHolder(fileName: fileName))
    }

    var body: some View {
        Group {
            if let player = holder.player {
                VideoPlayer(player: player)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onAppear { holder.play() }
                    .onDisappear { holder.pause() }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.22))
                        .frame(height: 160)

                    Text("Video not found")
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
    }
}

final class LocalVideoPlayerHolder: ObservableObject {
    @Published var player: AVPlayer?

    private var endObserver: NSObjectProtocol?

    init(fileName: String) {
        guard let url = Self.findVideoURL(for: fileName) else { return }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        self.player = player

        if let item = player.currentItem {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    private static func findVideoURL(for rawName: String) -> URL? {
        let nsName = rawName as NSString
        let givenExtension = nsName.pathExtension
        let baseName = nsName.deletingPathExtension

        if !baseName.isEmpty, !givenExtension.isEmpty,
           let url = Bundle.main.url(forResource: baseName, withExtension: givenExtension) {
            return url
        }

        if let url = Bundle.main.url(forResource: rawName, withExtension: nil) {
            return url
        }

        let candidates = [rawName, baseName].filter { !$0.isEmpty }
        let extensions = ["mp4", "mov", "m4v"]

        for candidate in candidates {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: candidate, withExtension: ext) {
                    return url
                }
            }
        }

        return nil
    }
}
