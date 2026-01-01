import SwiftUI
import AppKit
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var queueWindow: NSWindow?
    var preferencesWindow: NSWindow?
    var queueManager: QueueManager?
    var clipboardMonitor: ClipboardMonitor?
    var keyboardShortcutManager: KeyboardShortcutManager?
    var modelContainer: ModelContainer?
    var historyStore: HistoryStore?
    var categoryStore: CategoryStore?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureDockIcon()
        applyAppearanceMode()

        do {
            modelContainer = try ModelContainer(for: ClipboardHistoryEntry.self, ClipboardCategory.self)
            if let modelContainer {
                historyStore = HistoryStore(modelContext: modelContainer.mainContext)
                categoryStore = CategoryStore(modelContext: modelContainer.mainContext)
            }
        } catch {
            print("⚠️ Failed to initialize history store: \(error.localizedDescription)")
        }

        // Create the queue manager
        queueManager = QueueManager(historyStore: historyStore)
        
        // Create the clipboard monitor
        clipboardMonitor = ClipboardMonitor(queueManager: queueManager!)
        clipboardMonitor?.startMonitoring()
        
        // Create keyboard shortcut manager
        keyboardShortcutManager = KeyboardShortcutManager(queueManager: queueManager!)
        keyboardShortcutManager?.onToggleWindow = { [weak self] in
            self?.toggleWindow()
        }
        keyboardShortcutManager?.registerDefaultShortcuts()
        
        // Create the status bar item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use SF Symbol for menu bar icon
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            if let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipQueue") {
                button.image = image.withSymbolConfiguration(config)
            } else {
                // Fallback to text if SF Symbol not available
                button.title = "📋"
            }
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Create the floating window
        createFloatingWindow()
        
        print("✅ ClipQueue started")
    }

    private func configureDockIcon() {
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            NSApplication.shared.applicationIconImage = appIcon
            return
        }

        let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        if let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipQueue") {
            let icon = image.withSymbolConfiguration(config) ?? image
            icon.isTemplate = false
            NSApplication.shared.applicationIconImage = icon
        }
    }

    private func applyAppearanceMode() {
        let mode = Preferences.shared.appearanceMode
        switch mode {
        case .system:
            NSApp.appearance = nil  // Follow system
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }

        // Observe preference changes
        Preferences.shared.$appearanceMode.sink { [weak self] newMode in
            self?.updateAppearance(newMode)
        }.store(in: &cancellables)
    }

    private func updateAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
    
    private func createFloatingWindow() {
        // Create window with saved position or default
        let savedFrame = loadWindowFrame()
        
        let window = NSWindow(
            contentRect: savedFrame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        window.title = "ClipQueue (0)"
        window.level = .floating  // Always on top
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        // Set minimum and maximum sizes for responsive behavior
        window.minSize = NSSize(width: 280, height: 300)
        window.maxSize = NSSize(width: 800, height: 1200)
        
        // Add transparency
        window.isOpaque = false
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.97)
        window.alphaValue = 0.97
        
        // Set up the SwiftUI content with callback
        let contentView = QueueView(
            queueManager: queueManager!,
            historyStore: historyStore,
            categoryStore: categoryStore,
            onOpenPreferences: { [weak self] in
                self?.openPreferences()
            }
        )
        if let modelContainer {
            window.contentView = NSHostingView(rootView: contentView.modelContainer(modelContainer))
        } else {
            window.contentView = NSHostingView(rootView: contentView)
        }
        
        // Update window title when queue changes
        queueManager?.$items.sink { [weak window] items in
            window?.title = "ClipQueue (\(items.count))"
        }.store(in: &cancellables)
        
        // Save window frame when it changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.saveWindowFrame()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.saveWindowFrame()
        }
        
        self.queueWindow = window
        
        // Show window initially
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Don't steal focus from other apps
        NSApp.activate(ignoringOtherApps: false)
    }
    
    @objc func toggleWindow() {
        guard let window = queueWindow else { return }
        
        if window.isVisible {
            // Hide window and pause monitoring
            window.orderOut(nil)
            if Preferences.shared.pauseMonitoringWhenHidden {
                clipboardMonitor?.stopMonitoring()
                keyboardShortcutManager?.setMonitoringEnabled(false)
                print("🪟 Window hidden - monitoring paused")
            } else {
                print("🪟 Window hidden - monitoring continues")
            }
        } else {
            // Show window and resume monitoring
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: false)
            if Preferences.shared.pauseMonitoringWhenHidden {
                clipboardMonitor?.startMonitoring()
                keyboardShortcutManager?.setMonitoringEnabled(true)
            }
            print("🪟 Window shown - monitoring active")
        }
    }
    
    func openPreferences() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create preferences window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "ClipQueue Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        
        let contentView = PreferencesView(categoryStore: categoryStore)
        if let modelContainer {
            window.contentView = NSHostingView(rootView: contentView.modelContainer(modelContainer))
        } else {
            window.contentView = NSHostingView(rootView: contentView)
        }
        
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("⚙️ Preferences opened")
    }
    
    // MARK: - Window Frame Persistence
    
    private func saveWindowFrame() {
        guard let window = queueWindow else { return }
        let frame = window.frame
        let frameString = NSStringFromRect(frame)
        UserDefaults.standard.set(frameString, forKey: "windowFrame")
    }
    
    private func loadWindowFrame() -> NSRect {
        if let frameString = UserDefaults.standard.string(forKey: "windowFrame") {
            let frame = NSRectFromString(frameString)
            // Validate frame is on screen
            if !frame.isEmpty && NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) {
                return frame
            }
        }
        
        // Default frame (center of screen)
        let defaultSize = NSSize(width: 300, height: 400)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - defaultSize.width / 2
            let y = screenFrame.midY - defaultSize.height / 2
            return NSRect(x: x, y: y, width: defaultSize.width, height: defaultSize.height)
        }
        
        return NSRect(x: 100, y: 100, width: defaultSize.width, height: defaultSize.height)
    }
    
    // Store for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        keyboardShortcutManager?.unregisterAll()
        saveWindowFrame()
        print("👋 ClipQueue terminated")
    }
}

// Need to import Combine for the sink operator
import Combine
