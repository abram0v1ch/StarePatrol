import SwiftUI
import Combine
import UserNotifications

@main
struct StarePatrolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager: TimerManager
    
    var body: some Scene {
        // .window style renders content in a stable floating popover rather than
        // a native NSMenu — this is the only way to prevent SwiftUI from
        // triggering expensive layout passes on every second tick that cause
        // the dropdown to collapse/become unresponsive.
        MenuBarExtra {
            SettingsView()
                .environmentObject(timerManager)
        } label: {
            // Single stable HStack so the frame never changes, preventing jitter
            HStack(spacing: 4) {
                Image(systemName: timerManager.isBreaking ? "eyes.inverse" : timerManager.menuBarIconName)
                Text(timerManager.isBreaking ? "Break!" : timerManager.timeString)
                    .font(.body.monospacedDigit())
            }
            .frame(width: 90, alignment: .leading)
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        // Create the manager first, wire real AppKit implementations, then hand
        // it to SwiftUI. Using _timerManager = StateObject(wrappedValue:) is the
        // only correct pattern — accessing `self.timerManager` in init() reaches
        // a throwaway wrapper, NOT the instance SwiftUI will use for the view.
        let manager = TimerManager()
        manager.onPlaySound    = { name in SoundManager.shared.previewSound(name) }
        manager.onHaptic       = { SoundManager.shared.performHapticFeedback() }
        manager.onShowReminder = { mgr in ReminderWindowManager.shared.showReminder(timerManager: mgr) }
        manager.onHideReminder = { ReminderWindowManager.shared.hideReminder() }
        _timerManager = StateObject(wrappedValue: manager)
        
        // Forward notification-action events (snooze/skip from banners) to the timer
        NotificationCenter.default.addObserver(forName: .notificationActionReceived, object: nil, queue: .main) { notification in
            if let action = notification.userInfo?["action"] as? String {
                if action == "SNOOZE_ACTION" { manager.snoozeBreak(minutes: 5) }
                else if action == "SKIP_ACTION" { manager.skipBreak() }
            }
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // Request alert + sound + banner permissions upfront
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notifications granted: \(granted)")
        }
    }
    
    // CRITICAL: This delegate method forces the notification to display as a
    // visible banner even when the app is the foreground/active process.
    // Without this, macOS silently drops all notifications to Notification Center only.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = ["action": response.actionIdentifier]
        NotificationCenter.default.post(name: .notificationActionReceived, object: nil, userInfo: userInfo)
        completionHandler()
    }
}

extension Notification.Name {
    static let notificationActionReceived = Notification.Name("notificationActionReceived")
}
