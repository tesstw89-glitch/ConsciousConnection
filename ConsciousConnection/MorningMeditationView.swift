import SwiftUI
import AVFoundation

struct MorningMeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = MeditationAudioController(
        fileName: "Morning_Meditation",
        fileExtension: "mp3"
    )

    @State private var isScrubbing = false

    private let backX: CGFloat = 0.86
    private let backY: CGFloat = 0.90
    private let backWidth: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LoopingVideoBackgroundView(
                    resourceName: "Morning_Meditation",
                    fileExtension: "mp4",
                    isMuted: true
                )
                .ignoresSafeArea()

                Color.black.opacity(0.12)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    audioControls
                        .frame(width: min(geo.size.width * 0.76, 430))
                        .padding(.bottom, 230)

                    Spacer()
                }

                Button {
                    audio.pause()
                    dismiss()
                } label: {
                    Image("back_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: backWidth)
                }
                .buttonStyle(AssetButtonPressStyle())
                .position(
                    x: geo.size.width * backX,
                    y: geo.size.height * backY
                )
            }
            .onDisappear {
                audio.pause()
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private var audioControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    audio.toggle()
                } label: {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning Meditation")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(format(audio.currentTime)) / \(format(audio.duration))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                }

                Spacer()
            }

            Slider(
                value: Binding(
                    get: {
                        isScrubbing ? audio.scrubTime : audio.currentTime
                    },
                    set: { newValue in
                        audio.scrubTime = newValue
                    }
                ),
                in: 0...max(audio.duration, 1),
                onEditingChanged: { editing in
                    isScrubbing = editing
                    if editing {
                        audio.scrubTime = audio.currentTime
                    } else {
                        audio.seek(to: audio.scrubTime)
                    }
                }
            )
            .tint(.white)
        }
        .padding(18)
        .background(Color.black.opacity(0.32))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func format(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

final class MeditationAudioController: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var scrubTime: Double = 0

    private var player: AVPlayer?
    private var timeObserver: Any?

    init(fileName: String, fileExtension: String) {
        load(fileName: fileName, fileExtension: fileExtension)
    }

    deinit {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func seek(to seconds: Double) {
        let safe = max(0, min(seconds, duration))
        let time = CMTime(seconds: safe, preferredTimescale: 600)
        player?.seek(to: time)
        currentTime = safe
        scrubTime = safe
    }

    private func load(fileName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else { return }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        let assetDuration = asset.duration.seconds
        if assetDuration.isFinite && assetDuration > 0 {
            duration = assetDuration
        }

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }

            let seconds = max(0, time.seconds)
            self.currentTime = seconds

            if let itemDuration = self.player?.currentItem?.duration.seconds,
               itemDuration.isFinite,
               itemDuration > 0 {
                self.duration = itemDuration
            }

            if self.duration > 0, seconds >= self.duration - 0.1 {
                self.isPlaying = false
            }
        }
    }
}
