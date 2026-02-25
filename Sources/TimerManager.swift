import Foundation
import Combine
import SwiftUI
import UserNotifications

// MARK: - Side-effect hooks (injectable for testing)

/// Called when a sound should play. Receives the sound name.
typealias PlaySoundAction   = (_ name: String) -> Void
/// Called when haptic feedback should fire.
typealias HapticAction      = () -> Void
/// Called to show the break reminder to the user.
typealias ShowReminderAction = (_ manager: TimerManager) -> Void
/// Called to hide the break reminder.
typealias HideReminderAction = () -> Void

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var isBreaking: Bool = false
    @Published var isPaused: Bool = false
    
    // UserDefaults via AppStorage
    @AppStorage("workIntervalMinutes") var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") var breakIntervalSeconds: Int = 20
    @AppStorage("isAppEnabled") var isAppEnabled: Bool = true
    @AppStorage("notificationMode") var notificationMode: String = "fullscreen"
    
    // Statistics
    @AppStorage("totalBreaksTaken") var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") var totalBreaksSkipped: Int = 0
    
    // Customization
    @AppStorage("customReminderMessage") var customReminderMessage: String = "Rest your eyes — look 20ft away."
    @AppStorage("menuBarIconName") var menuBarIconName: String = "eyes"
    @AppStorage("isStrictMode") var isStrictMode: Bool = false
    @AppStorage("isSoundEnabled") var isSoundEnabled: Bool = true
    @AppStorage("isWorkEndSoundEnabled") var isWorkEndSoundEnabled: Bool = false
    @AppStorage("selectedSoundName") var selectedSoundName: String = "Glass"
    
    var workInterval: TimeInterval { TimeInterval(workIntervalMinutes * 60) }
    var breakInterval: TimeInterval { TimeInterval(breakIntervalSeconds) }
    
    private var timer: AnyCancellable?
    
    // Injectable side-effects — set by app at launch, no-ops for tests
    var onPlaySound:    PlaySoundAction    = { _ in }
    var onHaptic:       HapticAction       = { }
    var onShowReminder: ShowReminderAction = { _ in }
    var onHideReminder: HideReminderAction = { }
    
    init() {
        // Safe defaults configuration
        UserDefaults.standard.register(defaults: [
            "workIntervalMinutes": 20,
            "breakIntervalSeconds": 20,
            "isAppEnabled": true,
            "notificationMode": "fullscreen",
            // Sound / haptic defaults — also registered by SoundManager, but
            // TimerManager's tick() gates on these keys so they must be seeded here
            // too in case SoundManager.shared hasn't been initialized yet.
            "isSoundEnabled": true,
            "breakStartSoundEnabled": true,
            "breakEndSoundEnabled": true,
            "isHapticsEnabled": true,
            "selectedSoundName": "Glass"
        ])
        
        let initialWorkInterval = TimeInterval(UserDefaults.standard.integer(forKey: "workIntervalMinutes") > 0 ? UserDefaults.standard.integer(forKey: "workIntervalMinutes") * 60 : 1200)
        self.timeRemaining = initialWorkInterval // Start with full work interval
        
        // Default sound/haptic closures call SoundManager directly.
        // These are set HERE (not in StarePatrolApp) because SwiftUI re-invokes
        // App.init() on every re-render and discards all but the first TimerManager
        // instance — any closures set in App.init() are lost on subsequent calls.
        onPlaySound = { name in SoundManager.shared.previewSound(name) }
        onHaptic    = { SoundManager.shared.performHapticFeedback() }
        
        if isAppEnabled {
            startTimer()
        }
    }
    
    func settingsUpdated() {
        if isAppEnabled {
            resetTimer()
        } else {
            pauseTimer()
            onHideReminder()
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
    
    var isTimerRunning: Bool { timer != nil }
    
    func pauseTimer() {
        timer?.cancel()
        timer = nil
    }
    
    func resetTimer() {
        isPaused = false
        isBreaking = false
        timeRemaining = workInterval
        startTimer()
    }
    
    func skipBreak() {
        if isBreaking {
            totalBreaksSkipped += 1
            isBreaking = false
            executeBreakEndSideEffects()
            resetTimer()
        }
    }
    
    func completeBreak() {
        if isBreaking {
            totalBreaksTaken += 1
            isBreaking = false
            executeBreakEndSideEffects()
            resetTimer()
        }
    }
    
    private func executeBreakStartSideEffects() {
        if UserDefaults.standard.bool(forKey: "breakStartSoundEnabled") {
            let snd = UserDefaults.standard.string(forKey: "selectedSoundName") ?? "Glass"
            onPlaySound(snd)
        }
        onHaptic()
        showReminderIfNeeded()
    }
    
    private func executeBreakEndSideEffects() {
        if UserDefaults.standard.bool(forKey: "breakEndSoundEnabled") {
            let snd = UserDefaults.standard.string(forKey: "selectedSoundName") ?? "Glass"
            onPlaySound(snd)
        }
        onHaptic()
        onHideReminder()
        NotificationCenter.default.post(name: .hideReminder, object: nil)
    }
    
    func pauseApp(minutes: Int) {
        isBreaking = false
        isPaused = true
        timeRemaining = TimeInterval(minutes * 60)
        onHideReminder()
        NotificationCenter.default.post(name: .hideReminder, object: nil)
        startTimer()
    }
    
    func pauseIndefinitely() {
        isBreaking = false
        isPaused = true
        pauseTimer()
        onHideReminder()
        NotificationCenter.default.post(name: .hideReminder, object: nil)
    }
    
    private var wasAutoPausedForSleep = false
    
    func handleSystemSleep() {
        if !isPaused {
            wasAutoPausedForSleep = true
            isPaused = true
            pauseTimer()
            onHideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
        }
    }
    
    func handleSystemWake() {
        if wasAutoPausedForSleep {
            wasAutoPausedForSleep = false
            isPaused = false
            startTimer()
        }
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
            onHideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
            startTimer()
        }
    }
    
    func triggerDebugBreak() {
        if !isBreaking {
            isBreaking = true
            timeRemaining = breakInterval
            executeBreakStartSideEffects()
        }
    }
    
    func tick() {
        guard isAppEnabled else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            if isPaused {
                isPaused = false
                resetTimer()
            } else {
                let wasBreaking = isBreaking
                isBreaking.toggle()
                timeRemaining = isBreaking ? breakInterval : workInterval
                
                if isBreaking && !wasBreaking {
                    // work → break
                    executeBreakStartSideEffects()
                } else if !isBreaking && wasBreaking {
                    // break → work
                    totalBreaksTaken += 1
                    executeBreakEndSideEffects()
                }
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
            switch notificationMode {
            case "fullscreen":
                onShowReminder(self)
            case "notification":
                sendLocalNotification()
            default:
                break
            }
            NotificationCenter.default.post(name: .showReminder, object: nil)
        } else {
            onHideReminder()
            NotificationCenter.default.post(name: .hideReminder, object: nil)
        }
    }
    
    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "StarePatrol"
        content.body = customReminderMessage
        content.sound = .default
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
        // Just add the notification — auth was already requested at app launch
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let showReminder = Notification.Name("showReminder")
    static let hideReminder = Notification.Name("hideReminder")
}
