import Foundation
import AppKit
import UniformTypeIdentifiers
import UserNotifications

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private weak var queueManager: QueueManager?
    private var isMonitoring = false
    private let imageStorageURL: URL

    init(queueManager: QueueManager) {
        self.queueManager = queueManager
        self.lastChangeCount = pasteboard.changeCount

        // Create directory for storing clipboard images
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.imageStorageURL = appSupport.appendingPathComponent("ClipQueue/Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageStorageURL, withIntermediateDirectories: true)

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            }
        }
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

        let sourceInfo = currentSourceAppInfo()

        // Check for image content first
        if let imageItem = extractImageItem(sourceInfo: sourceInfo) {
            DispatchQueue.main.async { [weak self] in
                self?.queueManager?.addItem(imageItem)
                SoundManager.shared.playCopySound()
                // Show notification if enabled
                self?.sendCopyNotification(for: imageItem)
            }
            print("📋 Added image to queue")
            return
        }

        // Fall back to string content
        guard let rawContent = pasteboard.string(forType: .string),
              !rawContent.isEmpty else {
            return
        }

        // Process content according to preferences
        var content = rawContent
        if Preferences.shared.trimWhitespace {
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Skip empty content after trimming
        guard !content.isEmpty else { return }

        let item = ClipboardItem(
            content: content,
            type: determineType(content),
            sourceAppBundleIdentifier: sourceInfo.bundleIdentifier,
            sourceAppName: sourceInfo.name
        )
        DispatchQueue.main.async { [weak self] in
            self?.queueManager?.addItem(item)
            // Play copy sound effect
            SoundManager.shared.playCopySound()
            // Show notification if enabled
            self?.sendCopyNotification(for: item)
        }

        print("📋 Added to queue: \(item.shortPreview)")
    }

    private func extractImageItem(sourceInfo: (bundleIdentifier: String?, name: String?)) -> ClipboardItem? {
        // Check for various image types
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .tiff,
            .png,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic")
        ]

        for imageType in imageTypes {
            if let imageData = pasteboard.data(forType: imageType) {
                return saveImageAndCreateItem(data: imageData, sourceInfo: sourceInfo)
            }
        }

        // Check for file URLs that are images
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let fileURL = fileURLs.first,
           fileURL.isFileURL {
            let ext = fileURL.pathExtension.lowercased()
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "heic", "webp", "bmp"]
            if imageExtensions.contains(ext) {
                // It's an image file - store the path directly
                let content = "Image: \(fileURL.lastPathComponent)"
                return ClipboardItem(
                    content: content,
                    type: .image,
                    sourceAppBundleIdentifier: sourceInfo.bundleIdentifier,
                    sourceAppName: sourceInfo.name,
                    imagePath: fileURL.path
                )
            }
        }

        return nil
    }

    private func saveImageAndCreateItem(data: Data, sourceInfo: (bundleIdentifier: String?, name: String?)) -> ClipboardItem? {
        // Generate unique filename
        let filename = "\(UUID().uuidString).png"
        let fileURL = imageStorageURL.appendingPathComponent(filename)

        // Convert to PNG for consistent storage
        guard let image = NSImage(data: data),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: fileURL)
        } catch {
            print("⚠️ Failed to save clipboard image: \(error.localizedDescription)")
            return nil
        }

        // Create item with image info
        let dimensions = image.size
        let content = "Image: \(Int(dimensions.width))×\(Int(dimensions.height))"

        return ClipboardItem(
            content: content,
            type: .image,
            sourceAppBundleIdentifier: sourceInfo.bundleIdentifier,
            sourceAppName: sourceInfo.name,
            imagePath: fileURL.path
        )
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

    private func sendCopyNotification(for item: ClipboardItem) {
        guard Preferences.shared.notifyOnCopy else { return }

        let content = UNMutableNotificationContent()
        content.title = "Copied to Queue"
        content.body = item.shortPreview
        if let appName = item.sourceAppName {
            content.subtitle = "from \(appName)"
        }
        content.sound = nil // We already play a sound effect

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
}
