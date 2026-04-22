import Combine
import Foundation

class TimerManager: ObservableObject {

    @Published var secondsRemaining: Int = 300
    @Published var isRunning: Bool = false
    @Published var didExpire: Bool = false
    @Published var totalSeconds: Int = 300

    private var timer: Timer?
    var onExpire: (() -> Void)?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(secondsRemaining) / Double(totalSeconds)
    }

    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTimeHMS: String {
        let h = secondsRemaining / 3600
        let m = (secondsRemaining % 3600) / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Updates the ring while idle (before Start) when the user picks a new duration.
    func setIdleCountdown(seconds: Int) {
        guard !isRunning else { return }
        let s = max(1, seconds)
        totalSeconds = s
        secondsRemaining = s
        didExpire = false
    }

    func start(seconds: Int) {
        let s = max(1, seconds)
        totalSeconds = s
        secondsRemaining = s
        didExpire = false
        isRunning = true

        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.expire()
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard !didExpire else { return }
        isRunning = true
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.expire()
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func addTime(seconds: Int) {
        secondsRemaining = min(secondsRemaining + seconds, totalSeconds * 2)
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        didExpire = false
    }

    private func expire() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        didExpire = true
        DispatchQueue.main.async {
            self.onExpire?()
        }
    }
}
