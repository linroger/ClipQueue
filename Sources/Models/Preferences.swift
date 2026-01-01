import Foundation
import ServiceManagement

class Preferences: ObservableObject {
    static let shared = Preferences()
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            // Actually enable/disable launch at login
            LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    @Published var keepWindowOnTop: Bool {
        didSet {
            UserDefaults.standard.set(keepWindowOnTop, forKey: "keepWindowOnTop")
        }
    }
    
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }
    
    // Keyboard shortcuts
    @Published var copyAndRecordShortcut: String {
        didSet {
            UserDefaults.standard.set(copyAndRecordShortcut, forKey: "copyAndRecordShortcut")
        }
    }
    
    @Published var toggleWindowShortcut: String {
        didSet {
            UserDefaults.standard.set(toggleWindowShortcut, forKey: "toggleWindowShortcut")
        }
    }
    
    @Published var pasteNextShortcut: String {
        didSet {
            UserDefaults.standard.set(pasteNextShortcut, forKey: "pasteNextShortcut")
        }
    }
    
    @Published var pasteAllShortcut: String {
        didSet {
            UserDefaults.standard.set(pasteAllShortcut, forKey: "pasteAllShortcut")
        }
    }
    
    @Published var clearAllShortcut: String {
        didSet {
            UserDefaults.standard.set(clearAllShortcut, forKey: "clearAllShortcut")
        }
    }
    
    private init() {
        // Load saved preferences or use defaults
        let savedKeepOnTop = UserDefaults.standard.object(forKey: "keepWindowOnTop")
        self.keepWindowOnTop = savedKeepOnTop == nil ? true : UserDefaults.standard.bool(forKey: "keepWindowOnTop")
        
        let savedShowInMenuBar = UserDefaults.standard.object(forKey: "showInMenuBar")
        self.showInMenuBar = savedShowInMenuBar == nil ? true : UserDefaults.standard.bool(forKey: "showInMenuBar")
        
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        
        // Load shortcuts or use defaults
        self.copyAndRecordShortcut = UserDefaults.standard.string(forKey: "copyAndRecordShortcut") ?? "⌃Q"
        self.toggleWindowShortcut = UserDefaults.standard.string(forKey: "toggleWindowShortcut") ?? "⌃⌥⌘C"
        self.pasteNextShortcut = UserDefaults.standard.string(forKey: "pasteNextShortcut") ?? "⌃W"
        self.pasteAllShortcut = UserDefaults.standard.string(forKey: "pasteAllShortcut") ?? "⌃E"
        self.clearAllShortcut = UserDefaults.standard.string(forKey: "clearAllShortcut") ?? "⌃X"
    }
    
    func resetToDefaults() {
        launchAtLogin = false
        keepWindowOnTop = true
        showInMenuBar = true
        copyAndRecordShortcut = "⌃Q"
        toggleWindowShortcut = "⌃⌥⌘C"
        pasteNextShortcut = "⌃W"
        pasteAllShortcut = "⌃E"
        clearAllShortcut = "⌃X"
    }
}
