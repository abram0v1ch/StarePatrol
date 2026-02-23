import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager
    
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("isStrictMode") private var isStrictMode: Bool = false
    @AppStorage("useFullScreenPopup") private var useFullScreenPopup: Bool = true
    @AppStorage("selectedSoundName") private var selectedSoundName: String = "Glass"
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage("customReminderMessage") private var customReminderMessage: String = "Time to rest your eyes! Look 20 feet away."
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "eyes"
    
    let availableSounds = ["Glass", "Ping", "Purr", "Funk", "Basso", "Hero", "Pop", "Submarine"]
    let availableIcons = ["eyes", "eyeglasses", "timer", "clock.fill", "eye.fill", "macwindow"]
    
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
                Toggle("Launch StarePatrol at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _ in
                        do {
                            if launchAtLogin {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update SMAppService: \(error.localizedDescription)")
                        }
                    }
                
                Toggle("Enable StarePatrol", isOn: $isAppEnabled)
                    .onChange(of: isAppEnabled) { _ in timerManager.settingsUpdated() }
                
                Toggle("Strict Mode (Disable skip/snooze)", isOn: $isStrictMode)
                    .onChange(of: isStrictMode) { _ in timerManager.settingsUpdated() }
                
                TextField("Reminder Message", text: $customReminderMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 5)
                
                Picker("Menu Bar Icon", selection: $menuBarIconName) {
                    ForEach(availableIcons, id: \.self) { icon in
                        HStack {
                            Image(systemName: icon)
                            Text(icon)
                        }.tag(icon)
                    }
                }
                .padding(.top, 5)
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
