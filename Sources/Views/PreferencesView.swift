import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferences = Preferences.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView(preferences: preferences)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)
            
            ShortcutsPreferencesView(preferences: preferences)
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(1)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject var preferences: Preferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Startup
            VStack(alignment: .leading, spacing: 8) {
                Text("Startup")
                    .font(.headline)
                
                Toggle("Launch at login", isOn: $preferences.launchAtLogin)
                
                Text("ClipQueue will start automatically when you log in.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Window
            VStack(alignment: .leading, spacing: 8) {
                Text("Window")
                    .font(.headline)
                
                Toggle("Keep window on top", isOn: $preferences.keepWindowOnTop)
                
                Text("The queue window will stay above other windows.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Show in menu bar", isOn: $preferences.showInMenuBar)
                
                Text("Show the 📋 icon in the menu bar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ShortcutsPreferencesView: View {
    @ObservedObject var preferences: Preferences
    
    var body: some View {
        Form {
            Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                ShortcutRow(
                    label: "Copy and record:",
                    shortcut: $preferences.copyAndRecordShortcut,
                    description: "Copy selected text and add to queue (alternative to Cmd+C)"
                )
                
                ShortcutRow(
                    label: "Toggle window:",
                    shortcut: $preferences.toggleWindowShortcut,
                    description: "Show or hide the ClipQueue window"
                )
                
                ShortcutRow(
                    label: "Paste next item:",
                    shortcut: $preferences.pasteNextShortcut,
                    description: "Paste the oldest item from the queue"
                )
                
                ShortcutRow(
                    label: "Paste all items:",
                    shortcut: $preferences.pasteAllShortcut,
                    description: "Paste all items from the queue"
                )
                
                ShortcutRow(
                    label: "Clear all items:",
                    shortcut: $preferences.clearAllShortcut,
                    description: "Remove all items from the queue"
                )
            }
            
            Divider()
            
            Text("Note: Changes to shortcuts require restarting ClipQueue to take effect.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                }
            }
        }
        .padding()
    }
}

struct ShortcutRow: View {
    let label: String
    @Binding var shortcut: String
    let description: String
    @State private var isRecording = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .frame(width: 150, alignment: .leading)
                
                Button(action: {
                    isRecording.toggle()
                }) {
                    Text(shortcut)
                        .frame(width: 100)
                        .padding(6)
                        .background(isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                
                if isRecording {
                    Text("Press keys...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
