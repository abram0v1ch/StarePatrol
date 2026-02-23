import SwiftUI
import AppKit

// ── BannerWindowManager ────────────────────────────────────────────────────
// Always-visible floating notification that bypasses macOS Notification Center.

class BannerWindowManager {
    static let shared = BannerWindowManager()
    private var bannerWindow: NSWindow?

    func show(timerManager: TimerManager) {
        hide()
        guard let screen = NSScreen.main else { return }

        let width: CGFloat = 340
        let height: CGFloat = 96
        let margin: CGFloat = 16
        let menuBarApprox: CGFloat = 28

        let x = screen.frame.maxX - width - margin
        let y = screen.frame.maxY - height - margin - menuBarApprox

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

        let view = NSHostingView(rootView: BannerView(timerManager: timerManager))
        panel.contentView = view
        panel.orderFrontRegardless()
        bannerWindow = panel
    }

    func hide() {
        bannerWindow?.orderOut(nil)
        bannerWindow = nil
    }
}

// ── BannerView ─────────────────────────────────────────────────────────────

struct BannerView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        HStack(spacing: 0) {
            // Accent stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor)
                .frame(width: 4)
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                // Icon bubble
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "eyes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(timerManager.customReminderMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Label(timerManager.timeString, systemImage: "timer")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundColor(.secondary)

                    if !timerManager.isStrictMode {
                        HStack(spacing: 12) {
                            Button("Snooze 5m") { timerManager.snoozeBreak(minutes: 5) }
                            Button("Skip") { timerManager.skipBreak() }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.accentColor)
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        .frame(width: 340, height: 96)
    }
}
