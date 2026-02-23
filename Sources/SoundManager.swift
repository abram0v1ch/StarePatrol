import AppKit
import SwiftUI

class SoundManager {
    static let shared = SoundManager()
    
    init() {
        // Set default values if not explicitly set yet
        UserDefaults.standard.register(defaults: [
            "isSoundEnabled": true,
            "isHapticsEnabled": true
        ])
    }
    
    func playGentleReminderSound() {
        guard UserDefaults.standard.bool(forKey: "isSoundEnabled") else { return }
        
        // Use a standard system sound that is gentle
        // Ping, Purr, or Glass are okay. We'll use "Glass".
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
    
    func performHapticFeedback() {
        guard UserDefaults.standard.bool(forKey: "isHapticsEnabled") else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
    
    func triggerFeedback() {
        playGentleReminderSound()
        performHapticFeedback()
    }
}
