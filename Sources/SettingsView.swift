import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var pauseMinutes: Double = 15
    
    var body: some View {
        // Status row
        if timerManager.isBreaking {
            Text("👀 Break time! Look 20ft away.")
                .foregroundColor(.orange)
        } else if timerManager.isPaused {
            Text("⏸ Paused – \(timerManager.timeString) left")
            Button("Resume Work") {
                timerManager.resumeTimer()
            }
        } else {
            Text("Next break in \(timerManager.timeString)")
        }
        
        Divider()
        
        // Custom pause duration selector with slider
        VStack(alignment: .leading, spacing: 6) {
            Text("Pause for \(Int(pauseMinutes)) min")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Slider(value: $pauseMinutes, in: 1...120, step: 1)
                    .frame(minWidth: 120)
                Button("Pause") {
                    timerManager.pauseApp(minutes: Int(pauseMinutes))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(width: 240)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        
        Divider()
        
        Button("Preferences…") {
            PreferencesWindowManager.shared.showPreferences(timerManager: timerManager)
        }
        
        Button("Reset Timer") {
            timerManager.resetTimer()
        }
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
