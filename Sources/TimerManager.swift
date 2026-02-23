import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isBreaking: Bool = false
    
    // UserDefaults via AppStorage
    @AppStorage("workIntervalMinutes") var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") var breakIntervalSeconds: Int = 20
    
    var workInterval: TimeInterval { TimeInterval(workIntervalMinutes * 60) }
    var breakInterval: TimeInterval { TimeInterval(breakIntervalSeconds) }
    
    private var timer: AnyCancellable?
    
    init() {
        // We can't immediately use self.workInterval before initialization in swift strict concurrency sometimes,
        // but here it's safe after super.init, or we just pull from UserDefaults directly.
        let initialWorkInterval = TimeInterval(UserDefaults.standard.integer(forKey: "workIntervalMinutes") > 0 ? UserDefaults.standard.integer(forKey: "workIntervalMinutes") * 60 : 1200)
        self.timeRemaining = initialWorkInterval // Start with full work interval
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
