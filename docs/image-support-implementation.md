# Image Support Implementation Guide

This document outlines the step-by-step implementation plan for adding image support to ClipQueue with thumbnails, QuickLook preview, and filepath copying.

## Overview

The feature includes:
1. **Image Detection**: Capture images from clipboard (screenshots, copied images)
2. **Image Storage**: Save images to disk (not UserDefaults due to size limits)
3. **Thumbnail Display**: Show image previews in the queue list
4. **QuickLook Preview**: Press spacebar to open full image in QuickLook
5. **Context Menu**: "Copy Image Filepath" option for image items

---

## Phase 1: Data Model Updates

### 1.1 Update `ClipboardItem.ItemType` enum

**File**: `Sources/Models/ClipboardItem.swift`

Add `.image` case to the `ItemType` enum:

```swift
enum ItemType: String, Codable {
    case text
    case url
    case image  // NEW
    case other
}
```

### 1.2 Add `imagePath` property to `ClipboardItem`

**File**: `Sources/Models/ClipboardItem.swift`

Add an optional `imagePath` property to store the file path of saved images:

```swift
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ItemType
    let sourceAppBundleIdentifier: String?
    let sourceAppName: String?
    let categoryId: UUID?
    let isPinned: Bool
    let imagePath: String?  // NEW - file path for image items

    // Update both initializers to include imagePath parameter
    init(
        content: String,
        type: ItemType = .text,
        sourceAppBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        categoryId: UUID? = nil,
        isPinned: Bool = false,
        imagePath: String? = nil  // NEW
    ) {
        // ... existing init code ...
        self.imagePath = imagePath
    }

    // Update the full initializer similarly
    // Update withCategory() and withPinned() methods to preserve imagePath
}
```

### 1.3 Update `ClipboardHistoryEntry` SwiftData model

**File**: `Sources/Models/ClipboardItem.swift`

Add `imagePath` to the SwiftData model:

```swift
@Model
final class ClipboardHistoryEntry {
    // ... existing properties ...
    var imagePath: String?  // NEW

    // Update init to include imagePath parameter
}
```

---

## Phase 2: Clipboard Monitoring

### 2.1 Add image storage directory

**File**: `Sources/Services/ClipboardMonitor.swift`

Create a directory for storing clipboard images in Application Support:

```swift
import UniformTypeIdentifiers

class ClipboardMonitor {
    private let imageStorageURL: URL

    init(queueManager: QueueManager) {
        // ... existing code ...

        // Create directory for storing clipboard images
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        self.imageStorageURL = appSupport.appendingPathComponent(
            "ClipQueue/Images",
            isDirectory: true
        )
        try? FileManager.default.createDirectory(
            at: imageStorageURL,
            withIntermediateDirectories: true
        )
    }
}
```

### 2.2 Implement image extraction from clipboard

**File**: `Sources/Services/ClipboardMonitor.swift`

Add method to detect and extract image data from the clipboard:

```swift
private func extractImageItem(
    sourceInfo: (bundleIdentifier: String?, name: String?)
) -> ClipboardItem? {
    // Check for various image types in order of preference
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
    if let fileURLs = pasteboard.readObjects(
        forClasses: [NSURL.self],
        options: nil
    ) as? [URL],
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
```

### 2.3 Save image to disk

**File**: `Sources/Services/ClipboardMonitor.swift`

Add method to save image data and create a ClipboardItem:

```swift
private func saveImageAndCreateItem(
    data: Data,
    sourceInfo: (bundleIdentifier: String?, name: String?)
) -> ClipboardItem? {
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
        print("Failed to save clipboard image: \(error.localizedDescription)")
        return nil
    }

    // Create item with image info
    let dimensions = image.size
    let content = "Image: \(Int(dimensions.width))x\(Int(dimensions.height))"

    return ClipboardItem(
        content: content,
        type: .image,
        sourceAppBundleIdentifier: sourceInfo.bundleIdentifier,
        sourceAppName: sourceInfo.name,
        imagePath: fileURL.path
    )
}
```

### 2.4 Update `checkClipboard()` to detect images first

**File**: `Sources/Services/ClipboardMonitor.swift`

Modify `checkClipboard()` to check for images before text:

```swift
private func checkClipboard() {
    let currentChangeCount = pasteboard.changeCount
    guard currentChangeCount != lastChangeCount else { return }
    lastChangeCount = currentChangeCount

    let sourceInfo = currentSourceAppInfo()

    // Check for image content FIRST
    if let imageItem = extractImageItem(sourceInfo: sourceInfo) {
        DispatchQueue.main.async { [weak self] in
            self?.queueManager?.addItem(imageItem)
            SoundManager.shared.playCopySound()
        }
        print("Added image to queue")
        return
    }

    // Fall back to string content
    guard let content = pasteboard.string(forType: .string),
          !content.isEmpty else {
        return
    }

    // ... existing text handling code ...
}
```

---

## Phase 3: UI Updates - Thumbnail Display

### 3.1 Create `ImageThumbnailView` component

**File**: `Sources/Views/QueueView.swift` (or new file `Sources/Views/ImageThumbnailView.swift`)

Create a reusable thumbnail view:

```swift
struct ImageThumbnailView: View {
    let imagePath: String
    let size: CGFloat

    @State private var thumbnail: NSImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        // Load and resize image on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = NSImage(contentsOfFile: imagePath) else { return }

            // Create thumbnail
            let thumbnailSize = NSSize(width: size * 2, height: size * 2) // 2x for retina
            let thumbnail = NSImage(size: thumbnailSize)
            thumbnail.lockFocus()
            image.draw(
                in: NSRect(origin: .zero, size: thumbnailSize),
                from: NSRect(origin: .zero, size: image.size),
                operation: .copy,
                fraction: 1.0
            )
            thumbnail.unlockFocus()

            DispatchQueue.main.async {
                self.thumbnail = thumbnail
            }
        }
    }
}
```

### 3.2 Update `QueueItemRow` to show thumbnails

**File**: `Sources/Views/QueueView.swift`

Modify `QueueItemRow` to conditionally show image thumbnails:

```swift
struct QueueItemRow: View {
    let item: ClipboardItem
    // ... existing properties ...

    var body: some View {
        HStack(alignment: .top, spacing: density.rowSpacing) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: compactMode ? 8 : 10))
                .foregroundColor(.secondary.opacity(0.5))

            if showAppIcon {
                SourceAppIconView(/* ... */)
            }

            // NEW: Show thumbnail for image items
            if item.type == .image, let imagePath = item.imagePath {
                ImageThumbnailView(
                    imagePath: imagePath,
                    size: compactMode ? 32 : 48
                )
            }

            // Content preview
            VStack(alignment: .leading, spacing: density.contentSpacing) {
                if item.type == .image {
                    // Show image info instead of link-detecting text
                    Text(item.shortPreview)
                        .lineLimit(previewLines)
                        .font(compactMode ? .caption : .callout)
                        .foregroundStyle(isOldest ? .primary : .secondary)
                } else {
                    LinkDetectingText(/* ... existing ... */)
                }

                // ... existing metadata row ...
            }

            Spacer()

            // ... existing delete button ...
        }
        // ... rest of view ...
    }

    private var iconName: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"  // NEW
        case .other: return "doc"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .text: return .blue
        case .url: return .green
        case .image: return .purple  // NEW
        case .other: return .gray
        }
    }
}
```

### 3.3 Update `HistoryItemRow` and `PinnedItemRow` similarly

Apply the same thumbnail display logic to history and pinned item rows.

---

## Phase 4: QuickLook Integration

### 4.1 Add QuickLook state to `QueueView`

**File**: `Sources/Views/QueueView.swift`

Add state variables for QuickLook:

```swift
struct QueueView: View {
    // ... existing properties ...
    @State private var quickLookURL: URL?
    @State private var showingQuickLook = false

    var body: some View {
        VStack(spacing: 0) {
            // ... existing content ...
        }
        .quickLookPreview($quickLookURL)  // macOS 13+
        .onKeyPress(.space) {
            handleSpacebarPress()
            return .handled
        }
    }

    private func handleSpacebarPress() {
        // Find the selected item
        guard let selectedID = selectedQueueID,
              let item = queueManager.items.first(where: { $0.id == selectedID }),
              item.type == .image,
              let imagePath = item.imagePath else {
            return
        }

        quickLookURL = URL(fileURLWithPath: imagePath)
    }
}
```

### 4.2 Alternative: Use QLPreviewPanel directly (for older macOS)

For broader compatibility, use `QLPreviewPanel`:

```swift
import QuickLookUI

class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    var url: URL?

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return url != nil ? 1 : 0
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return url as QLPreviewItem?
    }
}

// In QueueView, add:
@State private var quickLookCoordinator = QuickLookCoordinator()

private func showQuickLook(for imagePath: String) {
    quickLookCoordinator.url = URL(fileURLWithPath: imagePath)
    if let panel = QLPreviewPanel.shared() {
        panel.dataSource = quickLookCoordinator
        panel.delegate = quickLookCoordinator
        panel.makeKeyAndOrderFront(nil)
    }
}
```

---

## Phase 5: Context Menu - Copy Filepath

### 5.1 Add "Copy Image Filepath" option

**File**: `Sources/Views/QueueView.swift`

Add conditional context menu item for image items:

```swift
.contextMenu {
    Button("Copy") {
        copyToPasteboard(item.content)
    }

    // NEW: Copy Image Filepath option
    if item.type == .image, let imagePath = item.imagePath {
        Button("Copy Image Filepath") {
            copyToPasteboard(imagePath)
        }
    }

    Button("Paste to Previous App") {
        handlePaste(item: item)
    }

    // ... rest of context menu ...
}
```

### 5.2 Add to history and pinned item context menus as well

Apply the same conditional "Copy Image Filepath" option to `HistoryItemRow` and `PinnedItemRow` context menus.

---

## Phase 6: History Store Updates

### 6.1 Update `HistoryStore.record()` to save imagePath

**File**: `Sources/Services/QueueManager.swift`

Ensure `imagePath` is passed when recording history:

```swift
func record(_ item: ClipboardItem) {
    let entry = ClipboardHistoryEntry(
        id: item.id,
        content: item.content,
        timestamp: item.timestamp,
        typeRaw: item.type.rawValue,
        sourceAppBundleIdentifier: item.sourceAppBundleIdentifier,
        sourceAppName: item.sourceAppName,
        categoryId: item.categoryId,
        isPinned: item.isPinned,
        imagePath: item.imagePath  // NEW - preserve image path
    )
    modelContext.insert(entry)
    // ... rest of method ...
}
```

### 6.2 Update `bootstrap()` similarly

Ensure image paths are preserved when bootstrapping history from queue items.

---

## Phase 7: Image Cleanup (Optional)

### 7.1 Clean up orphaned images

Add a method to clean up image files that are no longer referenced:

```swift
func cleanupOrphanedImages() {
    let fileManager = FileManager.default
    guard let contents = try? fileManager.contentsOfDirectory(
        at: imageStorageURL,
        includingPropertiesForKeys: nil
    ) else { return }

    // Get all referenced image paths from queue and history
    var referencedPaths = Set<String>()
    for item in queueManager.items {
        if let path = item.imagePath {
            referencedPaths.insert(path)
        }
    }
    // Add paths from history store...

    // Remove unreferenced files
    for fileURL in contents {
        if !referencedPaths.contains(fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
```

---

## Testing Checklist

- [ ] Copy a screenshot (Cmd+Shift+4) and verify it appears in queue with thumbnail
- [ ] Copy an image from a web browser and verify detection
- [ ] Copy an image file from Finder and verify path is stored
- [ ] Select image item and press spacebar to verify QuickLook opens
- [ ] Right-click image item and verify "Copy Image Filepath" appears
- [ ] Click "Copy Image Filepath" and verify path is copied to clipboard
- [ ] Verify images persist after app restart (stored in Application Support)
- [ ] Verify history entries include image information
- [ ] Verify thumbnails load correctly for various image formats (PNG, JPEG, HEIC)
- [ ] Verify performance with many images in queue (lazy loading)

---

## File Changes Summary

| File | Changes |
|------|---------|
| `Sources/Models/ClipboardItem.swift` | Add `.image` case, `imagePath` property |
| `Sources/Services/ClipboardMonitor.swift` | Add image detection, extraction, and storage |
| `Sources/Services/QueueManager.swift` | Update `HistoryStore` to save `imagePath` |
| `Sources/Views/QueueView.swift` | Add `ImageThumbnailView`, QuickLook, context menu |

---

## Estimated Implementation Time

| Phase | Effort |
|-------|--------|
| Phase 1: Data Model | 15 min |
| Phase 2: Clipboard Monitoring | 30 min |
| Phase 3: Thumbnail Display | 45 min |
| Phase 4: QuickLook | 30 min |
| Phase 5: Context Menu | 10 min |
| Phase 6: History Store | 10 min |
| Phase 7: Cleanup (optional) | 20 min |
| **Total** | **~2.5-3 hours** |
