import SwiftUI
import Combine
import UserNotifications

@main
struct StarePatrolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager()
    
    // We use a MenuBarExtra to make it a status bar app
    // In macOS 13+, MenuBarExtra is the modern way to do this in SwiftUI
    var body: some Scene {
        MenuBarExtra {
            SettingsView()
                .environmentObject(timerManager)
        } label: {
            if timerManager.isBreaking {
                Image(systemName: "eyes.inverse")
                    .foregroundColor(.yellow)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: timerManager.menuBarIconName)
                    Text(timerManager.timeString)
                        .font(.body.monospacedDigit())
                }
                .frame(width: 80, alignment: .leading)
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        // Safe way to observe even when UI is not rendering
        NotificationCenter.default.addObserver(forName: .showReminder, object: nil, queue: .main) { _ in
            SoundManager.shared.triggerFeedback()
            // Assume we need access to TimerManager, we can pass a reference or just use a singleton.
            // Since we have an instance here, we will handle it inside the closure.
        }
        NotificationCenter.default.addObserver(forName: .hideReminder, object: nil, queue: .main) { _ in
            ReminderWindowManager.shared.hideReminder()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Force the notification to show as a banner even if the app is active
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = ["action": response.actionIdentifier]
        NotificationCenter.default.post(name: .notificationActionReceived, object: nil, userInfo: userInfo)
        
        completionHandler()
    }
}

extension Notification.Name {
    static let notificationActionReceived = Notification.Name("notificationActionReceived")
}
