import Foundation
import AppKit
import Combine
import SwiftData
import Observation

class QueueManager: ObservableObject {
    @Published var items: [ClipboardItem] = [] {
        didSet {
            // Force SwiftUI to notice the change
            updateTrigger += 1
        }
    }
    @Published var undoStack: [ClipboardItem] = []
    @Published var updateTrigger: Int = 0

    private let userDefaultsKey = "clipQueueItems"
    private var lastPastedContent: String?
    private let historyStore: HistoryStore?
    
    init(historyStore: HistoryStore? = nil) {
        self.historyStore = historyStore
        loadQueue()
        if let historyStore {
            let currentItems = items
            Task { @MainActor in
                historyStore.bootstrap(with: currentItems)
            }
        }
    }
    
    // Add item to the END of the queue (newest)
    // Display order: items[0] = oldest (top), items[last] = newest (bottom)
    func addItem(_ item: ClipboardItem) {
        // Don't add if it's what we just pasted
        if let lastPasted = lastPastedContent, lastPasted == item.content {
            lastPastedContent = nil
            return
        }

        // Skip duplicates if preference is enabled
        if Preferences.shared.skipDuplicates {
            if items.contains(where: { $0.content == item.content }) {
                print("⏭️ Skipped duplicate item: \(item.shortPreview)")
                return
            }
        }

        // Create new array and assign to trigger SwiftUI update
        var newItems = items
        newItems.append(item)

        // Enforce max queue size limit
        let maxSize = Preferences.shared.maxQueueSize
        while newItems.count > maxSize {
            newItems.removeFirst()
        }

        // Assign new array to trigger @Published change
        items = newItems

        recordHistory(item)
        saveQueue()
    }
    
    // Paste the next item (from the FRONT of the queue - oldest)
    func pasteNext() -> ClipboardItem? {
        guard !items.isEmpty else {
            return nil
        }

        // Get the first item (oldest - FIFO)
        let item = items.first!

        // Create new array without the first item
        items = Array(items.dropFirst())

        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)

        // Remember what we pasted to avoid re-adding it
        lastPastedContent = item.content

        saveQueue()

        // Play paste sound effect
        SoundManager.shared.playPasteSound()

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

        // Clear the queue by assigning empty array
        items = []
        saveQueue()

        // Play paste sound effect
        SoundManager.shared.playPasteSound()

        print("✅ Pasted all items")
    }
    
    // Remove a specific item
    func removeItem(_ item: ClipboardItem) {
        items = items.filter { $0.id != item.id }
        saveQueue()
    }

    func removeItems(ids: [UUID], saveToUndo: Bool = false) {
        guard !ids.isEmpty else { return }

        // Save removed items to undo stack if requested (e.g., for paste operations)
        if saveToUndo {
            let removedItems = items.filter { ids.contains($0.id) }
            undoStack = removedItems  // Replace undo stack with latest removed items
        }

        items = items.filter { !ids.contains($0.id) }
        saveQueue()
    }

    // Restore items from undo stack back to the queue
    func undoLastPaste() {
        guard !undoStack.isEmpty else { return }

        let restoredCount = undoStack.count

        // Add items back to the queue in their original order
        items = items + undoStack

        // Record items in history
        for item in undoStack {
            recordHistory(item)
        }

        // Clear the undo stack
        undoStack = []

        saveQueue()

        print("↩️ Restored \(restoredCount) item(s) from undo")
    }

    func updateCategory(for item: ClipboardItem, categoryId: UUID?) {
        let updated = item.withCategory(categoryId)
        updateItem(updated)
    }

    func updatePinned(for item: ClipboardItem, pinned: Bool) {
        let updated = item.withPinned(pinned)
        updateItem(updated)
    }

    func updateFavorite(for item: ClipboardItem, favorite: Bool) {
        let updated = item.withFavorite(favorite)
        updateItem(updated)
    }
    
    // Remove item at specific index
    func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        var newItems = items
        newItems.remove(at: index)
        items = newItems
        saveQueue()
    }

    // Clear all items
    func clearQueue() {
        items = []
        saveQueue()
        print("🗑️ Queue cleared")
    }
    
    // Move item from one index to another (for drag & drop)
    func moveItem(from source: Int, to destination: Int) {
        guard source >= 0 && source < items.count &&
              destination >= 0 && destination < items.count else {
            return
        }

        var newItems = items
        let item = newItems.remove(at: source)
        newItems.insert(item, at: destination)
        items = newItems
        saveQueue()
    }

    // Move item to the top of the queue (first position)
    func moveToTop(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index > 0 else { return }
        var newItems = items
        let moved = newItems.remove(at: index)
        newItems.insert(moved, at: 0)
        items = newItems
        saveQueue()
    }

    // Reverse the order of all items in the queue
    func reverseQueue() {
        guard items.count > 1 else { return }
        items = items.reversed()
        saveQueue()
        print("🔄 Queue order reversed")
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

    private func updateItem(_ updated: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return }
        var newItems = items
        newItems[index] = updated
        items = newItems
        saveQueue()
    }

    private func recordHistory(_ item: ClipboardItem) {
        guard Preferences.shared.historyEnabled else { return }
        guard let historyStore = historyStore else { return }
        Task { @MainActor in
            historyStore.record(item)
        }
    }
}

@MainActor
@Observable
final class HistoryStore {
    // NOTE(claude-code): If you move the queue to SwiftData, merge this paging logic with queue persistence.
    private let modelContext: ModelContext
    private let pageSize: Int
    private(set) var items: [ClipboardHistoryEntry] = []
    private(set) var pinnedItems: [ClipboardHistoryEntry] = []
    private(set) var favoriteItems: [ClipboardHistoryEntry] = []
    private(set) var canLoadMore = true
    private var loadedCount = 0
    private var searchQuery = ""
    private var searchTask: Task<Void, Never>?

    init(modelContext: ModelContext, pageSize: Int = 200) {
        self.modelContext = modelContext
        self.pageSize = pageSize
        loadInitial()
        loadPinned()
        loadFavorites()
    }

    func bootstrap(with queueItems: [ClipboardItem]) {
        guard items.isEmpty, !queueItems.isEmpty else { return }
        for item in queueItems {
            let entry = ClipboardHistoryEntry(
                id: item.id,
                content: item.content,
                timestamp: item.timestamp,
                typeRaw: item.type.rawValue,
                sourceAppBundleIdentifier: item.sourceAppBundleIdentifier,
                sourceAppName: item.sourceAppName,
                categoryId: item.categoryId,
                isPinned: item.isPinned,
                isFavorite: item.isFavorite
            )
            modelContext.insert(entry)
        }
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to bootstrap history: \(error.localizedDescription)")
        }
        loadInitial()
    }

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
            isFavorite: item.isFavorite
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save history entry: \(error.localizedDescription)")
            return
        }

        items.insert(entry, at: 0)
        loadedCount += 1
        if entry.isPinned {
            pinnedItems.insert(entry, at: 0)
        }
        if entry.isFavorite {
            favoriteItems.insert(entry, at: 0)
        }
    }

    func loadInitial() {
        loadedCount = 0
        pruneOldEntries()
        items = fetchEntries(offset: loadedCount, limit: pageSize)
        loadedCount = items.count
        canLoadMore = items.count == pageSize
    }

    private func pruneOldEntries() {
        let retentionDays = Preferences.shared.historyRetentionDays
        guard retentionDays > 0 else { return } // 0 means keep forever

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let batchSize = 500
        var totalPruned = 0

        // Loop to handle very large backlogs efficiently
        while true {
            var descriptor = FetchDescriptor<ClipboardHistoryEntry>(
                predicate: #Predicate { entry in
                    entry.timestamp < cutoffDate && entry.isPinned == false
                }
            )
            descriptor.fetchLimit = batchSize

            do {
                let oldEntries = try modelContext.fetch(descriptor)
                guard !oldEntries.isEmpty else { break }

                for entry in oldEntries {
                    modelContext.delete(entry)
                }
                try modelContext.save()
                totalPruned += oldEntries.count

                // If we got less than a full batch, we're done
                if oldEntries.count < batchSize { break }
            } catch {
                print("⚠️ Failed to prune old history: \(error.localizedDescription)")
                break
            }
        }

        if totalPruned > 0 {
            print("🗑️ Pruned \(totalPruned) history entries older than \(retentionDays) days")
        }
    }

    func loadMore() {
        guard canLoadMore else { return }
        let next = fetchEntries(offset: loadedCount, limit: pageSize)
        items.append(contentsOf: next)
        loadedCount += next.count
        canLoadMore = next.count == pageSize
    }

    func loadPinned() {
        var descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        if let fetched = try? modelContext.fetch(descriptor) {
            pinnedItems = fetched
        }
    }

    func loadFavorites() {
        var descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        if let fetched = try? modelContext.fetch(descriptor) {
            favoriteItems = fetched
        }
    }

    private func fetchEntries(offset: Int, limit: Int) -> [ClipboardHistoryEntry] {
        let query = searchQuery
        var descriptor: FetchDescriptor<ClipboardHistoryEntry>
        if query.isEmpty {
            descriptor = FetchDescriptor<ClipboardHistoryEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<ClipboardHistoryEntry>(
                predicate: #Predicate { entry in
                    entry.content.localizedStandardContains(query)
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        }
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("⚠️ Failed to fetch history: \(error.localizedDescription)")
            canLoadMore = false
            return []
        }
    }

    func updateSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != searchQuery else { return }
        searchQuery = trimmed
        debounceReload()
    }

    private func debounceReload() {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            loadInitial()
        }
    }

    func remove(_ entry: ClipboardHistoryEntry) {
        modelContext.delete(entry)
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to delete history entry: \(error.localizedDescription)")
            return
        }
        items.removeAll { $0.id == entry.id }
        pinnedItems.removeAll { $0.id == entry.id }
        favoriteItems.removeAll { $0.id == entry.id }
        loadedCount = max(0, loadedCount - 1)
    }

    func clearAll() {
        while true {
            var descriptor = FetchDescriptor<ClipboardHistoryEntry>()
            descriptor.fetchLimit = pageSize
            guard let batch = try? modelContext.fetch(descriptor), !batch.isEmpty else {
                break
            }
            for entry in batch {
                modelContext.delete(entry)
            }
            do {
                try modelContext.save()
            } catch {
                print("⚠️ Failed to clear history: \(error.localizedDescription)")
                break
            }
        }
        items.removeAll()
        pinnedItems.removeAll()
        favoriteItems.removeAll()
        loadedCount = 0
        canLoadMore = false
    }

    func setPinned(itemId: UUID, pinned: Bool) {
        guard let entry = fetchEntry(id: itemId) else { return }
        entry.isPinned = pinned
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to update pinned state: \(error.localizedDescription)")
            return
        }
        if pinned {
            if !pinnedItems.contains(where: { $0.id == entry.id }) {
                pinnedItems.insert(entry, at: 0)
            }
        } else {
            pinnedItems.removeAll { $0.id == entry.id }
        }
        items = items
    }

    func setFavorite(itemId: UUID, favorite: Bool) {
        guard let entry = fetchEntry(id: itemId) else { return }
        entry.isFavorite = favorite
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to update favorite state: \(error.localizedDescription)")
            return
        }
        if favorite {
            if !favoriteItems.contains(where: { $0.id == entry.id }) {
                favoriteItems.insert(entry, at: 0)
            }
        } else {
            favoriteItems.removeAll { $0.id == entry.id }
        }
        items = items
    }

    func setCategory(itemId: UUID, categoryId: UUID?) {
        guard let entry = fetchEntry(id: itemId) else { return }
        entry.categoryId = categoryId
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to update category: \(error.localizedDescription)")
        }
        items = items
    }

    func markAsPasted(itemIds: [UUID]) {
        let now = Date()
        for itemId in itemIds {
            guard let entry = fetchEntry(id: itemId) else { continue }
            entry.lastPastedDate = now
        }
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to mark items as pasted: \(error.localizedDescription)")
        }
    }

    var recentlyPastedItems: [ClipboardHistoryEntry] {
        var descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            predicate: #Predicate { entry in
                entry.lastPastedDate != nil
            },
            sortBy: [SortDescriptor(\.lastPastedDate, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("⚠️ Failed to fetch recently pasted items: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchEntry(id: UUID) -> ClipboardHistoryEntry? {
        var descriptor = FetchDescriptor<ClipboardHistoryEntry>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }
}
