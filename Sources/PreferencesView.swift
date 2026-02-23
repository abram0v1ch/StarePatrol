import SwiftUI

struct PreferencesView: View {
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    
    var body: some View {
        Form {
            Section(header: Text("Intervals").font(.headline)) {
                VStack(alignment: .leading) {
                    Text("Work Duration: \(workIntervalMinutes) minutes")
                    Slider(value: Binding(get: {
                        Double(workIntervalMinutes)
                    }, set: { newValue in
                        workIntervalMinutes = Int(newValue)
                    }), in: 1...60, step: 1)
                }
                .padding(.vertical, 5)
                
                VStack(alignment: .leading) {
                    Text("Break Duration: \(breakIntervalSeconds) seconds")
                    Slider(value: Binding(get: {
                        Double(breakIntervalSeconds)
                    }, set: { newValue in
                        breakIntervalSeconds = Int(newValue)
                    }), in: 5...300, step: 5)
                }
                .padding(.vertical, 5)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            Section(header: Text("Notifications").font(.headline)) {
                Toggle("Play Sound (\(isSoundEnabled ? "Glass" : "None"))", isOn: $isSoundEnabled)
                Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
            }
        }
        .padding(30)
        .frame(width: 400, height: 350)
    }
}
