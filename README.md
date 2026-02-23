<p align="center">
  <img src="docs/icon.png" width="128" alt="StarePatrol icon">
</p>

<h1 align="center">StarePatrol</h1>

<p align="center">
  <strong>A macOS menu bar app that keeps your eyes healthy with the 20-20-20 rule.</strong><br>
  Every 20 minutes, look at something 20 feet away for 20 seconds.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/built%20with-Swift-orange?style=flat-square" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT">
</p>

---

## What is StarePatrol?

Staring at a screen for hours without breaks leads to **digital eye strain** — headaches, blurry vision, and tired eyes. The **20-20-20 rule** is the simplest, most effective remedy: every 20 minutes, look at something 20 feet away for 20 seconds.

StarePatrol lives in your menu bar and enforces this rule silently, with gentle reminders that actually work.

---

## Features

- 🕐 **Configurable intervals** — set your own work and break durations
- 🔔 **Three alert styles** — full-screen takeover, system notification, or silent
- 🔊 **Sounds** — distinct sounds at break start and break end
- ⏸ **Pause & Snooze** — pause the timer or snooze a break without losing your flow
- 🔒 **Strict Mode** — disable skip/snooze for maximum discipline
- 📊 **Statistics** — track breaks taken and skipped over time
- 🚀 **Launch at Login** — starts automatically when you log in
- ✏️ **Customizable message** — change the text shown during breaks
- 🎨 **Customizable menu bar icon** — pick the SF Symbol you like most

---

## Installation

### Requirements
- macOS 14.0 (Sonoma) or later
- Apple Silicon (arm64)

### Build from source

```bash
git clone https://github.com/abram0v1ch/StarePatrol.git
cd StarePatrol
make run
```

This compiles the app, signs it ad-hoc, and launches it automatically.

> **Note:** The build output is at `/tmp/StarePatrol-build/StarePatrol.app`. macOS places a quarantine lock on directories that have previously run apps, so `/tmp` is used as the consistent build location to avoid this.

### After first launch
macOS may show a security prompt the first time. Go to **System Settings → Privacy & Security** and allow StarePatrol to run.

For notification alerts, open **System Settings → Notifications → StarePatrol** and set style to **Alerts** so they persist until dismissed.

---

## Usage

StarePatrol appears as an icon in your **menu bar**. Click it to:

- See the countdown to your next break
- Pause the timer for a set duration
- Open Preferences

### Preferences

| Section | What you can configure |
|---|---|
| **General** | Enable/disable the app, Launch at Login, Strict Mode |
| **Intervals** | Work duration (1–60 min) and break duration (5–300 sec) |
| **Notifications** | Alert style (Full Screen / Notification / None), sounds at break start and end, haptics, sound selection |
| **Appearance** | Menu bar icon, custom reminder message |
| **Statistics** | Breaks taken / skipped, reset button |
| **Debug** | Trigger an instant break to test your settings |

---

## How it works

A `Timer` publishes every second on the main thread. When the work interval ends, the app triggers a break:

- **Full Screen** — an `NSPanel` covers all displays, preventing screen use
- **Notification** — a `UNUserNotification` fires via Notification Center
- **None** — silent timer only, useful with other reminder systems

Sounds are played using `NSSound(named:)` via system sound files. Break-start and break-end sounds are decoupled so they don't interfere.

---

## Makefile

```bash
make build   # compile to /tmp/StarePatrol-build/StarePatrol.app
make run     # build + open the app
make clean   # quit the app and remove the build artifacts
```

---

## Author

Made by **Vasyl Abramovych** — [@abram0v1ch](https://github.com/abram0v1ch)

---

## License

MIT — see [LICENSE](LICENSE) for details.
