import Foundation
import AppKit

/// Manages sound effect playback for clipboard events
class SoundManager {
    static let shared = SoundManager()

    private init() {}

    /// Plays the configured copy sound effect
    func playCopySound() {
        guard Preferences.shared.playSoundEffects else { return }
        playSound(Preferences.shared.copySoundEffect.systemSoundName)
    }

    /// Plays the configured paste sound effect
    func playPasteSound() {
        guard Preferences.shared.playSoundEffects else { return }
        playSound(Preferences.shared.pasteSoundEffect.systemSoundName)
    }

    /// Plays a system sound by name
    private func playSound(_ soundName: String?) {
        guard let soundName = soundName else { return }

        // Try to play the system sound
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        } else {
            // Fallback: Try to load from system sounds path
            let systemSoundsPath = "/System/Library/Sounds/\(soundName).aiff"
            if let sound = NSSound(contentsOfFile: systemSoundsPath, byReference: true) {
                sound.play()
            }
        }
    }

    /// Preview a specific sound effect
    func previewCopySound(_ effect: CopySoundEffect) {
        playSound(effect.systemSoundName)
    }

    /// Preview a specific paste sound effect
    func previewPasteSound(_ effect: PasteSoundEffect) {
        playSound(effect.systemSoundName)
    }
}
