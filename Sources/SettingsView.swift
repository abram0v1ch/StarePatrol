import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var pauseMinutes: Int = 15
    
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
        
        // Custom pause duration selector
        VStack(alignment: .leading, spacing: 6) {
            Stepper("Pause: \(pauseMinutes) min", value: $pauseMinutes, in: 1...120)
            Button("Pause Now") {
                timerManager.pauseApp(minutes: pauseMinutes)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(width: 220)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        
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
