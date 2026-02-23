import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isBreaking: Bool = false
    
    // Default 20 minutes (1200 seconds) for work, 20 seconds for break
    let workInterval: TimeInterval = 1200
    let breakInterval: TimeInterval = 20
    
    private var timer: AnyCancellable?
    
    init() {
        self.timeRemaining = 1200 // Start with full work interval
        startTimer()
    }
    
    func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pauseTimer() {
        timer?.cancel()
        timer = nil
    }
    
    func resetTimer() {
        timeRemaining = isBreaking ? breakInterval : workInterval
        startTimer()
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Switch state
            isBreaking.toggle()
            timeRemaining = isBreaking ? breakInterval : workInterval
            
            // Notify when state changes (e.g. show popup)
            showReminderIfNeeded()
        }
    }
    
    // Format for menu bar display
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%d", seconds)
        }
    }
    
    private func showReminderIfNeeded() {
        if isBreaking {
            ReminderWindowManager.shared.showReminder(timerManager: self)
            NotificationCenter.default.post(name: .showReminder, object: nil)
        } else {
            ReminderWindowManager.shared.hideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
        }
    }
}

extension Notification.Name {
    static let showReminder = Notification.Name("showReminder")
    static let hideReminder = Notification.Name("hideReminder")
}
