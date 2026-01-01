import SwiftUI

@main
struct ClipQueueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We don't want a regular window, just the menu bar and floating window
        Settings {
            EmptyView()
        }
    }
}
