import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("StarePolice 🚔")
                .font(.headline)
            
            Divider()
            
            if timerManager.isBreaking {
                Text("Take a break! Look 20ft away.")
                    .foregroundColor(.orange)
            } else {
                Text("Next break in: \(timerManager.timeString)")
            }
            
            Divider()
            
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
