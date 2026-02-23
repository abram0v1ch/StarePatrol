import SwiftUI

// Preset snap values for the pause slider (minutes); 9999 = indefinite
let pauseSnapValues: [Double] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120, 9999]

func snapPause(_ raw: Double) -> Double {
    pauseSnapValues.min(by: { abs($0 - raw) < abs($1 - raw) }) ?? raw
}

func formatPause(_ minutes: Double) -> String {
    if minutes >= 9999 { return "∞" }
    let m = Int(minutes)
    if m >= 60 {
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }
    return "\(m)m"
}

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var pauseMinutes: Double = 15

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ───────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: timerManager.isBreaking
                      ? "eyes.inverse"
                      : timerManager.menuBarIconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(timerManager.isBreaking ? .orange : .accentColor)
                Text("StarePatrol")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                statusPill
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider()

            // ── Countdown ────────────────────────────────────────────
            HStack {
                Group {
                    if timerManager.isBreaking {
                        Label("Rest your eyes – look 20ft away", systemImage: "eye")
                            .foregroundColor(.orange)
                    } else if timerManager.isPaused {
                        let label = timerManager.isTimerRunning
                            ? "Resumes in \(timerManager.timeString)"
                            : "Paused indefinitely"
                        Label(label, systemImage: "pause.circle")
                            .foregroundColor(.secondary)
                    } else {
                        Label("Next break in \(timerManager.timeString)", systemImage: "timer")
                            .foregroundColor(.primary)
                    }
                }
                .font(.system(size: 12).monospacedDigit())
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)

            Divider()

            // ── Pause ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pause for")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatPause(pauseMinutes))
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    // Snapping slider
                    Slider(
                        value: Binding(
                            get: { pauseMinutes },
                            set: { pauseMinutes = snapPause($0) }
                        ),
                        in: pauseSnapValues.first!...pauseSnapValues.last!
                    )
                    if timerManager.isPaused {
                        Button("Resume") { timerManager.resumeTimer() }
                            .buttonStyle(.bordered).controlSize(.small)
                    } else {
                        Button("Pause") {
                            if pauseMinutes >= 9999 {
                                timerManager.pauseIndefinitely()
                            } else {
                                timerManager.pauseApp(minutes: Int(pauseMinutes))
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)

            Divider()

            // ── Menu Buttons ─────────────────────────────────────────
            VStack(spacing: 0) {
                menuRow("Preferences…", icon: "gearshape") {
                    PreferencesWindowManager.shared.showPreferences(timerManager: timerManager)
                }
                menuRow("Reset Timer", icon: "arrow.counterclockwise") {
                    timerManager.resetTimer()
                }
                menuRow("Quit StarePatrol", icon: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }

    @ViewBuilder private var statusPill: some View {
        let (label, bg, fg): (String, Color, Color) = timerManager.isBreaking
            ? ("BREAK", .orange.opacity(0.15), .orange)
            : timerManager.isPaused
                ? ("PAUSED", .yellow.opacity(0.15), .yellow)
                : ("ACTIVE", .green.opacity(0.12), .green)
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(bg)
            .foregroundColor(fg)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func menuRow(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}
