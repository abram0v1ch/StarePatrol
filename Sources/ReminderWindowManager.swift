import AppKit
import SwiftUI

class ReminderWindowManager {
    static let shared = ReminderWindowManager()
    
    private var reminderWindow: NSWindow?
    
    func showReminder(timerManager: TimerManager) {
        if reminderWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            
            // Make the window transparent and float above everything
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.center()
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            
            let hostingView = NSHostingView(rootView: ReminderView(timerManager: timerManager))
            panel.contentView = hostingView
            
            reminderWindow = panel
        }
        
        // Show window without stealing keyboard focus
        reminderWindow?.orderFrontRegardless()
    }
    
    func hideReminder() {
        reminderWindow?.orderOut(nil)
        reminderWindow = nil
    }
}
