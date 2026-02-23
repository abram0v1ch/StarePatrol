import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var pauseSliderValue: Double = 15
    
    var body: some View {
        if timerManager.isBreaking {
            Text("Take a break! Look 20ft away.")
        } else if timerManager.isPaused {
            Text("Paused for \(timerManager.timeString)")
            Button("Resume Work") {
                timerManager.resumeTimer()
            }
        } else {
            Text("Next break in: \(timerManager.timeString)")
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 5) {
            Text("Pause for \(Int(pauseSliderValue)) mins")
                .font(.caption)
            HStack {
                Slider(value: $pauseSliderValue, in: 5...60, step: 5)
                Button("Pause") {
                    timerManager.pauseApp(minutes: Int(pauseSliderValue))
                }
            }
        }
        .frame(width: 220)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        
        Divider()
        
        Button("Preferences...") {
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
