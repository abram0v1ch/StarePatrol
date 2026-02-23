import AppKit
import SwiftUI

class SoundManager {
    static let shared = SoundManager()
    
    init() {
        // Set default values if not explicitly set yet
        UserDefaults.standard.register(defaults: [
            "isSoundEnabled": true,
            "breakStartSoundEnabled": true,
            "breakEndSoundEnabled": true,
            "isHapticsEnabled": true,
            "selectedSoundName": "Glass"
        ])
    }
    
    func playGentleReminderSound() {
        guard UserDefaults.standard.bool(forKey: "isSoundEnabled") else { return }
        
        let soundName = UserDefaults.standard.string(forKey: "selectedSoundName") ?? "Glass"
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }
    }
    
    func previewSound(_ name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
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
