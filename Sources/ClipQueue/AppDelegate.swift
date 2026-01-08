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
        keyboardShortcutManager?.registerShortcuts()
        
        // Create the status bar item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            updateMenuBarIcon()
        }

        // Create context menu for status bar
        createStatusBarMenu()

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

        // Observe keyboard shortcut changes
        Preferences.shared.$copyAndRecordShortcut.sink { [weak self] _ in
            self?.keyboardShortcutManager?.updateShortcuts()
        }.store(in: &cancellables)

        Preferences.shared.$toggleWindowShortcut.sink { [weak self] _ in
            self?.keyboardShortcutManager?.updateShortcuts()
        }.store(in: &cancellables)

        Preferences.shared.$pasteNextShortcut.sink { [weak self] _ in
            self?.keyboardShortcutManager?.updateShortcuts()
        }.store(in: &cancellables)

        Preferences.shared.$pasteAllShortcut.sink { [weak self] _ in
            self?.keyboardShortcutManager?.updateShortcuts()
        }.store(in: &cancellables)

        Preferences.shared.$clearAllShortcut.sink { [weak self] _ in
            self?.keyboardShortcutManager?.updateShortcuts()
        }.store(in: &cancellables)

        // Observe window sizing related preferences
        Preferences.shared.$autoResizeWindowHeight.sink { [weak self] _ in
            self?.updateQueueWindowHeight()
        }.store(in: &cancellables)

        Preferences.shared.$rowDensity.sink { [weak self] _ in
            self?.updateQueueWindowHeight()
        }.store(in: &cancellables)

        Preferences.shared.$showPreviewLines.sink { [weak self] _ in
            self?.updateQueueWindowHeight()
        }.store(in: &cancellables)

        Preferences.shared.$textSize.sink { [weak self] _ in
            self?.updateQueueWindowHeight()
        }.store(in: &cancellables)

        Preferences.shared.$selectedQueueTab.sink { [weak self] _ in
            self?.updateQueueWindowHeight()
        }.store(in: &cancellables)
    }

    private func updateWindowTranslucency(_ window: NSWindow) {
        let alpha = CGFloat(Preferences.shared.windowTranslucency)
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(alpha)
        window.alphaValue = alpha
    }

    private func updateQueueWindowHeight(for itemsCount: Int? = nil) {
        guard let window = queueWindow else { return }
        guard Preferences.shared.autoResizeWindowHeight else { return }
        guard Preferences.shared.selectedQueueTab == .queue else { return }

        let count = itemsCount ?? queueManager?.items.count ?? 0
        let targetHeight = estimatedQueueWindowHeight(for: count)

        var frame = window.frame
        let newHeight = min(max(targetHeight, window.minSize.height), window.maxSize.height)
        let heightDelta = frame.size.height - newHeight
        if abs(heightDelta) < 1 { return }

        frame.origin.y += heightDelta
        frame.size.height = newHeight
        window.setFrame(frame, display: true, animate: true)
    }

    private func estimatedQueueWindowHeight(for itemCount: Int) -> CGFloat {
        let density = Preferences.shared.rowDensity
        let previewLines = max(1, Preferences.shared.showPreviewLines)
        let textScale = Preferences.shared.textSize.scaleFactor

        let contentFont = NSFont.preferredFont(forTextStyle: .callout).pointSize * textScale
        let metaFont = NSFont.preferredFont(forTextStyle: .caption2).pointSize * textScale

        // Calculate row height components
        let lineHeightMultiplier: CGFloat = 1.2 // Standard line height multiplier
        let contentTextHeight = (contentFont * lineHeightMultiplier) * CGFloat(previewLines)
        let metaLineHeight = metaFont * lineHeightMultiplier
        let rowTextHeight = contentTextHeight + metaLineHeight + density.contentSpacing
        let rowHeight = rowTextHeight + (density.verticalPadding * 2)

        // Row spacing in List
        let rowSpacing: CGFloat = 4

        // Window chrome components
        let headerHeight: CGFloat = 48  // GlassBar with tabs and search
        let footerHeight: CGFloat = 44  // GlassBar with settings and actions
        let scrollViewPadding: CGFloat = 8  // List .padding(8) in QueueView
        let listTopBottomSpace: CGFloat = 8  // Additional List internal spacing

        // Empty state
        if itemCount <= 0 {
            let emptyStateHeight: CGFloat = 120
            return headerHeight + footerHeight + emptyStateHeight
        }

        // Calculate total rows height with spacing
        let totalRowsHeight = (rowHeight * CGFloat(itemCount)) + (rowSpacing * CGFloat(max(0, itemCount - 1)))

        // Add all components with proper accounting for all spacing
        let totalContentHeight = scrollViewPadding + totalRowsHeight + scrollViewPadding + listTopBottomSpace
        let totalHeight = headerHeight + totalContentHeight + footerHeight

        return totalHeight
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
        window.minSize = NSSize(width: 280, height: 200)
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
            onPasteToPreviousApp: { [weak self] content, removeFromQueue, itemIds in
                self?.pasteContentToPreviousApp(content, removeFromQueue: removeFromQueue, itemIds: itemIds)
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
            self?.updateQueueWindowHeight(for: items.count)
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
    
    // MARK: - Status Bar Menu

    private func createStatusBarMenu() {
        let menu = NSMenu()

        // Show Window
        let showItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        // Hide Window
        let hideItem = NSMenuItem(title: "Hide Window", action: #selector(hideWindow), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        menu.addItem(NSMenuItem.separator())

        // Minimize Window
        let minimizeItem = NSMenuItem(title: "Minimize Window", action: #selector(minimizeWindow), keyEquivalent: "")
        minimizeItem.target = self
        menu.addItem(minimizeItem)

        // Maximize Window
        let maximizeItem = NSMenuItem(title: "Maximize Window", action: #selector(maximizeWindow), keyEquivalent: "")
        maximizeItem.target = self
        menu.addItem(maximizeItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(title: "About ClipQueue", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit ClipQueue", action: #selector(quitApplication), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: show menu (menu is set in statusItem, so it will show automatically)
            statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        } else {
            // Left-click: toggle window
            // Remove menu temporarily so left-click doesn't show menu
            let menu = statusItem?.menu
            statusItem?.menu = nil
            toggleWindow()
            // Restore menu after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.statusItem?.menu = menu
            }
        }
    }

    @objc private func showWindow() {
        guard let window = queueWindow else { return }
        if !window.isVisible {
            toggleWindow()
        }
    }

    @objc private func hideWindow() {
        guard let window = queueWindow else { return }
        if window.isVisible {
            toggleWindow()
        }
    }

    @objc private func minimizeWindow() {
        queueWindow?.miniaturize(nil)
    }

    @objc private func maximizeWindow() {
        guard let window = queueWindow else { return }
        window.zoom(nil)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

    // MARK: - Dock Icon Handler

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Toggle window when dock icon is clicked
        toggleWindow()
        return true
    }

    // MARK: - Window Toggle

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
            if Preferences.shared.returnToQueueOnShow {
                Preferences.shared.selectedQueueTab = .queue
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: false)
            if Preferences.shared.pauseMonitoringWhenHidden {
                clipboardMonitor?.startMonitoring()
                keyboardShortcutManager?.setMonitoringEnabled(true)
            }
            print("🪟 Window shown - monitoring active")
        }
    }
    
    @objc func openPreferences() {
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
        guard let button = statusItem?.button else {
            print("⚠️ Menu bar button not available")
            return
        }

        button.title = ""
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown

        let style = Preferences.shared.menuBarIconStyle
        let fallbackImage = configuredSymbolImage(named: "list.clipboard")

        switch style {
        case .default:
            if let image = fallbackImage {
                applyMenuBarIcon(image, to: button)
                print("🎨 Menu bar icon: default (list.clipboard)")
            }

        case .sfSymbol:
            let symbolName = Preferences.shared.customMenuBarSymbol
            if let image = configuredSymbolImage(named: symbolName) {
                applyMenuBarIcon(image, to: button)
                print("🎨 Menu bar icon: SF Symbol (\(symbolName))")
            } else {
                // Fallback to default if symbol not found
                print("⚠️ SF Symbol '\(symbolName)' not found, using default")
                if let image = fallbackImage {
                    applyMenuBarIcon(image, to: button)
                }
            }

        case .custom:
            let imagePath = Preferences.shared.customMenuBarImagePath
            if !imagePath.isEmpty {
                // Try to load from file path
                if let image = NSImage(contentsOfFile: imagePath) {
                    let resizedImage = resizedMenuBarImage(from: image)
                    applyMenuBarIcon(resizedImage, to: button)
                    print("🎨 Menu bar icon: custom image (\(imagePath))")
                } else {
                    // Try loading from URL in case path needs URL handling
                    let url = URL(fileURLWithPath: imagePath)
                    if let image = NSImage(contentsOf: url) {
                        let resizedImage = resizedMenuBarImage(from: image)
                        applyMenuBarIcon(resizedImage, to: button)
                        print("🎨 Menu bar icon: custom image via URL (\(imagePath))")
                    } else {
                        print("⚠️ Failed to load custom image: \(imagePath)")
                        // Fallback to default
                        if let image = fallbackImage {
                            applyMenuBarIcon(image, to: button)
                        }
                    }
                }
            } else {
                print("⚠️ Custom image path is empty, using default")
                // Fallback to default
                if let image = fallbackImage {
                    applyMenuBarIcon(image, to: button)
                }
            }
        }
    }

    private func configuredSymbolImage(named name: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: "ClipQueue") else {
            return nil
        }
        return image.withSymbolConfiguration(config) ?? image
    }

    private func resizedMenuBarImage(from image: NSImage) -> NSImage {
        let targetSize = NSSize(width: 18, height: 18)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver,
                   fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }

    private func applyMenuBarIcon(_ image: NSImage, to button: NSStatusBarButton) {
        image.isTemplate = true
        button.image = image
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
    func pasteContentToPreviousApp(_ content: String, removeFromQueue: Bool = false, itemIds: [UUID] = []) {
        // Prepare content with optional newline
        var pasteContent = content
        if Preferences.shared.appendNewlineAfterPaste, !pasteContent.hasSuffix("\n") {
            pasteContent += "\n"
        }

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pasteContent, forType: .string)

        // Store content to avoid re-adding when pasted
        if removeFromQueue, !itemIds.isEmpty {
            queueManager?.removeItems(ids: itemIds)
        }

        // Mark items as pasted in history
        if !itemIds.isEmpty {
            Task { @MainActor in
                historyStore?.markAsPasted(itemIds: itemIds)
            }
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
