import SwiftUI
import Combine

@main
struct StarePoliceApp: App {
    @StateObject private var timerManager = TimerManager()
    
    // We use a MenuBarExtra to make it a status bar app
    // In macOS 13+, MenuBarExtra is the modern way to do this in SwiftUI
    var body: some Scene {
        MenuBarExtra {
            SettingsView()
                .environmentObject(timerManager)
        } label: {
            // Dynamic labeling based on time remaining or state
            if timerManager.isBreaking {
                Image(systemName: "eyes.inverse")
                    .foregroundColor(.yellow)
            } else {
                HStack {
                    Image(systemName: "eyes")
                    Text(timerManager.timeString)
                        .font(.body.monospacedDigit())
                }
            }
        }
        // MenuBarExtra itself cannot easily hold onReceive that runs when menu is closed in some older macOS,
        // but since we are targeting macOS 14+, it works if attached to an always-alive object.
        // Even safer: we can just attach it to the timerManager init, but keeping it here is SwiftUI-native.
        // Actually, we'll just handle it directly from TimerManager to be safe even when menu is closed.
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
