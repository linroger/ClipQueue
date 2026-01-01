import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    /// Enable or disable launch at login
    func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                // Register the app to launch at login
                if #available(macOS 13.0, *) {
                    try SMAppService.mainApp.register()
                    print("✅ Launch at login enabled")
                } else {
                    // Fallback for older macOS versions
                    setLaunchAtLoginLegacy(enabled: true)
                }
            } else {
                // Unregister the app from launch at login
                if #available(macOS 13.0, *) {
                    try SMAppService.mainApp.unregister()
                    print("❌ Launch at login disabled")
                } else {
                    // Fallback for older macOS versions
                    setLaunchAtLoginLegacy(enabled: false)
                }
            }
        } catch {
            print("⚠️ Failed to set launch at login: \(error.localizedDescription)")
        }
    }
    
    /// Check if launch at login is currently enabled
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions
            return isEnabledLegacy()
        }
    }
    
    // MARK: - Legacy Support (macOS 12 and earlier)
    
    private func setLaunchAtLoginLegacy(enabled: Bool) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.clipqueue.ClipQueue"
        
        if enabled {
            // Add to login items using LSSharedFileList (deprecated but works)
            let script = """
            tell application "System Events"
                make login item at end with properties {path:"\(Bundle.main.bundlePath)", hidden:false}
            end tell
            """
            
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    print("⚠️ AppleScript error: \(error)")
                } else {
                    print("✅ Launch at login enabled (legacy)")
                }
            }
        } else {
            // Remove from login items
            let script = """
            tell application "System Events"
                delete login item "ClipQueue"
            end tell
            """
            
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    print("⚠️ AppleScript error: \(error)")
                } else {
                    print("❌ Launch at login disabled (legacy)")
                }
            }
        }
    }
    
    private func isEnabledLegacy() -> Bool {
        let script = """
        tell application "System Events"
            get the name of every login item
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("⚠️ AppleScript error: \(error)")
                return false
            }
            
            // Check if "ClipQueue" is in the list
            if let resultString = result.stringValue {
                return resultString.contains("ClipQueue")
            }
        }
        
        return false
    }
}
