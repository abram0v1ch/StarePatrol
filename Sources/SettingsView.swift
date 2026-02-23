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
                Text("Next break in: \(timerManager.timeString)")
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
