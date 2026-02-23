import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("StarePatrol 🚔")
                .font(.headline)
            
            Divider()
            
            if timerManager.isBreaking {
                Text("Take a break! Look 20ft away.")
                    .foregroundColor(.orange)
            } else {
                HStack {
                    Text("Next break in:")
                    Spacer()
                    Text(timerManager.timeString)
                        .font(.body.monospacedDigit())
                }
            }
            
            Divider()
            
            Menu("Pause StarePatrol...") {
                Button("Pause for 5 Minutes") { timerManager.snoozeBreak(minutes: 5) }
                Button("Pause for 15 Minutes") { timerManager.snoozeBreak(minutes: 15) }
                Button("Pause for 30 Minutes") { timerManager.snoozeBreak(minutes: 30) }
                Button("Pause for 1 Hour") { timerManager.snoozeBreak(minutes: 60) }
            }
            
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
        .padding()
        // MenuBarExtra content view dimensions
        .frame(width: 250)
    }
}
