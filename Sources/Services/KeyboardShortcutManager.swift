import Foundation
import AppKit
import Carbon
import CoreGraphics

class KeyboardShortcutManager {
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var isMonitoringEnabled = true
    private var fallbackShortcuts: [UInt32: KeyboardShortcut] = [:]
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    
    weak var queueManager: QueueManager?
    var onToggleWindow: (() -> Void)?
    var onToggleMiniMode: (() -> Void)?
    
    init(queueManager: QueueManager) {
        self.queueManager = queueManager
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ ========================================")
            print("⚠️ ACCESSIBILITY PERMISSIONS NOT GRANTED")
            print("⚠️ ========================================")
            print("⚠️ Shortcuts are registered but cannot simulate keypresses")
            print("⚠️ ")
            print("⚠️ To fix:")
            print("⚠️ 1. Open System Settings")
            print("⚠️ 2. Go to Privacy & Security > Accessibility")
            print("⚠️ 3. Remove any old ClipQueue entries")
            print("⚠️ 4. Add ClipQueue from ~/Applications/ClipQueue.app")
            print("⚠️ 5. Toggle it ON")
            print("⚠️ ========================================")
            
            // Try to prompt for permissions
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            let _ = AXIsProcessTrustedWithOptions(options)
        } else {
            print("✅ Accessibility permissions granted")
        }
    }
    
    func registerShortcuts(from preferences: Preferences = .shared) {
        fallbackShortcuts.removeAll()
        registerHotKey(shortcut: preferences.copyAndRecordShortcut, id: 1)
        registerHotKey(shortcut: preferences.toggleWindowShortcut, id: 2)
        registerHotKey(shortcut: preferences.pasteNextShortcut, id: 3)
        registerHotKey(shortcut: preferences.pasteAllShortcut, id: 4)
        registerHotKey(shortcut: preferences.clearAllShortcut, id: 5)

        // Mini mode keeps its legacy shortcut for now
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_M),
            modifiers: UInt32(controlKey | optionKey),
            id: 6
        )

        installEventHandler()
        installEventTapIfNeeded()
        if fallbackShortcuts.isEmpty {
            removeEventTap()
        }

        print("⌨️ Keyboard shortcuts registered")
        print("   \(preferences.copyAndRecordShortcut.displayString) - Copy and record")
        print("   \(preferences.toggleWindowShortcut.displayString) - Toggle window")
        print("   \(preferences.pasteNextShortcut.displayString) - Paste next")
        print("   \(preferences.pasteAllShortcut.displayString) - Paste all")
        print("   \(preferences.clearAllShortcut.displayString) - Clear all")
        print("   ⌃⌥M - Toggle mini mode")
    }

    func updateShortcuts(from preferences: Preferences = .shared) {
        unregisterAll()
        registerShortcuts(from: preferences)
    }
    
    private func registerHotKey(shortcut: KeyboardShortcut, id: UInt32) {
        let flags = shortcut.modifierFlags
        if requiresEventTap(for: flags) {
            fallbackShortcuts[id] = shortcut
            return
        }

        let success = registerHotKey(
            keyCode: UInt32(shortcut.keyCode),
            modifiers: carbonModifiers(from: flags),
            id: id
        )

        if !success {
            fallbackShortcuts[id] = shortcut
        }
    }

    @discardableResult
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: UInt32) -> Bool {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B455920), id: id) // 'KEY '
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
            return true
        } else {
            print("⚠️ Failed to register hotkey with code \(keyCode) modifiers \(modifiers)")
            return false
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }

    private func requiresEventTap(for flags: NSEvent.ModifierFlags) -> Bool {
        let primary: NSEvent.ModifierFlags = [.command, .control, .option]
        return flags.intersection(primary).isEmpty
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let callback: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr {
                manager.handleHotKey(id: hotKeyID.id)
            }
            
            return noErr
        }
        
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            pointer,
            &eventHandler
        )
    }
    
    func setMonitoringEnabled(_ enabled: Bool) {
        isMonitoringEnabled = enabled
        print("⌨️ Monitoring \(enabled ? "enabled" : "disabled")")
    }
    
    private func handleHotKey(id: UInt32) {
        // Always allow toggle window (case 2)
        if id == 2 {
            onToggleWindow?()
            print("⌨️ Toggle window")
            return
        }
        
        // Check if monitoring is enabled for other shortcuts
        guard isMonitoringEnabled else {
            print("⌨️ Shortcut ignored (window hidden)")
            return
        }
        
        switch id {
        case 1:
            // ⌃Q - Copy and record
            simulateCopy()
            print("⌨️ Copy and record")
            
        case 3:
            // ⌃W - Paste next
            if let item = queueManager?.pasteNext() {
                print("⌨️ Pasted next: \(item.shortPreview)")
                // Simulate Cmd+V to actually paste
                simulatePaste()
            } else {
                print("⌨️ Queue is empty")
            }
            
        case 4:
            // ⌃E - Paste all
            queueManager?.pasteAll()
            print("⌨️ Pasted all items")
            // Simulate Cmd+V to actually paste
            simulatePaste()
            
        case 5:
            // ⌃X - Clear all
            queueManager?.clearQueue()
            print("⌨️ Cleared queue")

        case 6:
            // ⌃M - Toggle mini mode
            onToggleMiniMode?()
            print("⌨️ Toggle mini mode")

        default:
            break
        }
    }
    
    // Simulate Cmd+C copy
    private func simulateCopy() {
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permissions not granted!")
            return
        }
        
        // Simulate Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down for 'C' with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            
            usleep(10000) // 10ms
            
            // Key up for 'C'
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) {
                keyUp.flags = .maskCommand
                keyUp.post(tap: .cghidEventTap)
            }
            
            print("⌨️ Simulated Cmd+C")
        }
    }
    
    // Simulate Cmd+V paste
    private func simulatePaste() {
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permissions not granted!")
            print("   Go to System Settings > Privacy & Security > Accessibility")
            print("   Add ClipQueue and enable it")
            return
        }
        
        // Small delay to ensure clipboard is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Create Cmd+V key down event
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Key down for 'V' with Command modifier
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
                
                print("⌨️ Simulated Cmd+V")
            } else {
                print("⚠️ Failed to create paste event")
            }
        }
    }
    
    func unregisterAll() {
        for hotKeyRef in hotKeyRefs {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
        fallbackShortcuts.removeAll()
        removeEventTap()
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        
        print("⌨️ Keyboard shortcuts unregistered")
    }
    
    deinit {
        unregisterAll()
    }

    // MARK: - Event Tap Fallback (no command/option/control modifiers)

    private func installEventTapIfNeeded() {
        guard eventTap == nil else { return }
        guard !fallbackShortcuts.isEmpty else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard type == .keyDown, let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<KeyboardShortcutManager>
                .fromOpaque(userInfo)
                .takeUnretainedValue()
            let handled = manager.handleEventTap(event)
            return handled ? nil : Unmanaged.passUnretained(event)
        }

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: pointer
        )

        guard let eventTap else {
            print("⚠️ Failed to install event tap for fallback shortcuts")
            return
        }

        eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let eventTapSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("⌨️ Event tap installed for fallback shortcuts")
    }

    private func removeEventTap() {
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        eventTapSource = nil
        eventTap = nil
    }

    private func handleEventTap(_ event: CGEvent) -> Bool {
        if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
            return false
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
            .intersection(.deviceIndependentFlagsMask)

        for (id, shortcut) in fallbackShortcuts {
            if shortcut.keyCode == keyCode && shortcut.modifierFlags == flags {
                if id != 2 && !isMonitoringEnabled {
                    return false
                }
                handleHotKey(id: id)
                return true
            }
        }

        return false
    }
}
