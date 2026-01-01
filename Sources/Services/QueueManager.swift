import Foundation
import AppKit
import Combine

class QueueManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private let userDefaultsKey = "clipQueueItems"
    private var lastPastedContent: String?
    
    init() {
        loadQueue()
    }
    
    // Add item to the END of the queue (newest)
    // Display order: items[0] = oldest (top), items[last] = newest (bottom)
    func addItem(_ item: ClipboardItem) {
        // Don't add if it's what we just pasted
        if let lastPasted = lastPastedContent, lastPasted == item.content {
            lastPastedContent = nil
            return
        }
        
        // Add to end (newest position) - allow duplicates
        items.append(item)
        
        saveQueue()
    }
    
    // Paste the next item (from the FRONT of the queue - oldest)
    func pasteNext() -> ClipboardItem? {
        guard !items.isEmpty else {
            return nil
        }
        
        // Get the first item (oldest - FIFO)
        let item = items.removeFirst()
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        
        // Remember what we pasted to avoid re-adding it
        lastPastedContent = item.content
        
        saveQueue()
        
        print("✅ Pasted: \(item.shortPreview)")
        
        return item
    }
    
    // Paste all items in order (oldest to newest)
    func pasteAll() {
        guard !items.isEmpty else {
            return
        }
        
        // Concatenate all items with newlines
        let allContent = items.map { $0.content }.joined(separator: "\n")
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(allContent, forType: .string)
        
        // Remember to avoid re-adding
        lastPastedContent = allContent
        
        // Clear the queue
        items.removeAll()
        saveQueue()
        
        print("✅ Pasted all items")
    }
    
    // Remove a specific item
    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveQueue()
    }
    
    // Remove item at specific index
    func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        saveQueue()
    }
    
    // Clear all items
    func clearQueue() {
        items.removeAll()
        saveQueue()
        print("🗑️ Queue cleared")
    }
    
    // Move item from one index to another (for drag & drop)
    func moveItem(from source: Int, to destination: Int) {
        guard source >= 0 && source < items.count &&
              destination >= 0 && destination < items.count else {
            return
        }
        
        let item = items.remove(at: source)
        items.insert(item, at: destination)
        saveQueue()
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }
}
