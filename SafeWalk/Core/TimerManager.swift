import Foundation
import Combine

class TimerManager: ObservableObject {
    
    @Published var secondsRemaining: Int = 300  // Default 5 minutes
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
    
    func start(seconds: Int) {
        self.totalSeconds = seconds
        self.secondsRemaining = seconds
        self.didExpire = false
        self.isRunning = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.expire()
            }
        }
    }
    
    func pause() {
        timer?.invalidate()
        isRunning = false
    }
    
    func resume() {
        guard !didExpire else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.expire()
            }
        }
    }
    
    func addTime(seconds: Int) {
        secondsRemaining = min(secondsRemaining + seconds, totalSeconds * 2)
    }
    
    func invalidate() {
        timer?.invalidate()
        isRunning = false
        didExpire = false
    }
    
    private func expire() {
        timer?.invalidate()
        isRunning = false
        didExpire = true
        DispatchQueue.main.async {
            self.onExpire?()
        }
    }
}
