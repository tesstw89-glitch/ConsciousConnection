import SwiftUI
import AVKit
import AVFoundation

struct NightRoutineVideoView: View {

    @EnvironmentObject private var router: AppRouter
    @Environment(\.openURL) private var openURL

    let videoName: String
    let nextRoute: Route?

    @State private var player: AVPlayer? = nil
    @State private var hasStartedPlayback = false

    private var shouldShowChecklist: Bool {
        videoName == "NightVideo2"
    }

    private var shouldShowJournalButton: Bool {
        videoName == "NightVideo1"
    }

    private var shouldShowCenteredPlayButton: Bool {
        videoName == "NightVideo3" && !hasStartedPlayback
    }

    private var shouldAutoplay: Bool {
        videoName != "NightVideo3"
    }

    private var nightItems: [String] {
        let weekday = Calendar.current.component(.weekday, from: Date())

        switch weekday {
        case 1, 5:
            return [
                "Pack workbag",
                "Put out work clothes",
                "Clean kitchen & Wash dishes",
                "Clear Toys",
                "Night Skincare & Teeth"
            ]
        default:
            return [
                "Clean kitchen & Wash dishes",
                "Clear Toys",
                "Night Skincare & Teeth"
            ]
        }
    }

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        configureAudioSession()
                        player.isMuted = false
                        player.seek(to: .zero)

                        if shouldAutoplay {
                            player.play()
                            hasStartedPlayback = true
                        } else {
                            player.pause()
                            hasStartedPlayback = false
                        }
                    }
            } else {
                Color.black.ignoresSafeArea()
                Text("Loading…")
                    .foregroundColor(.white)
            }

            // APPLE JOURNAL BUTTON - ONLY ON NIGHTVIDEO1
            if shouldShowJournalButton {
                VStack {
                    Button {
                        if let url = URL(string: "moments://") {
                            openURL(url)
                        }
                    } label: {
                        Image("Apple_Journal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 40)

                    Spacer()
                }
            }

            if shouldShowChecklist {
                VStack {
                    Spacer()

                    HStack {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(nightItems, id: \.self) { item in
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
                    .offset(y: 150)

                    Spacer()
                }
            }

            if shouldShowCenteredPlayButton {
                Button {
                    configureAudioSession()
                    player?.isMuted = false
                    player?.play()
                    hasStartedPlayback = true
                } label: {
                    Image("playButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)
                }
                .buttonStyle(.plain)
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    if let nextRoute {
                        NavigationLink(value: nextRoute) {
                            Image("nextButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, 690)
                    } else {
                        Button {
                            router.goHome()
                        } label: {
                            Image("homeButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 95)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            if player == nil,
               let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                configureAudioSession()

                let newPlayer = AVPlayer(url: url)
                newPlayer.isMuted = false
                player = newPlayer

                if shouldAutoplay {
                    newPlayer.play()
                    hasStartedPlayback = true
                } else {
                    newPlayer.pause()
                    hasStartedPlayback = false
                }
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
            hasStartedPlayback = false
        }
        .navigationBarBackButtonHidden(true)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        NightRoutineVideoView(videoName: "NightVideo1", nextRoute: .nightVideo2)
            .environmentObject(AppRouter())
    }
}
