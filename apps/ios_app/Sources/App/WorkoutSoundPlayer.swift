import AVFoundation
import Foundation

@MainActor
final class WorkoutSoundPlayer: NSObject, WorkoutSoundPlaying, AVAudioPlayerDelegate {
    private var activePlayers: [ObjectIdentifier: AVAudioPlayer] = [:]

    func play(_ effect: WorkoutSoundEffect) {
        let bundle = Bundle.main
        guard let url = bundle.url(
            forResource: effect.rawValue,
            withExtension: "wav",
            subdirectory: "Sounds"
        ) ?? bundle.url(
            forResource: effect.rawValue,
            withExtension: "wav"
        ) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            activePlayers[ObjectIdentifier(player)] = player
            player.play()
        } catch {
            return
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let key = ObjectIdentifier(player)
        DispatchQueue.main.async { [weak self] in
            self?.activePlayers.removeValue(forKey: key)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let key = ObjectIdentifier(player)
        DispatchQueue.main.async { [weak self] in
            self?.activePlayers.removeValue(forKey: key)
        }
    }
}
