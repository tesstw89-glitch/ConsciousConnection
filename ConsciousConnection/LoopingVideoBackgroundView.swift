import SwiftUI
import AVFoundation

struct LoopingVideoBackgroundView: UIViewRepresentable {
    let resourceName: String
    let fileExtension: String
    var isMuted: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill

        if let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
            let player = AVQueuePlayer()
            player.isMuted = isMuted

            let item = AVPlayerItem(url: url)
            let looper = AVPlayerLooper(player: player, templateItem: item)

            context.coordinator.player = player
            context.coordinator.looper = looper

            view.playerLayer.player = player
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        context.coordinator.player?.isMuted = isMuted
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        uiView.playerLayer.player = nil
    }

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

struct AssetButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
