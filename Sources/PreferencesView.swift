import SwiftUI

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager
    
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("useFullScreenPopup") private var useFullScreenPopup: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("General").font(.headline)) {
                Toggle("Enable StarePatrol", isOn: $isAppEnabled)
                    .onChange(of: isAppEnabled) { _ in timerManager.settingsUpdated() }
            }
            
            Divider().padding(.vertical, 5)
            
            Section(header: Text("Intervals").font(.headline)) {
                VStack(alignment: .leading) {
                    Text("Work Duration: \(workIntervalMinutes) minutes")
                    Slider(value: Binding(get: {
                        Double(workIntervalMinutes)
                    }, set: { newValue in
                        workIntervalMinutes = Int(newValue)
                    }), in: 1...60, step: 1)
                    .onChange(of: workIntervalMinutes) { _ in timerManager.settingsUpdated() }
                }
                .padding(.vertical, 5)
                
                VStack(alignment: .leading) {
                    Text("Break Duration: \(breakIntervalSeconds) seconds")
                    Slider(value: Binding(get: {
                        Double(breakIntervalSeconds)
                    }, set: { newValue in
                        breakIntervalSeconds = Int(newValue)
                    }), in: 5...300, step: 5)
                    .onChange(of: breakIntervalSeconds) { _ in timerManager.settingsUpdated() }
                }
                .padding(.vertical, 5)
            }
            .disabled(!isAppEnabled)
            
            Divider()
                .padding(.vertical, 10)
            
            Section(header: Text("Notifications").font(.headline)) {
                Toggle("Full Screen Popup (vs. System Notification)", isOn: $useFullScreenPopup)
                Toggle("Play Sound (\(isSoundEnabled ? "Glass" : "None"))", isOn: $isSoundEnabled)
                Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
            }
            .disabled(!isAppEnabled)
        }
        .padding(30)
        .frame(width: 450, height: 420)
    }
}
