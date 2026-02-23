import SwiftUI
import ServiceManagement

// ── Shared row style matching the menu panel ───────────────────────────────

struct PrefRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let content: Content
    init(icon: String, color: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.icon = icon; self.iconColor = color; self.content = content()
    }
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            content
        }
    }
}

struct SectionCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
    }
}

// ── PreferencesView ────────────────────────────────────────────────────────

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager

    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("isStrictMode") private var isStrictMode: Bool = false
    @AppStorage("notificationMode") private var notificationMode: String = "fullscreen"
    @AppStorage("selectedSoundName") private var selectedSoundName: String = "Glass"
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage("customReminderMessage") private var customReminderMessage: String = "Rest your eyes — look 20ft away."
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "eyes"
    @AppStorage("totalBreaksTaken") private var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") private var totalBreaksSkipped: Int = 0

    let availableSounds = ["Glass", "Ping", "Purr", "Funk", "Basso", "Hero", "Pop", "Submarine"]
    let availableIcons  = ["eyes", "eyeglasses", "timer", "clock.fill", "eye.fill", "macwindow"]

    var body: some View {
        TabView {
            settingsTab.tabItem { Label("Settings", systemImage: "gearshape") }
            statsTab.tabItem    { Label("Statistics", systemImage: "chart.bar.fill") }
            aboutTab.tabItem    { Label("About", systemImage: "info.circle") }
            debugTab.tabItem    { Label("Debug", systemImage: "ladybug") }
        }
        .frame(width: 520, height: 580)
    }

    // ── Settings tab ──────────────────────────────────────────────────────

    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 14) {

                // General
                prefSection(title: "General", icon: "gearshape.fill", color: .gray) {
                    PrefRow(icon: "power", color: .blue) {
                        Toggle("Enable StarePatrol", isOn: $isAppEnabled)
                            .onChange(of: isAppEnabled) { timerManager.settingsUpdated() }
                    }
                    Divider()
                    PrefRow(icon: "arrow.up.right.circle", color: .green) {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) {
                                do {
                                    if launchAtLogin { try SMAppService.mainApp.register() }
                                    else { try SMAppService.mainApp.unregister() }
                                } catch { print("SMAppService error: \(error)") }
                            }
                    }
                    Divider()
                    PrefRow(icon: "lock.fill", color: .red) {
                        Toggle("Strict Mode (no skip/snooze)", isOn: $isStrictMode)
                            .onChange(of: isStrictMode) { timerManager.settingsUpdated() }
                    }
                }
                .disabled(!isAppEnabled)

                // Intervals
                prefSection(title: "Intervals", icon: "timer", color: .orange) {
                    PrefRow(icon: "briefcase", color: .blue) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Work: \(workIntervalMinutes) min").font(.subheadline)
                            Slider(value: Binding(get: { Double(workIntervalMinutes) },
                                                  set: { workIntervalMinutes = Int($0) }),
                                   in: 1...60, step: 1)
                            .onChange(of: workIntervalMinutes) { timerManager.settingsUpdated() }
                        }
                    }
                    Divider()
                    PrefRow(icon: "eye.slash", color: .purple) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break: \(breakIntervalSeconds) sec").font(.subheadline)
                            Slider(value: Binding(get: { Double(breakIntervalSeconds) },
                                                  set: { breakIntervalSeconds = Int($0) }),
                                   in: 5...300, step: 5)
                            .onChange(of: breakIntervalSeconds) { timerManager.settingsUpdated() }
                        }
                    }
                }
                .disabled(!isAppEnabled)

                // Notifications
                prefSection(title: "Notifications", icon: "bell.fill", color: .red) {
                    PrefRow(icon: "rectangle.on.rectangle", color: .indigo) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Break Alert Style").font(.subheadline)
                            Picker("", selection: $notificationMode) {
                                Text("Full Screen").tag("fullscreen")
                                Text("Banner").tag("banner")
                                Text("None").tag("none")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                    Divider()
                    PrefRow(icon: "speaker.wave.2", color: .orange) {
                        Toggle("Play Sound", isOn: $isSoundEnabled)
                    }
                    if isSoundEnabled {
                        PrefRow(icon: "music.note", color: .orange) {
                            Picker("Sound", selection: $selectedSoundName) {
                                ForEach(availableSounds, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedSoundName) { SoundManager.shared.previewSound(selectedSoundName) }
                        }
                    }
                    Divider()
                    PrefRow(icon: "hand.tap", color: .pink) {
                        Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
                    }
                }
                .disabled(!isAppEnabled)

                // Appearance
                prefSection(title: "Appearance", icon: "paintbrush.fill", color: .teal) {
                    PrefRow(icon: "menubar.rectangle", color: .teal) {
                        Picker("Menu Bar Icon", selection: $menuBarIconName) {
                            ForEach(availableIcons, id: \.self) { icon in
                                HStack { Image(systemName: icon); Text(icon) }.tag(icon)
                            }
                        }
                    }
                    Divider()
                    PrefRow(icon: "text.bubble", color: .teal) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Reminder Message").font(.subheadline)
                                Spacer()
                                Button("Reset") {
                                    customReminderMessage = "Rest your eyes — look 20ft away."
                                }
                                .buttonStyle(.link).font(.caption)
                            }
                            TextEditor(text: $customReminderMessage)
                                .frame(height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // ── Stats tab ─────────────────────────────────────────────────────────

    private var statsTab: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                statCard(value: totalBreaksTaken, label: "Breaks Taken", color: .green)
                statCard(value: totalBreaksSkipped, label: "Skipped", color: .orange)
            }
            Button("Reset Statistics") {
                totalBreaksTaken = 0; totalBreaksSkipped = 0
            }
            .buttonStyle(.link)
            Spacer()
        }
        .padding(32)
    }

    private func statCard(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 130, height: 110)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }

    // ── About tab ─────────────────────────────────────────────────────────

    private var aboutTab: some View {
        VStack(spacing: 18) {
            Image(systemName: "eyes")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .padding(.top, 30)
            VStack(spacing: 4) {
                Text("StarePatrol").font(.largeTitle.bold())
                Text("Version 1.0").foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(30)
    }

    // ── Debug tab ─────────────────────────────────────────────────────────

    private var debugTab: some View {
        VStack(spacing: 14) {
            Image(systemName: "ladybug").font(.largeTitle).foregroundColor(.secondary)
            Text("Testing tools").font(.title3.bold())
            Text("Trigger a break instantly to test your notification style and sounds.")
                .multilineTextAlignment(.center).foregroundColor(.secondary).padding(.horizontal)
            Button("Trigger Break Now") { timerManager.triggerDebugBreak() }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .padding(30)
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private func prefSection<C: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
                .padding(.leading, 2)
            SectionCard(content: content)
        }
    }
}
