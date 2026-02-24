import SwiftUI
import ServiceManagement
import AppKit

// ── Shared components ──────────────────────────────────────────────────────

struct PrefRow<Content: View>: View {
    let icon: String; let iconColor: Color; let content: Content
    init(icon: String, color: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.icon = icon; iconColor = color; self.content = content()
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
    }
}

// ── Section enum ───────────────────────────────────────────────────────────

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
        case .general:        return "gearshape"
        case .intervals:      return "timer"
        case .notifications:  return "bell"
        case .appearance:     return "paintbrush"
        case .statistics:     return "chart.bar"
        case .about:          return "info.circle"
        case .debug:          return "ladybug"
        }
    }
}

// ── PreferencesView ────────────────────────────────────────────────────────
// Manual HStack split — avoids NavigationSplitView which injects a
// sidebar-toggle toolbar button we can't easily remove.

struct PreferencesView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var selectedSection: PrefSection = .general

    var body: some View {
        HStack(spacing: 0) {
            // ── Sidebar ──────────────────────────────────────────────
            List(PrefSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon).tag(section)
            }
            .listStyle(.sidebar)
            .frame(width: 160)

            Divider()

            // ── Detail ───────────────────────────────────────────────
            Group {
                switch selectedSection {
                case .general:        GeneralSection(timerManager: timerManager)
                case .intervals:      IntervalsSection(timerManager: timerManager)
                case .notifications:  NotificationsSection(timerManager: timerManager)
                case .appearance:     AppearanceSection()
                case .statistics:     StatisticsSection()
                case .about:          AboutSection()
                case .debug:          DebugSection(timerManager: timerManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 500)
    }
}

// ── Section views ──────────────────────────────────────────────────────────

struct GeneralSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    @AppStorage("isStrictMode") private var isStrictMode: Bool = false
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct IntervalsSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("workIntervalMinutes") private var workIntervalMinutes: Int = 20
    @AppStorage("breakIntervalSeconds") private var breakIntervalSeconds: Int = 20
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionCard {
                PrefRow(icon: "briefcase", color: .blue) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Work: \(workIntervalMinutes) min").font(.subheadline)
                        Slider(
                            value: Binding(get: { Double(workIntervalMinutes) }, set: { workIntervalMinutes = Int($0) }),
                            in: 1...60, step: 1
                        )
                        .onChange(of: workIntervalMinutes) { timerManager.settingsUpdated() }
                    }
                }
                Divider()
                PrefRow(icon: "eye.slash", color: .purple) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Break: \(breakIntervalSeconds) sec").font(.subheadline)
                        Slider(
                            value: Binding(get: { Double(breakIntervalSeconds) }, set: { breakIntervalSeconds = Int($0) }),
                            in: 5...300, step: 5
                        )
                        .onChange(of: breakIntervalSeconds) { timerManager.settingsUpdated() }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .disabled(!isAppEnabled)
    }
}

struct NotificationsSection: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("notificationMode") private var notificationMode: String = "fullscreen"
    @AppStorage("breakStartSoundEnabled") private var breakStartSoundEnabled: Bool = true
    @AppStorage("breakEndSoundEnabled") private var breakEndSoundEnabled: Bool = true
    @AppStorage("selectedSoundName") private var selectedSoundName: String = "Glass"
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("isAppEnabled") private var isAppEnabled: Bool = true
    let availableSounds = ["Glass", "Ping", "Purr", "Funk", "Basso", "Hero", "Pop", "Submarine"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    Toggle("Sound at break start", isOn: $breakStartSoundEnabled)
                }
                Divider()
                PrefRow(icon: "bell.badge", color: .orange) {
                    Toggle("Sound at break end", isOn: $breakEndSoundEnabled)
                }
                Divider()
                PrefRow(icon: "music.note", color: .orange) {
                    Picker("Sound", selection: $selectedSoundName) {
                        ForEach(availableSounds, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSoundName) { SoundManager.shared.previewSound(selectedSoundName) }
                }
                Divider()
                PrefRow(icon: "hand.tap", color: .pink) {
                    Toggle("Haptic Feedback", isOn: $isHapticsEnabled)
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .disabled(!isAppEnabled)
    }
}

struct AppearanceSection: View {
    @AppStorage("menuBarIconName") private var menuBarIconName: String = "eyes"
    @AppStorage("customReminderMessage") private var customReminderMessage: String = "Rest your eyes — look 20ft away."
    let availableIcons = ["eyes", "eyeglasses", "timer", "clock.fill", "eye.fill", "macwindow"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                        TextField("Reminder message", text: $customReminderMessage)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct StatisticsSection: View {
    @AppStorage("totalBreaksTaken") private var totalBreaksTaken: Int = 0
    @AppStorage("totalBreaksSkipped") private var totalBreaksSkipped: Int = 0
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HStack(spacing: 30) {
                statCard(value: totalBreaksTaken, label: "Breaks Taken", color: .green)
                statCard(value: totalBreaksSkipped, label: "Skipped", color: .orange)
            }
            Button("Reset Statistics") { totalBreaksTaken = 0; totalBreaksSkipped = 0 }
                .buttonStyle(.link)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    private func statCard(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(width: 130, height: 100).background(color.opacity(0.08)).cornerRadius(12)
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            // Use the real app icon from the bundle
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            VStack(spacing: 4) {
                Text("StarePatrol").font(.title2.bold())
                Text("Version 1.0").foregroundColor(.secondary).font(.subheadline)
                Text("Protect your eyes with the 20-20-20 rule.")
                    .foregroundColor(.secondary).font(.caption).padding(.top, 2)
            }
            Divider().padding(.horizontal, 40)
            VStack(spacing: 2) {
                Text("Made by Vasyl Abramovych").font(.footnote).foregroundColor(.secondary)
                Link("github.com/abram0v1ch", destination: URL(string: "https://github.com/abram0v1ch")!)
                    .font(.footnote)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct DebugSection: View {
    @ObservedObject var timerManager: TimerManager
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "ladybug").font(.largeTitle).foregroundColor(.secondary)
            Text("Trigger a break instantly to test your notification style and sounds.")
                .multilineTextAlignment(.center).foregroundColor(.secondary).padding(.horizontal)
            Button("Trigger Break Now") { timerManager.triggerDebugBreak() }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
