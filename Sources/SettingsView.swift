import SwiftUI

// Default slider index (10 min → index 4); defined here for UI use
private let _defaultPauseIndex: Double = defaultPauseIndex

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    // Index into pauseSnapValues — evenly spaced on the slider regardless of value magnitude
    @State private var pauseIndex: Double = defaultPauseIndex

    var currentPauseValue: Double { pauseSnapValues[Int(pauseIndex.rounded())] }

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
                    Text(formatPause(currentPauseValue))
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    // Index-based slider: evenly spaced steps, no value-scale distortion
                    Slider(
                        value: $pauseIndex,
                        in: 0...Double(pauseSnapValues.count - 1),
                        step: 1
                    )
                    if timerManager.isPaused {
                        Button("Resume") { timerManager.resumeTimer() }
                            .buttonStyle(.bordered).controlSize(.small)
                    } else {
                        Button("Pause") {
                            if currentPauseValue >= 9999 {
                                timerManager.pauseIndefinitely()
                            } else {
                                timerManager.pauseApp(minutes: Int(currentPauseValue))
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
