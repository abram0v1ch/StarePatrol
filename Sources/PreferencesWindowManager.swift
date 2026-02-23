import AppKit
import SwiftUI

class PreferencesWindowManager {
    static let shared = PreferencesWindowManager()
    private var preferencesWindow: NSWindow?

    func showPreferences(timerManager: TimerManager) {
        if preferencesWindow == nil {
            // Fixed size — largest section (Notifications) fits at ~500px height.
            // No dynamic resize = zero jitter when switching sections.
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "StarePatrol Preferences"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PreferencesView(timerManager: timerManager))
            preferencesWindow = window
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
