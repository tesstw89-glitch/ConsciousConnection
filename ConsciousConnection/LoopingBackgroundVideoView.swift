import SwiftUI
import AVFoundation

struct LoopingBackgroundVideoView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> LoopingPlayerView {
        let view = LoopingPlayerView()
        view.configure(with: fileName)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) { }
}

final class LoopingPlayerView: UIView {
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    func configure(with rawName: String) {
        guard let url = Self.findVideoURL(for: rawName) else { return }

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.actionAtItemEnd = .none

        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        player.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    private static func findVideoURL(for rawName: String) -> URL? {
        let nsName = rawName as NSString
        let givenExtension = nsName.pathExtension
        let baseName = nsName.deletingPathExtension

        if !baseName.isEmpty,
           !givenExtension.isEmpty,
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
