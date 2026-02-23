import SwiftUI

// A compact top-right banner that's ALWAYS visible — bypasses macOS Notification Center
// entirely by using a floating NSPanel managed by us.
class BannerWindowManager {
    static let shared = BannerWindowManager()
    
    private var bannerWindow: NSWindow?
    private weak var timerManager: TimerManager?
    
    func show(timerManager: TimerManager) {
        self.timerManager = timerManager
        hide() // dismiss any existing banner first
        
        guard let screen = NSScreen.main else { return }
        let width: CGFloat = 320
        let height: CGFloat = 110
        let margin: CGFloat = 16
        // Position top-right, just below the menu bar
        let menuBarHeight: CGFloat = NSApplication.shared.mainMenu != nil ? 24 : 0
        let x = screen.frame.maxX - width - margin
        let y = screen.frame.maxY - height - margin - menuBarHeight
        
        let panel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        
        let hostingView = NSHostingView(
            rootView: BannerView(timerManager: timerManager)
        )
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        bannerWindow = panel
    }
    
    func hide() {
        bannerWindow?.orderOut(nil)
        bannerWindow = nil
    }
}

// The banner card UI
struct BannerView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: "eyes")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(timerManager.customReminderMessage)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("Look 20ft away · \(timerManager.timeString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                if !timerManager.isStrictMode {
                    HStack(spacing: 10) {
                        Button("Snooze 5m") { timerManager.snoozeBreak(minutes: 5) }
                            .buttonStyle(.plain)
                            .font(.caption.bold())
                            .foregroundColor(.accentColor)
                        Button("Skip") { timerManager.skipBreak() }
                            .buttonStyle(.plain)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .frame(width: 320)
    }
}
