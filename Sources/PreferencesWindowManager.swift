import AppKit
import SwiftUI

class PreferencesWindowManager {
    static let shared = PreferencesWindowManager()
    
    private var preferencesWindow: NSWindow?
    
    func showPreferences(timerManager: TimerManager) {
        if preferencesWindow == nil {
            let panel = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            panel.title = "StarePatrol Preferences"
            panel.center()
            panel.isReleasedWhenClosed = false
            panel.level = .floating
            
            let hostingView = NSHostingView(rootView: PreferencesView(timerManager: timerManager))
            panel.contentView = hostingView
            
            preferencesWindow = panel
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
