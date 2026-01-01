import Foundation
import AppKit

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private weak var queueManager: QueueManager?
    private var isMonitoring = false
    
    init(queueManager: QueueManager) {
        self.queueManager = queueManager
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Sync with current clipboard state to avoid picking up old changes
        lastChangeCount = pasteboard.changeCount

        // Check clipboard every 0.5 seconds (common run loop modes)
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        print("📋 Clipboard monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("📋 Clipboard monitoring stopped")
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        // Check if clipboard has changed
        guard currentChangeCount != lastChangeCount else {
            return
        }
        
        lastChangeCount = currentChangeCount
        
        // Try to get string content
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else {
            return
        }
        
        let sourceInfo = currentSourceAppInfo()
        let item = ClipboardItem(
            content: content,
            type: determineType(content),
            sourceAppBundleIdentifier: sourceInfo.bundleIdentifier,
            sourceAppName: sourceInfo.name
        )
        DispatchQueue.main.async { [weak self] in
            self?.queueManager?.addItem(item)
        }
        
        print("📋 Added to queue: \(item.shortPreview)")
    }
    
    private func determineType(_ content: String) -> ClipboardItem.ItemType {
        // Simple URL detection
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        }
        return .text
    }

    private func currentSourceAppInfo() -> (bundleIdentifier: String?, name: String?) {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            return (nil, nil)
        }
        if frontmost.bundleIdentifier == Bundle.main.bundleIdentifier {
            return (nil, nil)
        }
        return (frontmost.bundleIdentifier, frontmost.localizedName)
    }
}
