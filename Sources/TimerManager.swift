import Foundation
import Combine
import SwiftUI
import UserNotifications
import SwiftUI

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isBreaking: Bool = false
    @Published var isPaused: Bool = false
    
    // UserDefaults via AppStorage
    @AppStorage("workIntervalMinutes") var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") var breakIntervalSeconds: Int = 20
    @AppStorage("isAppEnabled") var isAppEnabled: Bool = true
    @AppStorage("useFullScreenPopup") var useFullScreenPopup: Bool = true
    
    // Statistics
    @AppStorage("totalBreaksTaken") var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") var totalBreaksSkipped: Int = 0
    
    // Customization
    @AppStorage("customReminderMessage") var customReminderMessage: String = "Time to rest your eyes! Look 20 feet away."
    @AppStorage("menuBarIconName") var menuBarIconName: String = "eyes"
    @AppStorage("isStrictMode") var isStrictMode: Bool = false
    
    var workInterval: TimeInterval { TimeInterval(workIntervalMinutes * 60) }
    var breakInterval: TimeInterval { TimeInterval(breakIntervalSeconds) }
    
    private var timer: AnyCancellable?
    
    init() {
        // Safe defaults configuration
        UserDefaults.standard.register(defaults: [
            "workIntervalMinutes": 20,
            "breakIntervalSeconds": 20,
            "isAppEnabled": true,
            "useFullScreenPopup": true
        ])
        
        let initialWorkInterval = TimeInterval(UserDefaults.standard.integer(forKey: "workIntervalMinutes") > 0 ? UserDefaults.standard.integer(forKey: "workIntervalMinutes") * 60 : 1200)
        self.timeRemaining = initialWorkInterval // Start with full work interval
        
        if isAppEnabled {
            startTimer()
        }
        
        // Listen for notification actions even when UI is closed
        NotificationCenter.default.addObserver(forName: .notificationActionReceived, object: nil, queue: .main) { [weak self] notification in
            if let action = notification.userInfo?["action"] as? String {
                if action == "SNOOZE_ACTION" {
                    self?.snoozeBreak(minutes: 5)
                } else if action == "SKIP_ACTION" {
                    self?.skipBreak()
                }
            }
        }
    }
    
    func settingsUpdated() {
        if isAppEnabled {
            resetTimer()
        } else {
            pauseTimer()
            ReminderWindowManager.shared.hideReminder()
        }
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
    
    func skipBreak() {
        if isBreaking {
            totalBreaksSkipped += 1
            isBreaking = false
            ReminderWindowManager.shared.hideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
            resetTimer()
        }
    }
    
    func completeBreak() {
        if isBreaking {
            totalBreaksTaken += 1
            isBreaking = false
            ReminderWindowManager.shared.hideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
            resetTimer()
        }
    }
    
    func pauseApp(minutes: Int) {
        isBreaking = false
        isPaused = true
        timeRemaining = TimeInterval(minutes * 60)
        ReminderWindowManager.shared.hideReminder()
        NotificationCenter.default.post(name: .hideReminder, object: nil)
        startTimer()
    }
    
    func resumeTimer() {
        isPaused = false
        resetTimer()
    }
    
    func snoozeBreak(minutes: Int = 5) {
        guard !isStrictMode else { return }
        if isBreaking {
            isBreaking = false
            isPaused = true
            timeRemaining = TimeInterval(minutes * 60)
            ReminderWindowManager.shared.hideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
            startTimer()
        }
    }
    
    func triggerDebugBreak() {
        if !isBreaking {
            isBreaking = true
            timeRemaining = breakInterval
            showReminderIfNeeded()
        }
    }
    
    private func tick() {
        guard isAppEnabled else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            if isPaused {
                isPaused = false
                resetTimer()
            } else {
                // Switch state
                isBreaking.toggle()
                timeRemaining = isBreaking ? breakInterval : workInterval
                showReminderIfNeeded()
            }
        }
    }
    
    // Format for menu bar display
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func showReminderIfNeeded() {
        if isBreaking {
            if useFullScreenPopup {
                ReminderWindowManager.shared.showReminder(timerManager: self)
            } else {
                sendLocalNotification()
            }
            NotificationCenter.default.post(name: .showReminder, object: nil)
        } else {
            ReminderWindowManager.shared.hideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
        }
    }
    
    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "StarePatrol"
        content.body = customReminderMessage
        content.categoryIdentifier = "BREAK_REMINDER"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        let center = UNUserNotificationCenter.current()
        let category: UNNotificationCategory
        
        if isStrictMode {
            category = UNNotificationCategory(identifier: "BREAK_REMINDER", actions: [], intentIdentifiers: [], options: [])
        } else {
            let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 5 Min", options: [])
            let skipAction = UNNotificationAction(identifier: "SKIP_ACTION", title: "Skip", options: [])
            category = UNNotificationCategory(identifier: "BREAK_REMINDER", actions: [snoozeAction, skipAction], intentIdentifiers: [], options: [])
        }
        
        center.setNotificationCategories([category])
        
        center.requestAuthorization(options: [.alert]) { granted, _ in
            if granted {
                center.add(request)
            }
        }
    }
}

extension Notification.Name {
    static let showReminder = Notification.Name("showReminder")
    static let hideReminder = Notification.Name("hideReminder")
}
