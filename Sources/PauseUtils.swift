// PauseUtils.swift — pure functions, no SwiftUI/AppKit dependencies
// Included in StarePatrolCore so they can be unit-tested.

/// Snap values for the pause slider (minutes). 9999 = indefinite/∞.
let pauseSnapValues: [Double] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120, 9999]

/// Default slider index (10 min → index 4)
let defaultPauseIndex: Double = 4

/// Returns the nearest value in pauseSnapValues to `raw`.
func snapPause(_ raw: Double) -> Double {
    pauseSnapValues.min(by: { abs($0 - raw) < abs($1 - raw) }) ?? raw
}

/// Human-readable label for a pause duration in minutes.
/// - 9999 → "∞"
/// - 90 → "1h 30m"
/// - 60 → "1h"
/// - 15 → "15m"
func formatPause(_ minutes: Double) -> String {
    if minutes >= 9999 { return "∞" }
    let m = Int(minutes)
    if m >= 60 {
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }
    return "\(m)m"
}
