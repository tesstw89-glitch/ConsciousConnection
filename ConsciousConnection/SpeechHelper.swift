import Foundation
import AVFoundation

@MainActor
final class SpeechHelper: ObservableObject {

    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.48
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }
}
