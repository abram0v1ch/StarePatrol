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
                .tabItem { Label("Settings", systemImage: "gearshape") }
            
            statsTab
                .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
                
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
                
            debugTab
                .tabItem { Label("Debug", systemImage: "ladybug") }
        }
        .padding()
        .frame(width: 550, height: 600)
    }
    
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // GENERAL SECTION
                VStack(alignment: .leading, spacing: 10) {
                    Text("General").font(.headline)
                    Toggle("Enable StarePatrol", isOn: $isAppEnabled)
                        .onChange(of: isAppEnabled) { _ in timerManager.settingsUpdated() }
                        .font(.headline)
                        
                    Toggle("Launch StarePatrol at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _ in
                            do {
                                if launchAtLogin { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch { print("Failed to update SMAppService: \(error)") }
                        }
                    
                    Toggle("Strict Mode (Disable skip/snooze)", isOn: $isStrictMode)
                        .onChange(of: isStrictMode) { _ in timerManager.settingsUpdated() }
                }
                .padding(.vertical, 10)
                
                Divider()
                
                // INTERVALS SECTION
                VStack(alignment: .leading, spacing: 20) {
                    Text("Intervals").font(.headline)
                    
                    VStack(alignment: .leading) {
                        Text("Work Duration: \(workIntervalMinutes) minutes").font(.subheadline)
                        Slider(value: Binding(get: { Double(workIntervalMinutes) }, set: { workIntervalMinutes = Int($0) }), in: 1...60, step: 1)
                            .onChange(of: workIntervalMinutes) { _ in timerManager.settingsUpdated() }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Break Duration: \(breakIntervalSeconds) seconds").font(.subheadline)
                        Slider(value: Binding(get: { Double(breakIntervalSeconds) }, set: { breakIntervalSeconds = Int($0) }), in: 5...300, step: 5)
                            .onChange(of: breakIntervalSeconds) { _ in timerManager.settingsUpdated() }
                    }
                }
                .padding(.vertical, 10)
                .disabled(!isAppEnabled)
                
                Divider()
                
                // NOTIFICATIONS SECTION
                VStack(alignment: .leading, spacing: 15) {
                    Text("Notifications").font(.headline)
                    
                    Toggle("Full Screen Popup (vs. System Notification)", isOn: $useFullScreenPopup)
                    Toggle("Play Sound", isOn: $isSoundEnabled)
                    
                    if isSoundEnabled {
                        Picker("Sound Effect", selection: $selectedSoundName) {
                            ForEach(availableSounds, id: \.self) { sound in Text(sound).tag(sound) }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSoundName) { _ in SoundManager.shared.previewSound(selectedSoundName) }
                        .padding(.leading, 20)
                    }
                    
                    Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
                }
                .padding(.vertical, 10)
                .disabled(!isAppEnabled)
                
                Divider()
                
                // APPEARANCE SECTION
                VStack(alignment: .leading, spacing: 15) {
                    Text("Appearance").font(.headline)
                    
                    Picker("Menu Bar Icon", selection: $menuBarIconName) {
                        ForEach(availableIcons, id: \.self) { icon in
                            HStack { Image(systemName: icon); Text(icon) }.tag(icon)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Reminder Message:")
                        TextField("Time to rest your eyes! Look 20 feet away.", text: $customReminderMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.vertical, 10)
            }
            .padding(25)
        }
    }
    
    private var statsTab: some View {
        VStack(spacing: 30) {
            Text("Your Eye Rest Stats 👁️")
                .font(.title2)
            
            HStack(spacing: 50) {
                VStack {
                    Text("\(totalBreaksTaken)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Breaks Taken")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalBreaksSkipped)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("Breaks Skipped")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(30)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Spacer()
            
            Button("Reset Statistics") {
                totalBreaksTaken = 0
                totalBreaksSkipped = 0
            }
            .buttonStyle(.link)
            .padding(.bottom)
        }
        .padding(40)
    }
    
    private var aboutTab: some View {
        VStack(spacing: 30) {
            Image(systemName: "eyes")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
                
            VStack {
                Text("StarePatrol")
                    .font(.largeTitle.bold())
                Text("Version 1.0")
                    .foregroundColor(.secondary)
            }
            
            Text("Your Eye Rest Stats 👁️")
                .font(.title2)
            
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
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
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
    
    private var debugTab: some View {
        VStack(spacing: 20) {
            Text("Debug Options")
                .font(.title2.bold())
                
            Text("Use these buttons to instantly trigger the reminder UI and notifications for testing purposes.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                
            Button("Trigger Break Now") {
                timerManager.triggerDebugBreak()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .padding(40)
    }
}
