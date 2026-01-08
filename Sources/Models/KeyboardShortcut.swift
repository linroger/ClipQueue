import AppKit

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt
    var keyEquivalent: String

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    var displayString: String {
        modifierSymbols + keyDisplayName
    }

    private var modifierSymbols: String {
        let flags = modifierFlags
        var symbols = ""
        if flags.contains(.control) { symbols += "⌃" }
        if flags.contains(.option) { symbols += "⌥" }
        if flags.contains(.shift) { symbols += "⇧" }
        if flags.contains(.command) { symbols += "⌘" }
        return symbols
    }

    private var keyDisplayName: String {
        if let special = Self.specialKeyName(for: keyCode, keyEquivalent: keyEquivalent) {
            return special
        }
        if keyEquivalent.isEmpty {
            return "Key \(keyCode)"
        }
        return keyEquivalent.uppercased()
    }

    static func from(event: NSEvent) -> KeyboardShortcut {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyEquivalent = event.charactersIgnoringModifiers ?? ""
        return KeyboardShortcut(
            keyCode: event.keyCode,
            modifiers: flags.rawValue,
            keyEquivalent: keyEquivalent
        )
    }

    static func specialKeyName(for keyCode: UInt16, keyEquivalent: String) -> String? {
        switch keyCode {
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Esc"
        case 76: return "Enter"
        case 117: return "Forward Delete"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            break
        }

        switch keyEquivalent {
        case "\t": return "Tab"
        case "\r": return "Return"
        case "\u{1b}": return "Esc"
        case " ": return "Space"
        default: return nil
        }
    }
}
