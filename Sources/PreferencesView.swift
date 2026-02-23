import SwiftUI

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager
    
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("useFullScreenPopup") private var useFullScreenPopup: Bool = true
    @AppStorage("selectedSoundName") private var selectedSoundName: String = "Glass"
    
    let availableSounds = ["Glass", "Ping", "Purr", "Funk", "Basso", "Hero", "Pop", "Submarine"]
    
    // Stats
    @AppStorage("totalBreaksTaken") private var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") private var totalBreaksSkipped: Int = 0
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            
            statsTab
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
        }
        .padding()
        .frame(width: 450, height: 420)
    }
    
    private var generalTab: some View {
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
                
                Toggle("Play Sound", isOn: $isSoundEnabled)
                if isSoundEnabled {
                    Picker("Sound Effect", selection: $selectedSoundName) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSoundName) { _ in
                        SoundManager.shared.previewSound(selectedSoundName)
                    }
                    .padding(.leading, 20)
                }
                
                Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
            }
            .disabled(!isAppEnabled)
        }
    }
    
    private var statsTab: some View {
        VStack(spacing: 20) {
            Text("Your Eye Rest Stats 👁️")
                .font(.title2)
                .padding(.bottom, 10)
            
            HStack(spacing: 50) {
                VStack {
                    Text("\(totalBreaksTaken)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Breaks Taken")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalBreaksSkipped)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("Breaks Skipped")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Reset Statistics") {
                totalBreaksTaken = 0
                totalBreaksSkipped = 0
            }
            .buttonStyle(.link)
            .padding(.bottom)
        }
        .padding(30)
    }
}
