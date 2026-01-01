import Foundation
import AppKit
import Carbon
import CoreGraphics

class KeyboardShortcutManager {
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var isMonitoringEnabled = true
    
    weak var queueManager: QueueManager?
    var onToggleWindow: (() -> Void)?
    
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
    
    func registerDefaultShortcuts() {
        // ⌃Q - Copy and record
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_Q),
            modifiers: UInt32(controlKey),
            id: 1
        )
        
        // ⌃⌥⌘C - Toggle window
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(controlKey | optionKey | cmdKey),
            id: 2
        )
        
        // ⌃W - Paste next
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_W),
            modifiers: UInt32(controlKey),
            id: 3
        )
        
        // ⌃E - Paste all
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_E),
            modifiers: UInt32(controlKey),
            id: 4
        )
        
        // ⌃X - Clear all
        registerHotKey(
            keyCode: UInt32(kVK_ANSI_X),
            modifiers: UInt32(controlKey),
            id: 5
        )
        
        // Install event handler
        installEventHandler()
        
        print("⌨️ Keyboard shortcuts registered")
        print("   ⌃Q - Copy and record")
        print("   ⌃⌥⌘C - Toggle window")
        print("   ⌃W - Paste next")
        print("   ⌃E - Paste all")
        print("   ⌃X - Clear all")
    }
    
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
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
        } else {
            print("⚠️ Failed to register hotkey with code \(keyCode)")
        }
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
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        
        print("⌨️ Keyboard shortcuts unregistered")
    }
    
    deinit {
        unregisterAll()
    }
}
