import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var pauseMinutes: Double = 15
    
    // Format duration as "1h 30m", "45m", etc.
    private func pauseLabel(_ minutes: Double) -> String {
        let m = Int(minutes)
        if m >= 60 {
            let h = m / 60
            let rem = m % 60
            return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
        }
        return "\(m)m"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: timerManager.isBreaking ? "eyes.inverse" : timerManager.menuBarIconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(timerManager.isBreaking ? .orange : .accentColor)
                Text("StarePatrol")
                    .font(.headline)
                Spacer()
                // Status pill
                Group {
                    if timerManager.isBreaking {
                        Text("BREAK")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    } else if timerManager.isPaused {
                        Text("PAUSED")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.yellow)
                            .clipShape(Capsule())
                    } else {
                        Text("ACTIVE")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // ── Countdown ───────────────────────────────────────────
            VStack(spacing: 4) {
                if timerManager.isBreaking {
                    Label("Rest your eyes — look 20ft away", systemImage: "eye")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                } else if timerManager.isPaused {
                    Label("Resumes in \(timerManager.timeString)", systemImage: "pause.circle")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Text("Next break in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(timerManager.timeString)
                            .font(.subheadline.bold().monospacedDigit())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            
            Divider()
            
            // ── Pause controls ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pause for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(pauseLabel(pauseMinutes))
                        .font(.caption.bold().monospacedDigit())
                        .frame(width: 48, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    Slider(value: $pauseMinutes, in: 1...120, step: 1)
                    if timerManager.isPaused {
                        Button("Resume") { timerManager.resumeTimer() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    } else {
                        Button("Pause") { timerManager.pauseApp(minutes: Int(pauseMinutes)) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // ── Actions ─────────────────────────────────────────────
            VStack(spacing: 2) {
                menuButton(label: "Preferences…", icon: "gearshape") {
                    PreferencesWindowManager.shared.showPreferences(timerManager: timerManager)
                }
                menuButton(label: "Reset Timer", icon: "arrow.counterclockwise") {
                    timerManager.resetTimer()
                }
                menuButton(label: "Quit StarePatrol", icon: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }
    
    @ViewBuilder
    private func menuButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}
