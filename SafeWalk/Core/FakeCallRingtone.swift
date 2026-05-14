import AVFoundation
import AudioToolbox
import Foundation

/// Repeating ring / vibration used when a delayed fake call fires.
final class FakeCallRingtone {
    static let shared = FakeCallRingtone()

    private var audioPlayer: AVAudioPlayer?
    private var vibrationTimer: Timer?

    private init() {}

    func start() {
        stop()
        
        // 1. Play the authentic Apple Opening ringtone looping indefinitely
        if let url = Bundle.main.url(forResource: "Opening", withExtension: "m4a") {
            do {
                // Ensure audio plays even if the device is on silent (if appropriate for emergency,
                // but usually ringtones play on silent if it's an alarm. For a fake call, standard playback is fine)
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("FakeCallRingtone failed to play audio: \(error)")
            }
        }

        // 2. Play vibration every 2.4 seconds to mimic a real call
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        let t = Timer(timeInterval: 2.4, repeats: true) { _ in
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        vibrationTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
}
