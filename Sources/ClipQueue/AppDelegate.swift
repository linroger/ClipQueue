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

    /// The previously active app before ClipQueue became active
    private var previousActiveApp: NSRunningApplication?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureDockIcon()
        applyAppearanceMode()

        // Initialize SwiftData with migration support
        let schema = Schema([ClipboardHistoryEntry.self, ClipboardCategory.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if let modelContainer {
                historyStore = HistoryStore(modelContext: modelContainer.mainContext)
                categoryStore = CategoryStore(modelContext: modelContainer.mainContext)
                print("✅ History store initialized successfully")
            }
        } catch {
            print("⚠️ Failed to initialize history store: \(error)")
            // Try to recover by deleting corrupted store
            if let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("default.store") {
                try? FileManager.default.removeItem(at: storeURL)
                print("🔄 Attempting to recreate store after deletion...")

                do {
                    modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    if let modelContainer {
                        historyStore = HistoryStore(modelContext: modelContainer.mainContext)
                        categoryStore = CategoryStore(modelContext: modelContainer.mainContext)
                        print("✅ History store recreated successfully")
                    }
                } catch {
                    print("❌ Failed to recreate history store: \(error)")
                }
            }
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
        keyboardShortcutManager?.onToggleMiniMode = { [weak self] in
            self?.toggleMiniMode()
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

        // Track the previously active app when ClipQueue becomes active
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppActivation(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        print("✅ ClipQueue started")
    }

    @objc private func handleAppActivation(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        // If it's not ClipQueue that became active, save it as the previous app
        if app.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousActiveApp = app
            print("📝 Saved previous app: \(app.localizedName ?? "Unknown")")
        }
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

        // Observe dock badge preference changes
        Preferences.shared.$showDockBadge.sink { [weak self] _ in
            let count = self?.queueManager?.items.count ?? 0
            self?.updateDockBadge(count: count)
        }.store(in: &cancellables)

        // Observe menu bar icon preference changes
        Preferences.shared.$menuBarIconStyle.sink { [weak self] _ in
            self?.updateMenuBarIcon()
        }.store(in: &cancellables)

        Preferences.shared.$customMenuBarSymbol.sink { [weak self] _ in
            self?.updateMenuBarIcon()
        }.store(in: &cancellables)

        Preferences.shared.$customMenuBarImagePath.sink { [weak self] _ in
            self?.updateMenuBarIcon()
        }.store(in: &cancellables)

        // Observe window translucency preference changes
        Preferences.shared.$windowTranslucency.sink { [weak self] _ in
            if let window = self?.queueWindow {
                self?.updateWindowTranslucency(window)
            }
        }.store(in: &cancellables)
    }

    private func updateWindowTranslucency(_ window: NSWindow) {
        let alpha = CGFloat(Preferences.shared.windowTranslucency)
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(alpha)
        window.alphaValue = alpha
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
        
        // Add transparency based on user preference
        window.isOpaque = false
        updateWindowTranslucency(window)
        
        // Set up the SwiftUI content with callback
        let contentView = QueueView(
            queueManager: queueManager!,
            historyStore: historyStore,
            categoryStore: categoryStore,
            onOpenPreferences: { [weak self] in
                self?.openPreferences()
            },
            onPasteToPreviousApp: { [weak self] content, removeFromQueue, item in
                self?.pasteContentToPreviousApp(content, removeFromQueue: removeFromQueue, item: item)
            }
        )
        if let modelContainer {
            window.contentView = NSHostingView(rootView: contentView.modelContainer(modelContainer))
        } else {
            window.contentView = NSHostingView(rootView: contentView)
        }
        
        // Update window title and dock badge when queue changes
        queueManager?.$items.sink { [weak window, weak self] items in
            window?.title = "ClipQueue (\(items.count))"
            self?.updateDockBadge(count: items.count)
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
        
        // Create preferences window - size matches PreferencesView frame
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 580),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "ClipQueue Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating  // Appear above main window
        window.minSize = NSSize(width: 620, height: 560)
        
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
    
    // MARK: - Dock Badge

    private func updateDockBadge(count: Int) {
        guard Preferences.shared.showDockBadge else {
            NSApp.dockTile.badgeLabel = nil
            return
        }

        if count > 0 {
            NSApp.dockTile.badgeLabel = "\(count)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }

    // MARK: - Menu Bar Icon

    func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let style = Preferences.shared.menuBarIconStyle

        switch style {
        case .default:
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            if let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipQueue") {
                button.image = image.withSymbolConfiguration(config)
            }

        case .sfSymbol:
            let symbolName = Preferences.shared.customMenuBarSymbol
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ClipQueue") {
                button.image = image.withSymbolConfiguration(config)
            } else {
                // Fallback to default if symbol not found
                if let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipQueue") {
                    button.image = image.withSymbolConfiguration(config)
                }
            }

        case .custom:
            let imagePath = Preferences.shared.customMenuBarImagePath
            if !imagePath.isEmpty, let image = NSImage(contentsOfFile: imagePath) {
                // Resize for menu bar
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                // Fallback to default
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                if let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClipQueue") {
                    button.image = image.withSymbolConfiguration(config)
                }
            }
        }
    }

    // MARK: - Mini Mode (Window to Icon)

    private var isMiniMode = false
    private var savedFrame: NSRect?

    func toggleMiniMode() {
        guard let window = queueWindow else { return }

        if isMiniMode {
            // Restore from mini mode
            restoreFromMiniMode(window)
        } else {
            // Enter mini mode
            enterMiniMode(window)
        }
    }

    private func enterMiniMode(_ window: NSWindow) {
        savedFrame = window.frame

        // Animate window shrinking
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Shrink to icon size near dock/menu bar
            let iconSize = NSSize(width: 64, height: 64)
            if let screen = window.screen ?? NSScreen.main {
                let newX = screen.visibleFrame.maxX - iconSize.width - 20
                let newY = screen.visibleFrame.minY + 20
                let newFrame = NSRect(x: newX, y: newY, width: iconSize.width, height: iconSize.height)
                window.animator().setFrame(newFrame, display: true)
            }
        } completionHandler: { [weak self] in
            self?.isMiniMode = true
        }

        print("🔽 Entered mini mode")
    }

    private func restoreFromMiniMode(_ window: NSWindow) {
        guard let frame = savedFrame else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        } completionHandler: { [weak self] in
            self?.isMiniMode = false
        }

        print("🔼 Restored from mini mode")
    }

    // MARK: - Paste to Previous App

    /// Copies content to clipboard, switches to the previous app, and simulates Cmd+V
    func pasteContentToPreviousApp(_ content: String, removeFromQueue: Bool = false, item: ClipboardItem? = nil) {
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)

        // Store content to avoid re-adding when pasted
        if let item = item, removeFromQueue {
            queueManager?.removeItem(item)
        }

        // Play paste sound effect
        SoundManager.shared.playPasteSound()

        // Switch to the previous app and paste
        if let previousApp = previousActiveApp {
            print("🔀 Switching to: \(previousApp.localizedName ?? "Unknown")")

            // Activate the previous app
            previousApp.activate(options: [])

            // Give the app time to become active before pasting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.simulatePaste()
            }
        } else {
            print("⚠️ No previous app to switch to")
        }
    }

    /// Simulates Cmd+V paste keystroke
    private func simulatePaste() {
        // Check accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permissions not granted!")
            print("   Go to System Settings > Privacy & Security > Accessibility")
            print("   Add ClipQueue and enable it")
            return
        }

        // Create Cmd+V key down event
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down for 'V' (keyCode 0x09) with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)

            // Small delay between key down and key up
            usleep(10000) // 10ms

            // Key up for 'V'
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                keyUp.flags = .maskCommand
                keyUp.post(tap: .cghidEventTap)
            }

            print("⌨️ Simulated Cmd+V to previous app")
        } else {
            print("⚠️ Failed to create paste event")
        }
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
