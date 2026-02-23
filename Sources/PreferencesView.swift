import SwiftUI
import ServiceManagement
import AppKit

// ── Section model ──────────────────────────────────────────────────────────

enum PrefSection: String, CaseIterable, Identifiable {
    case general      = "General"
    case intervals    = "Intervals"
    case notifications = "Notifications"
    case appearance   = "Appearance"
    case statistics   = "Statistics"
    case about        = "About"
    case debug        = "Debug"

    var id: Self { self }
    var icon: String {
        switch self {
        case .general:       return "gearshape"
        case .intervals:     return "timer"
        case .notifications: return "bell"
        case .appearance:    return "paintbrush"
        case .statistics:    return "chart.bar"
        case .about:         return "info.circle"
        case .debug:         return "ladybug"
        }
    }
    var color: Color {
        switch self {
        case .general:       return .gray
        case .intervals:     return .orange
        case .notifications: return .red
        case .appearance:    return .teal
        case .statistics:    return .green
        case .about:         return .blue
        case .debug:         return .purple
        }
    }
    // Preferred content height for each section (sidebar excluded)
    var contentHeight: CGFloat {
        switch self {
        case .general:       return 200
        case .intervals:     return 200
        case .notifications: return 280
        case .appearance:    return 200
        case .statistics:    return 220
        case .about:         return 200
        case .debug:         return 180
        }
    }
}

// ── Shared row components ──────────────────────────────────────────────────

struct PrefRow<Content: View>: View {
    let icon: String; let iconColor: Color; let content: Content
    init(icon: String, color: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.icon = icon; iconColor = color; self.content = content()
    }
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(iconColor.opacity(0.12)).frame(width: 28, height: 28)
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(iconColor)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
    }
}

// ── PreferencesView ────────────────────────────────────────────────────────

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var selectedSection: PrefSection = .general

    var body: some View {
        NavigationSplitView {
            List(PrefSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(160)
        } detail: {
            detailView
                .frame(width: 360, height: selectedSection.contentHeight)
                .animation(.easeInOut(duration: 0.2), value: selectedSection)
        }
        .onChange(of: selectedSection) { resizeWindow() }
        .onAppear { resizeWindow() }
    }

    @ViewBuilder private var detailView: some View {
        switch selectedSection {
        case .general:       GeneralSection(timerManager: timerManager)
        case .intervals:     IntervalsSection(timerManager: timerManager)
        case .notifications: NotificationsSection(timerManager: timerManager)
        case .appearance:    AppearanceSection(timerManager: timerManager)
        case .statistics:    StatisticsSection()
        case .about:         AboutSection()
        case .debug:         DebugSection(timerManager: timerManager)
        }
    }

    private func resizeWindow() {
        guard let window = NSApp.windows.first(where: { $0.title == "StarePatrol Preferences" }) else { return }
        let sidebarWidth: CGFloat = 160
        let newWidth  = sidebarWidth + 360
        let newHeight = selectedSection.contentHeight + 28 // +28 for toolbar
        let origin = CGPoint(
            x: window.frame.minX,
            y: window.frame.maxY - newHeight
        )
        window.animator().setFrame(NSRect(origin: origin, size: CGSize(width: newWidth, height: newHeight)), display: true)
    }
}

// ── Section views ──────────────────────────────────────────────────────────

struct GeneralSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("isStrictMode") private var isStrictMode: Bool = false
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionCard {
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
                                } catch { print("SMAppService: \(error)") }
                            }
                    }
                    Divider()
                    PrefRow(icon: "lock.fill", color: .red) {
                        Toggle("Strict Mode (no skip/snooze)", isOn: $isStrictMode)
                            .onChange(of: isStrictMode) { timerManager.settingsUpdated() }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct IntervalsSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionCard {
                    PrefRow(icon: "briefcase", color: .blue) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Work: \(workIntervalMinutes) min").font(.subheadline)
                            Slider(value: Binding(get: { Double(workIntervalMinutes) }, set: { workIntervalMinutes = Int($0) }), in: 1...60, step: 1)
                                .onChange(of: workIntervalMinutes) { timerManager.settingsUpdated() }
                        }
                    }
                    Divider()
                    PrefRow(icon: "eye.slash", color: .purple) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break: \(breakIntervalSeconds) sec").font(.subheadline)
                            Slider(value: Binding(get: { Double(breakIntervalSeconds) }, set: { breakIntervalSeconds = Int($0) }), in: 5...300, step: 5)
                                .onChange(of: breakIntervalSeconds) { timerManager.settingsUpdated() }
                        }
                    }
                }
            }
            .padding(16)
        }
        .disabled(!isAppEnabled)
    }
}

struct NotificationsSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("notificationMode") private var notificationMode: String = "fullscreen"
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isWorkEndSoundEnabled") private var isWorkEndSoundEnabled: Bool = false
    @AppStorage("selectedSoundName") private var selectedSoundName: String = "Glass"
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true

    let availableSounds = ["Glass", "Ping", "Purr", "Funk", "Basso", "Hero", "Pop", "Submarine"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionCard {
                    PrefRow(icon: "rectangle.on.rectangle", color: .indigo) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Break Alert Style").font(.subheadline)
                            Picker("", selection: $notificationMode) {
                                Text("Full Screen").tag("fullscreen")
                                Text("Notification").tag("notification")
                                Text("None").tag("none")
                            }
                            .pickerStyle(.segmented).labelsHidden()
                        }
                    }
                }

                SectionCard {
                    PrefRow(icon: "speaker.wave.2", color: .orange) {
                        Toggle("Sound at break start", isOn: $isSoundEnabled)
                    }
                    Divider()
                    PrefRow(icon: "bell.badge", color: .orange) {
                        Toggle("Sound when work period ends", isOn: $isWorkEndSoundEnabled)
                    }
                    if isSoundEnabled || isWorkEndSoundEnabled {
                        Divider()
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
            }
            .padding(16)
        }
        .disabled(!isAppEnabled)
    }
}

struct AppearanceSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "eyes"
    @AppStorage("customReminderMessage") private var customReminderMessage: String = "Rest your eyes — look 20ft away."

    let availableIcons = ["eyes", "eyeglasses", "timer", "clock.fill", "eye.fill", "macwindow"]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SectionCard {
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
                                Button("Reset") { customReminderMessage = "Rest your eyes — look 20ft away." }
                                    .buttonStyle(.link).font(.caption)
                            }
                            TextEditor(text: $customReminderMessage)
                                .frame(height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct StatisticsSection: View {
    @AppStorage("totalBreaksTaken") private var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") private var totalBreaksSkipped: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                statCard(value: totalBreaksTaken, label: "Breaks Taken", color: .green)
                statCard(value: totalBreaksSkipped, label: "Skipped", color: .orange)
            }
            Button("Reset Statistics") { totalBreaksTaken = 0; totalBreaksSkipped = 0 }
                .buttonStyle(.link)
        }
        .frame(maxHeight: .infinity)
        .padding(24)
    }

    private func statCard(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(width: 120, height: 100).background(color.opacity(0.08)).cornerRadius(12)
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "eyes").font(.system(size: 56)).foregroundColor(.accentColor)
            VStack(spacing: 4) {
                Text("StarePatrol").font(.title2.bold())
                Text("Version 1.0").foregroundColor(.secondary).font(.subheadline)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(24)
    }
}

struct DebugSection: View {
    @ObservedObject var timerManager: TimerManager
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "ladybug").font(.largeTitle).foregroundColor(.secondary)
            Text("Trigger a break instantly to test notifications and sounds.")
                .multilineTextAlignment(.center).foregroundColor(.secondary).padding(.horizontal)
            Button("Trigger Break Now") { timerManager.triggerDebugBreak() }
                .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .frame(maxHeight: .infinity)
        .padding(24)
    }
}
