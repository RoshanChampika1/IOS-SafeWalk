import AudioToolbox
import Foundation

/// Repeating ring / vibration used when a delayed fake call fires.
final class FakeCallRingtone {
    static let shared = FakeCallRingtone()

    private var timer: Timer?

    private init() {}

    func start() {
        stop()
        playOnce()
        let t = Timer(timeInterval: 2.4, repeats: true) { _ in
            self.playOnce()
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func playOnce() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }
}
