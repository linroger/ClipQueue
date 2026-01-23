import SwiftUI
import AppKit

struct QueueView: View {
    @ObservedObject var queueManager: QueueManager
    let historyStore: HistoryStore?
    let categoryStore: CategoryStore?
    var onOpenPreferences: (() -> Void)?
    /// Callback to paste content to the previous app
    var onPasteToPreviousApp: ((String, Bool, [UUID]) -> Void)?
    @State private var selectedQueueIDs: Set<UUID> = []
    @State private var selectionOrder: [UUID] = []
    @State private var selectionIntent: SelectionIntent?
    @State private var searchText = ""
    @State private var quickLookItem: ClipboardItem?
    @ObservedObject private var preferences = Preferences.shared
    
    var body: some View {
        VStack(spacing: 0) {
            header

            switch preferences.selectedQueueTab {
            case .queue:
                queueList
            case .favorites:
                favoritesView
            case .history:
                HistoryView(historyStore: historyStore, categoryStore: categoryStore, showAppIcon: preferences.showAppIcons, searchText: searchText)
            case .recents:
                recentsView
            }
            footer
        }
        .background(
            KeyEventMonitor(isEnabled: true) { event in
                handleKeyPress(event)
            }
        )
        .background(
            Group {
                if preferences.useVibrancy {
                    Rectangle()
                        .fill(.regularMaterial)
                        .opacity(preferences.windowTranslucency)
                } else {
                    Color(NSColor.windowBackgroundColor)
                        .opacity(preferences.windowTranslucency)
                }
            }
        )
        .sheet(item: $quickLookItem) { item in
            QuickLookPreview(item: item)
        }
    }

    private var header: some View {
        GlassBar(edge: .bottom) {
            HStack(spacing: 8) {
                Picker("", selection: selectedTabBinding) {
                    ForEach(topTabs) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(minWidth: usesSplitPickers ? 120 : 160, maxWidth: usesSplitPickers ? 200 : 320)
                .controlSize(.small)
                .layoutPriority(1)

                Spacer(minLength: 8)

                GlassSearchField(text: $searchText)
                    .frame(minWidth: 100, maxWidth: 220)
                    .onChange(of: searchText) { _, newValue in
                        historyStore?.updateSearch(newValue)
                    }
            }
        }
        .onAppear {
            ensureSelectedTabIsVisible()
        }
        .onChange(of: preferences.showHistoryTab) { _, _ in
            ensureSelectedTabIsVisible()
        }
        .onChange(of: preferences.showFavoritesTab) { _, _ in
            ensureSelectedTabIsVisible()
        }
        .onChange(of: preferences.showRecentsTab) { _, _ in
            ensureSelectedTabIsVisible()
        }
    }

    private var queueList: some View {
        Group {
            if queueManager.items.isEmpty && !hasPinnedItems {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        "Queue is empty",
                        systemImage: "tray",
                        description: Text("Copy something to get started.")
                    )
                    Spacer()
                }
            } else {
                List(selection: $selectedQueueIDs) {
                    if let historyStore, hasPinnedItems {
                        pinnedSection(historyStore: historyStore, query: searchText)
                    }
                    ForEach(filteredQueueItems) { item in
                        QueueItemRow(
                            item: item,
                            isOldest: item.id == queueManager.items.first?.id,
                            isSelected: selectedQueueIDs.contains(item.id),
                            category: categoryStore?.category(for: item.categoryId),
                            showAppIcon: preferences.showAppIcons,
                            compactMode: preferences.compactMode,
                            previewLines: preferences.showPreviewLines,
                            queueManager: queueManager
                        )
                        .tag(item.id)
                        .contentShape(Rectangle())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture(count: 2) {
                            handleDoubleClick(item: item)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            recordSelectionIntent(for: item)
                        })
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(item.content)
                            }
                            Button("Paste to Previous App") {
                                handlePaste(item: item)
                            }
                            Button("Paste & Remove") {
                                handlePasteAndRemove(item: item)
                            }

                            let itemIndex = queueManager.items.firstIndex(where: { $0.id == item.id })
                            if let idx = itemIndex, idx + 1 < queueManager.items.count {
                                Button("Paste Next Item") {
                                    handlePasteNext(from: item)
                                }
                            }
                            if let idx = itemIndex, idx > 0 {
                                Button("Paste Previous Item") {
                                    handlePastePrevious(from: item)
                                }
                            }

                            Divider()

                            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                                toggleFavorite(item: item)
                            }

                            Divider()

                            Button("Copy & Remove") {
                                copyToPasteboard(item.content)
                                queueManager.removeItem(item)
                            }

                            Divider()

                            if queueManager.items.first?.id != item.id {
                                Button("Move to Top") {
                                    queueManager.moveToTop(item)
                                }
                            }

                            if let historyStore {
                                Button(item.isPinned ? "Unpin" : "Pin") {
                                    historyStore.setPinned(itemId: item.id, pinned: !item.isPinned)
                                    queueManager.updatePinned(for: item, pinned: !item.isPinned)
                                    if !item.isPinned {
                                        queueManager.removeItem(item)
                                    }
                                }
                            }
                            categoryMenu(for: item)

                            Divider()

                            Button("Remove", role: .destructive) {
                                queueManager.removeItem(item)
                            }
                        }
                        .onDrag {
                            draggedItem = item

                            NSCursor.pop()
                            NSCursor.closedHand.set()

                            // Check if multiple items are selected
                            if selectedQueueIDs.count > 1 && selectedQueueIDs.contains(item.id) {
                                // Drag all selected items (joined with newlines)
                                let orderedContent = selectionOrder.isEmpty
                                    ? queueManager.items.filter { selectedQueueIDs.contains($0.id) }.map(\.content)
                                    : selectionOrder.compactMap { id in queueManager.items.first { $0.id == id }?.content }
                                let joinedContent = orderedContent.joined(separator: "\n")
                                print("🎯 Dragging \(selectedQueueIDs.count) items")
                                let itemProvider = NSItemProvider(object: joinedContent as NSString)
                                itemProvider.suggestedName = "ClipQueue Items (\(selectedQueueIDs.count))"
                                return itemProvider
                            } else {
                                // Drag single item
                                print("🎯 Dragging: \(item.shortPreview)")
                                let itemProvider = NSItemProvider(object: item.content as NSString)
                                itemProvider.suggestedName = "ClipQueue Item"
                                return itemProvider
                            }
                        }
                        .onDrop(of: [.text], delegate: DropViewDelegate(
                            item: item,
                            items: $queueManager.items,
                            queueManager: queueManager,
                            animationSpeed: preferences.animationSpeed
                        ))
                    }
                }
                .listStyle(.plain)
                .id(queueManager.updateTrigger) // Force List to update when items change
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contextMenu {
                    Button("Clear Queue") {
                        confirmAndClearQueue()
                    }
                }
                .onChange(of: selectedQueueIDs) { oldValue, newValue in
                    Task { @MainActor in
                        updateSelectionOrder(previous: oldValue, current: newValue)
                    }
                }
                .onChange(of: queueManager.items) { _, newItems in
                    Task { @MainActor in
                        syncSelection(with: newItems)
                    }
                }
            }
        }
    }

    private var favoritesView: some View {
        FavoritesView(
            historyStore: historyStore,
            queueManager: queueManager,
            categoryStore: categoryStore,
            showAppIcon: preferences.showAppIcons,
            searchText: searchText
        )
    }

    private var recentsView: some View {
        RecentsView(
            historyStore: historyStore,
            categoryStore: categoryStore,
            showAppIcon: preferences.showAppIcons,
            searchText: searchText
        )
    }

    private var footer: some View {
        GlassBar(edge: .top) {
            HStack(spacing: 8) {
                Button {
                    print("⚙️ Gear button clicked!")
                    onOpenPreferences?()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .font(.system(size: preferences.compactMode ? 12 : 14))
                }
                .buttonStyle(.borderless)
                .help("Settings")

                Spacer()

                if usesSplitPickers {
                    Picker("", selection: selectedTabBinding) {
                        ForEach(bottomTabs) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(minWidth: 140, maxWidth: 200)
                    .controlSize(.small)
                }

                Spacer()

                if preferences.selectedQueueTab == .queue {
                    // Undo button (restore last pasted items)
                    Button {
                        queueManager.undoLastPaste()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(.secondary)
                            .font(.system(size: preferences.compactMode ? 12 : 14))
                    }
                    .buttonStyle(.borderless)
                    .disabled(queueManager.undoStack.isEmpty)
                    .help("Undo last paste (restore removed items)")

                    // Reverse queue button
                    Button {
                        queueManager.reverseQueue()
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.secondary)
                            .font(.system(size: preferences.compactMode ? 12 : 14))
                    }
                    .buttonStyle(.borderless)
                    .disabled(queueManager.items.count < 2)
                    .help("Reverse queue order")

                    Button {
                        confirmAndClearQueue()
                    } label: {
                        Text("Clear")
                            .font(preferences.compactMode ? .caption : .body)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .disabled(queueManager.items.isEmpty)
                    .help("Clear all items (⌃X)")
                }
            }
        }
    }

    private var filteredQueueItems: [ClipboardItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return queueManager.items }
        return queueManager.items.filter { item in
            item.content.localizedCaseInsensitiveContains(query)
        }
    }

    private var hasPinnedItems: Bool {
        historyStore?.pinnedItems.isEmpty == false
    }

    private var selectedTabBinding: Binding<QueueTab> {
        Binding(
            get: { preferences.selectedQueueTab },
            set: { preferences.selectedQueueTab = $0 }
        )
    }

    private var visibleTabs: [QueueTab] {
        var tabs: [QueueTab] = [.queue]
        if preferences.showFavoritesTab { tabs.append(.favorites) }
        if preferences.showHistoryTab { tabs.append(.history) }
        if preferences.showRecentsTab { tabs.append(.recents) }
        return tabs
    }

    private var usesSplitPickers: Bool {
        visibleTabs.count == 4
    }

    private var topTabs: [QueueTab] {
        usesSplitPickers ? [.queue, .favorites].filter { visibleTabs.contains($0) } : visibleTabs
    }

    private var bottomTabs: [QueueTab] {
        usesSplitPickers ? [.history, .recents].filter { visibleTabs.contains($0) } : []
    }

    // MARK: - Click Actions

    private func handleDoubleClick(item: ClipboardItem) {
        switch preferences.doubleClickAction {
        case .copy:
            copyToPasteboard(item.content)
        case .paste:
            handlePaste(item: item)
        case .none:
            break
        }
    }

    private func handlePaste(item: ClipboardItem, forceRemove: Bool = false) {
        // If forceRemove is true, always remove. Otherwise, use the preference setting.
        let shouldRemove = forceRemove || preferences.autoClearAfterPaste
        onPasteToPreviousApp?(item.content, shouldRemove, [item.id])
    }

    private func handlePasteAndRemove(item: ClipboardItem) {
        // Explicitly remove the item after pasting
        onPasteToPreviousApp?(item.content, true, [item.id])
    }

    private func handlePasteNext(from item: ClipboardItem) {
        // Find the item after the current one and paste it
        guard let index = queueManager.items.firstIndex(where: { $0.id == item.id }),
              index + 1 < queueManager.items.count else { return }
        let nextItem = queueManager.items[index + 1]
        handlePaste(item: nextItem)
    }

    private func handlePastePrevious(from item: ClipboardItem) {
        // Find the item before the current one and paste it
        guard let index = queueManager.items.firstIndex(where: { $0.id == item.id }),
              index > 0 else { return }
        let prevItem = queueManager.items[index - 1]
        handlePaste(item: prevItem)
    }

    private func handleKeyPress(_ event: NSEvent) -> Bool {
        guard !shouldIgnoreKeyEvent() else { return false }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if event.keyCode == 48 && flags.contains(.control) {
            let forward = !flags.contains(.shift)
            navigateTabs(forward: forward)
            return true
        }

        guard preferences.selectedQueueTab == .queue else { return false }

        if event.keyCode == 51 || event.keyCode == 117 {
            deleteSelection()
            return true
        }

        if event.keyCode == 49 {
            showQuickLookForSelection()
            return true
        }

        if event.keyCode == 13 && flags.contains(.control) {
            pasteSelection(trigger: .controlW)
            return true
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            let trigger: QueuePasteTrigger = flags.contains(.shift) ? .shiftEnter : .enter
            pasteSelection(trigger: trigger)
            return true
        }

        return false
    }

    private func shouldIgnoreKeyEvent() -> Bool {
        if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView {
            return true
        }
        return false
    }

    private func deleteSelection() {
        let ids = Array(selectedQueueIDs)
        guard !ids.isEmpty else { return }
        queueManager.removeItems(ids: ids)
        selectedQueueIDs.removeAll()
        selectionOrder.removeAll()
    }

    private func showQuickLookForSelection() {
        guard selectedQueueIDs.count == 1,
              let id = selectedQueueIDs.first,
              let item = queueManager.items.first(where: { $0.id == id }) else {
            return
        }
        quickLookItem = item
    }

    private func navigateTabs(forward: Bool) {
        let tabs = visibleTabs
        guard let currentIndex = tabs.firstIndex(of: preferences.selectedQueueTab) else {
            preferences.selectedQueueTab = .queue
            return
        }
        let nextIndex = forward
            ? (currentIndex + 1) % tabs.count
            : (currentIndex - 1 + tabs.count) % tabs.count
        preferences.selectedQueueTab = tabs[nextIndex]
    }

    private func pasteSelection(trigger: QueuePasteTrigger) {
        let orderedIds = selectionOrder.isEmpty
            ? queueManager.items.map(\.id).filter { selectedQueueIDs.contains($0) }
            : selectionOrder
        let selectedItems = orderedIds.compactMap { id in
            queueManager.items.first(where: { $0.id == id })
        }
        guard !selectedItems.isEmpty else { return }

        let appendTrailingNewline: Bool
        let separator: String
        if selectedItems.count > 1 {
            separator = trigger == .controlW ? "" : "\n"
            appendTrailingNewline = trigger == .enter || trigger == .shiftEnter
        } else {
            separator = ""
            appendTrailingNewline = shouldAppendTrailingNewline(for: trigger)
        }

        pasteItems(selectedItems, separator: separator, appendTrailingNewline: appendTrailingNewline)
    }

    private func shouldAppendTrailingNewline(for trigger: QueuePasteTrigger) -> Bool {
        switch preferences.queuePasteNewlineTrigger {
        case .enter:
            return trigger == .enter
        case .shiftEnter:
            return trigger == .shiftEnter
        case .none:
            return false
        }
    }

    private func pasteItems(_ items: [ClipboardItem], separator: String, appendTrailingNewline: Bool) {
        let joined = items.map { $0.content }.joined(separator: separator)
        let content = appendTrailingNewline ? "\(joined)\n" : joined
        let shouldRemove = preferences.autoClearAfterPaste
        onPasteToPreviousApp?(content, shouldRemove, items.map(\.id))
    }

    private func updateSelectionOrder(previous: Set<UUID>, current: Set<UUID>) {
        let removed = previous.subtracting(current)
        if !removed.isEmpty {
            selectionOrder.removeAll { removed.contains($0) }
        }

        guard !current.isEmpty else {
            selectionOrder.removeAll()
            return
        }

        let added = current.subtracting(previous)
        if let intent = selectionIntent {
            selectionIntent = nil
            let flags = intent.modifiers

            if flags.contains(.shift) {
                selectionOrder = queueManager.items.map(\.id).filter { current.contains($0) }
                return
            }

            if flags.contains(.command) {
                if added.contains(intent.clickedID), !selectionOrder.contains(intent.clickedID) {
                    selectionOrder.append(intent.clickedID)
                } else if !added.contains(intent.clickedID) {
                    selectionOrder.removeAll { $0 == intent.clickedID }
                }
                return
            }

            if current.count == 1, let only = current.first {
                selectionOrder = [only]
                return
            }
        }

        guard !added.isEmpty else { return }

        let orderedAdded = queueManager.items
            .filter { added.contains($0.id) }
            .map(\.id)

        for id in orderedAdded where !selectionOrder.contains(id) {
            selectionOrder.append(id)
        }
    }

    private func syncSelection(with items: [ClipboardItem]) {
        let existing = Set(items.map(\.id))
        selectedQueueIDs = selectedQueueIDs.intersection(existing)
        selectionOrder = selectionOrder.filter { existing.contains($0) }
    }

    private func ensureSelectedTabIsVisible() {
        if !visibleTabs.contains(preferences.selectedQueueTab) {
            preferences.selectedQueueTab = .queue
        }
    }

    private func toggleFavorite(item: ClipboardItem) {
        let newValue = !item.isFavorite
        queueManager.updateFavorite(for: item, favorite: newValue)
        historyStore?.setFavorite(itemId: item.id, favorite: newValue)
    }

    private func confirmAndClearQueue() {
        if preferences.confirmBeforeClear {
            let alert = NSAlert()
            alert.messageText = "Clear Queue?"
            alert.informativeText = "This will remove all items from the queue. This action cannot be undone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Clear")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                queueManager.clearQueue()
            }
        } else {
            queueManager.clearQueue()
        }
    }

    private func recordSelectionIntent(for item: ClipboardItem) {
        guard let event = NSApp.currentEvent else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        selectionIntent = SelectionIntent(clickedID: item.id, modifiers: flags)
    }

    @ViewBuilder
    private func categoryMenu(for item: ClipboardItem) -> some View {
        if let categoryStore, !categoryStore.categories.isEmpty {
            Menu("Category") {
                Button("None") {
                    queueManager.updateCategory(for: item, categoryId: nil)
                    historyStore?.setCategory(itemId: item.id, categoryId: nil)
                }
                Divider()
                ForEach(categoryStore.categories, id: \.id) { category in
                    Button(category.name) {
                        queueManager.updateCategory(for: item, categoryId: category.id)
                        historyStore?.setCategory(itemId: item.id, categoryId: category.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pinnedSection(historyStore: HistoryStore, query: String) -> some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pinnedItems = trimmed.isEmpty
            ? historyStore.pinnedItems
            : historyStore.pinnedItems.filter { $0.content.localizedCaseInsensitiveContains(trimmed) }

        if !pinnedItems.isEmpty {
            Section("Pinned") {
                ForEach(pinnedItems, id: \.id) { entry in
                    PinnedItemRow(
                        entry: entry,
                        category: categoryStore?.category(for: entry.categoryId),
                        showAppIcon: preferences.showAppIcons,
                        compactMode: preferences.compactMode,
                        previewLines: preferences.showPreviewLines
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onDrag {
                        dragItemProvider(entry.content)
                    }
                    .contextMenu {
                        Button("Copy") {
                            copyToPasteboard(entry.content)
                        }
                        Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                            historyStore.setFavorite(itemId: entry.id, favorite: !entry.isFavorite)
                        }
                        if let categoryStore, !categoryStore.categories.isEmpty {
                            Menu("Category") {
                                Button("None") {
                                    historyStore.setCategory(itemId: entry.id, categoryId: nil)
                                }
                                Divider()
                                ForEach(categoryStore.categories, id: \.id) { category in
                                    Button(category.name) {
                                        historyStore.setCategory(itemId: entry.id, categoryId: category.id)
                                    }
                                }
                            }
                        }
                        Button("Unpin") {
                            historyStore.setPinned(itemId: entry.id, pinned: false)
                        }
                        Button("Remove") {
                            historyStore.remove(entry)
                        }
                    }
                }
            }
        }
    }
}

private enum QueuePasteTrigger {
    case enter
    case shiftEnter
    case controlW
}

private struct SelectionIntent {
    let clickedID: UUID
    let modifiers: NSEvent.ModifierFlags
}

struct QueueItemRow: View {
    let item: ClipboardItem
    let isOldest: Bool
    let isSelected: Bool
    let category: ClipboardCategory?
    let showAppIcon: Bool
    let compactMode: Bool
    let previewLines: Int
    @ObservedObject var queueManager: QueueManager
    @ObservedObject private var preferences = Preferences.shared
    @State private var isHovering = false
    @State private var isDragging = false

    private var density: RowDensity { preferences.rowDensity }

    var body: some View {
        HStack(alignment: .top, spacing: density.rowSpacing) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: compactMode ? 8 : 10))
                .foregroundColor(.secondary.opacity(0.5))
                .help("Drag to reorder")
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: item.sourceAppBundleIdentifier,
                    appName: item.sourceAppName,
                    size: compactMode ? preferences.sourceAppIconSize * 0.875 : preferences.sourceAppIconSize
                )
                .help(item.sourceAppName ?? "Unknown App")
            }
            // Content preview
            VStack(alignment: .leading, spacing: density.contentSpacing) {
                LinkDetectingText(
                    item.shortPreview,
                    lineLimit: previewLines,
                    font: compactMode ? .caption : .callout,
                    foregroundStyle: isOldest ? .primary : .secondary
                )

                HStack(spacing: 4) {
                    // Type icon
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundColor(iconColor)

                    Text(item.timeAgo)
                        .font(compactMode ? .system(size: 9) : .caption2)
                        .foregroundStyle(.tertiary)

                    if preferences.showCharacterCount {
                        Text("• \(item.content.count) chars")
                            .font(compactMode ? .system(size: 9) : .caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if let category {
                        CategoryBadge(category: category, compact: compactMode)
                    }

                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(compactMode ? .system(size: 8) : .caption2)
                            .foregroundColor(.yellow)
                    }

                    if isOldest {
                        Text("• Next")
                            .font(compactMode ? .system(size: 9, weight: .semibold) : .caption2.weight(.semibold))
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // Delete button (always visible but subtle)
            Button(action: {
                queueManager.removeItem(item)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(isHovering ? .secondary : .secondary.opacity(0.3))
                    .font(.system(size: compactMode ? 12 : 14))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove item")
            .onHover { hovering in
                // Change to arrow cursor when hovering delete button
                if hovering {
                    NSCursor.pop() // Remove hand cursor
                    NSCursor.arrow.push()
                } else {
                    NSCursor.pop() // Remove arrow
                    if isHovering {
                        NSCursor.openHand.push() // Restore hand if still over item
                    }
                }
            }
        }
        .padding(.horizontal, density.horizontalPadding)
        .padding(.vertical, density.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isOldest ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor).opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: isOldest ? [4, 2] : [])
                )
        )
        .opacity(draggedItem?.id == item.id ? 0.5 : 1.0) // Fade out while dragging
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
            // Change cursor on hover
            if hovering {
                NSCursor.openHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .contentShape(Rectangle()) // Make entire area hoverable
    }

    private var rowFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.18))
        }
        if isHovering {
            return AnyShapeStyle(Color(NSColor.selectedControlColor).opacity(0.15))
        }
        if preferences.useVibrancy {
            return AnyShapeStyle(Material.ultraThinMaterial)
        }
        return AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.8))
    }
    
    private var iconName: String {
        switch item.type {
        case .text:
            return "doc.text"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .other:
            return "doc"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .text:
            return .blue
        case .url:
            return .green
        case .image:
            return .purple
        case .other:
            return .gray
        }
    }
}

struct HistoryView: View {
    let historyStore: HistoryStore?
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String

    var body: some View {
        if let historyStore {
            HistoryListView(historyStore: historyStore, categoryStore: categoryStore, showAppIcon: showAppIcon, searchText: searchText)
        } else {
            VStack {
                Spacer()
                ContentUnavailableView(
                    "History unavailable",
                    systemImage: "clock.badge.exclamationmark",
                    description: Text("History store failed to initialize.")
                )
                Spacer()
            }
        }
    }
}

struct FavoritesView: View {
    let historyStore: HistoryStore?
    let queueManager: QueueManager
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String

    var body: some View {
        if let historyStore {
            FavoritesListView(historyStore: historyStore, categoryStore: categoryStore, showAppIcon: showAppIcon, searchText: searchText)
        } else {
            FavoritesQueueListView(queueManager: queueManager, categoryStore: categoryStore, showAppIcon: showAppIcon, searchText: searchText)
        }
    }
}

struct RecentsView: View {
    let historyStore: HistoryStore?
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String

    var body: some View {
        if let historyStore {
            RecentsListView(historyStore: historyStore, categoryStore: categoryStore, showAppIcon: showAppIcon, searchText: searchText)
        } else {
            VStack {
                Spacer()
                ContentUnavailableView(
                    "Recents unavailable",
                    systemImage: "clock.badge.exclamationmark",
                    description: Text("History store failed to initialize.")
                )
                Spacer()
            }
        }
    }
}

struct HistoryListView: View {
    @Bindable var historyStore: HistoryStore
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String
    @State private var selectedEntryID: UUID?

    var body: some View {
        if historyStore.items.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No history yet" : "No results",
                    systemImage: "clock",
                    description: Text(searchText.isEmpty ? "Copy something to build your history." : "Try a different search term.")
                )
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(historyStore.items, id: \.id) { entry in
                        HistoryItemRow(
                            entry: entry,
                            isSelected: selectedEntryID == entry.id,
                            category: categoryStore?.category(for: entry.categoryId),
                            showAppIcon: showAppIcon,
                            compactMode: Preferences.shared.compactMode,
                            previewLines: Preferences.shared.showPreviewLines
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntryID = entry.id
                        }
                        .onDrag {
                            dragItemProvider(entry.content)
                        }
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(entry.content)
                            }
                            Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                                historyStore.setFavorite(itemId: entry.id, favorite: !entry.isFavorite)
                            }
                            Button(entry.isPinned ? "Unpin" : "Pin") {
                                historyStore.setPinned(itemId: entry.id, pinned: !entry.isPinned)
                            }
                            if let categoryStore, !categoryStore.categories.isEmpty {
                                Menu("Category") {
                                    Button("None") {
                                        historyStore.setCategory(itemId: entry.id, categoryId: nil)
                                    }
                                    Divider()
                                    ForEach(categoryStore.categories, id: \.id) { category in
                                        Button(category.name) {
                                            historyStore.setCategory(itemId: entry.id, categoryId: category.id)
                                        }
                                    }
                                }
                            }
                            Button("Remove") {
                                historyStore.remove(entry)
                            }
                        }
                    }

                    if historyStore.canLoadMore {
                        ProgressView()
                            .frame(height: 40)
                            .onAppear {
                                historyStore.loadMore()
                            }
                    }
                }
                .padding(8)
            }
            .contextMenu {
                Button("Clear History") {
                    historyStore.clearAll()
                }
            }
        }
    }
}

struct FavoritesListView: View {
    @Bindable var historyStore: HistoryStore
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String
    @State private var selectedEntryID: UUID?

    private var filteredFavorites: [ClipboardHistoryEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = historyStore.favoriteItems
        guard !query.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        if filteredFavorites.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No favorites yet" : "No results",
                    systemImage: "star",
                    description: Text(searchText.isEmpty ? "Mark items as favorites to keep them handy." : "Try a different search term.")
                )
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredFavorites, id: \.id) { entry in
                        HistoryItemRow(
                            entry: entry,
                            isSelected: selectedEntryID == entry.id,
                            category: categoryStore?.category(for: entry.categoryId),
                            showAppIcon: showAppIcon,
                            compactMode: Preferences.shared.compactMode,
                            previewLines: Preferences.shared.showPreviewLines
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntryID = entry.id
                        }
                        .onDrag {
                            dragItemProvider(entry.content)
                        }
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(entry.content)
                            }
                            Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                                historyStore.setFavorite(itemId: entry.id, favorite: !entry.isFavorite)
                            }
                            Button(entry.isPinned ? "Unpin" : "Pin") {
                                historyStore.setPinned(itemId: entry.id, pinned: !entry.isPinned)
                            }
                            if let categoryStore, !categoryStore.categories.isEmpty {
                                Menu("Category") {
                                    Button("None") {
                                        historyStore.setCategory(itemId: entry.id, categoryId: nil)
                                    }
                                    Divider()
                                    ForEach(categoryStore.categories, id: \.id) { category in
                                        Button(category.name) {
                                            historyStore.setCategory(itemId: entry.id, categoryId: category.id)
                                        }
                                    }
                                }
                            }
                            Button("Remove") {
                                historyStore.remove(entry)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}

struct RecentsListView: View {
    @Bindable var historyStore: HistoryStore
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String
    @State private var selectedEntryID: UUID?

    private var recentEntries: [ClipboardHistoryEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = historyStore.recentlyPastedItems
        let filtered = query.isEmpty ? items : items.filter { $0.content.localizedCaseInsensitiveContains(query) }
        return Array(filtered.prefix(50))
    }

    var body: some View {
        if recentEntries.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No recents yet" : "No results",
                    systemImage: "clock",
                    description: Text(searchText.isEmpty ? "Recent items will appear here." : "Try a different search term.")
                )
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(recentEntries, id: \.id) { entry in
                        HistoryItemRow(
                            entry: entry,
                            isSelected: selectedEntryID == entry.id,
                            category: categoryStore?.category(for: entry.categoryId),
                            showAppIcon: showAppIcon,
                            compactMode: Preferences.shared.compactMode,
                            previewLines: Preferences.shared.showPreviewLines
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntryID = entry.id
                        }
                        .onDrag {
                            dragItemProvider(entry.content)
                        }
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(entry.content)
                            }
                            Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                                historyStore.setFavorite(itemId: entry.id, favorite: !entry.isFavorite)
                            }
                            Button(entry.isPinned ? "Unpin" : "Pin") {
                                historyStore.setPinned(itemId: entry.id, pinned: !entry.isPinned)
                            }
                            if let categoryStore, !categoryStore.categories.isEmpty {
                                Menu("Category") {
                                    Button("None") {
                                        historyStore.setCategory(itemId: entry.id, categoryId: nil)
                                    }
                                    Divider()
                                    ForEach(categoryStore.categories, id: \.id) { category in
                                        Button(category.name) {
                                            historyStore.setCategory(itemId: entry.id, categoryId: category.id)
                                        }
                                    }
                                }
                            }
                            Button("Remove") {
                                historyStore.remove(entry)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}

struct FavoritesQueueListView: View {
    @ObservedObject var queueManager: QueueManager
    let categoryStore: CategoryStore?
    let showAppIcon: Bool
    let searchText: String

    private var favoriteItems: [ClipboardItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = queueManager.items.filter { $0.isFavorite }
        guard !query.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        if favoriteItems.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No favorites yet" : "No results",
                    systemImage: "star",
                    description: Text(searchText.isEmpty ? "Mark items as favorites to keep them handy." : "Try a different search term.")
                )
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(favoriteItems) { item in
                        QueueItemRow(
                            item: item,
                            isOldest: false,
                            isSelected: false,
                            category: categoryStore?.category(for: item.categoryId),
                            showAppIcon: showAppIcon,
                            compactMode: Preferences.shared.compactMode,
                            previewLines: Preferences.shared.showPreviewLines,
                            queueManager: queueManager
                        )
                        .onDrag {
                            dragItemProvider(item.content)
                        }
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(item.content)
                            }
                            Button("Remove from Favorites") {
                                queueManager.updateFavorite(for: item, favorite: false)
                            }
                            Button("Remove") {
                                queueManager.removeItem(item)
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}

struct HistoryItemRow: View {
    let entry: ClipboardHistoryEntry
    let isSelected: Bool
    let category: ClipboardCategory?
    let showAppIcon: Bool
    let compactMode: Bool
    let previewLines: Int
    @ObservedObject private var preferences = Preferences.shared
    @State private var isHovering = false

    private var density: RowDensity { preferences.rowDensity }

    var body: some View {
        HStack(alignment: .top, spacing: density.rowSpacing) {
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: entry.sourceAppBundleIdentifier,
                    appName: entry.sourceAppName,
                    size: compactMode ? preferences.sourceAppIconSize * 0.875 : preferences.sourceAppIconSize
                )
                .help(entry.sourceAppName ?? "Unknown App")
            }

            VStack(alignment: .leading, spacing: density.contentSpacing) {
                LinkDetectingText(
                    entry.shortPreview,
                    lineLimit: previewLines,
                    font: compactMode ? .caption : .callout,
                    foregroundStyle: .primary
                )

                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundColor(iconColor)

                    Text(entry.timeAgo)
                        .font(compactMode ? .system(size: 9) : .caption2)
                        .foregroundStyle(.tertiary)

                    if preferences.showCharacterCount {
                        Text("• \(entry.content.count) chars")
                            .font(compactMode ? .system(size: 9) : .caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if let category {
                        CategoryBadge(category: category, compact: compactMode)
                    }

                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(compactMode ? .system(size: 8) : .caption2)
                            .foregroundColor(.yellow)
                    }

                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(compactMode ? .system(size: 8) : .caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, density.horizontalPadding)
        .padding(.vertical, density.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor).opacity(0.5))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }

    private var rowFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.18))
        }
        if isHovering {
            return AnyShapeStyle(Color(NSColor.selectedControlColor).opacity(0.15))
        }
        if preferences.useVibrancy {
            return AnyShapeStyle(Material.ultraThinMaterial)
        }
        return AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.8))
    }

    private var iconName: String {
        switch entry.typeRaw {
        case ClipboardItem.ItemType.url.rawValue:
            return "link"
        case ClipboardItem.ItemType.text.rawValue:
            return "doc.text"
        case ClipboardItem.ItemType.image.rawValue:
            return "photo"
        default:
            return "doc"
        }
    }

    private var iconColor: Color {
        switch entry.typeRaw {
        case ClipboardItem.ItemType.url.rawValue:
            return .green
        case ClipboardItem.ItemType.text.rawValue:
            return .blue
        case ClipboardItem.ItemType.image.rawValue:
            return .purple
        default:
            return .gray
        }
    }
}

struct PinnedItemRow: View {
    let entry: ClipboardHistoryEntry
    let category: ClipboardCategory?
    let showAppIcon: Bool
    let compactMode: Bool
    let previewLines: Int
    @ObservedObject private var preferences = Preferences.shared

    private var density: RowDensity { preferences.rowDensity }

    var body: some View {
        HStack(alignment: .top, spacing: density.rowSpacing) {
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: entry.sourceAppBundleIdentifier,
                    appName: entry.sourceAppName,
                    size: compactMode ? preferences.sourceAppIconSize * 0.875 : preferences.sourceAppIconSize
                )
                .help(entry.sourceAppName ?? "Unknown App")
            }

            Image(systemName: "pin.fill")
                .font(compactMode ? .system(size: 8) : .caption2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: density.contentSpacing) {
                LinkDetectingText(
                    entry.shortPreview,
                    lineLimit: previewLines,
                    font: compactMode ? .caption : .callout,
                    foregroundStyle: .primary
                )

                HStack(spacing: compactMode ? 3 : 4) {
                    Image(systemName: iconName)
                        .font(compactMode ? .system(size: 8) : .caption2)
                        .foregroundColor(iconColor)

                    Text(entry.timeAgo)
                        .font(compactMode ? .system(size: 9) : .caption2)
                        .foregroundStyle(.tertiary)

                    if let category {
                        CategoryBadge(category: category, compact: compactMode)
                    }

                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(compactMode ? .system(size: 8) : .caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, density.horizontalPadding)
        .padding(.vertical, density.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var rowFill: some ShapeStyle {
        if preferences.useVibrancy {
            return AnyShapeStyle(Material.ultraThinMaterial)
        }
        return AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.8))
    }

    private var iconName: String {
        switch entry.typeRaw {
        case ClipboardItem.ItemType.url.rawValue:
            return "link"
        case ClipboardItem.ItemType.text.rawValue:
            return "doc.text"
        case ClipboardItem.ItemType.image.rawValue:
            return "photo"
        default:
            return "doc"
        }
    }

    private var iconColor: Color {
        switch entry.typeRaw {
        case ClipboardItem.ItemType.url.rawValue:
            return .green
        case ClipboardItem.ItemType.text.rawValue:
            return .blue
        case ClipboardItem.ItemType.image.rawValue:
            return .purple
        default:
            return .gray
        }
    }
}

struct CategoryBadge: View {
    let category: ClipboardCategory
    var compact: Bool = false
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        HStack(spacing: compact ? 3 : 4) {
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)
            Text(category.name)
                .font(compact ? .system(size: 9) : .caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 1 : 2)
        .background(
            Capsule()
                .fill(preferences.useVibrancy ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.6)))
        )
        .clipShape(Capsule())
    }
}

struct QuickLookPreview: View {
    let item: ClipboardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            if item.type == .image,
               let path = item.imagePath,
               let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                    .cornerRadius(8)
            } else {
                ScrollView {
                    Text(item.content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(20)
        .frame(minWidth: 320, minHeight: 220)
    }
}

struct KeyEventMonitor: NSViewRepresentable {
    let isEnabled: Bool
    let onKeyDown: (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown, isEnabled: isEnabled)
    }

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onKeyDown = onKeyDown
        context.coordinator.isEnabled = isEnabled
        if isEnabled {
            context.coordinator.startMonitoring()
        } else {
            context.coordinator.stopMonitoring()
        }
    }

    final class Coordinator {
        var onKeyDown: (NSEvent) -> Bool
        var isEnabled: Bool
        private var monitor: Any?

        init(onKeyDown: @escaping (NSEvent) -> Bool, isEnabled: Bool) {
            self.onKeyDown = onKeyDown
            self.isEnabled = isEnabled
        }

        func startMonitoring() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self else { return event }
                guard self.isEnabled else { return event }
                return self.onKeyDown(event) ? nil : event
            }
        }

        func stopMonitoring() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}

private func copyToPasteboard(_ content: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
}

private func dragItemProvider(_ content: String) -> NSItemProvider {
    let itemProvider = NSItemProvider(object: content as NSString)
    itemProvider.suggestedName = "ClipQueue Item"
    return itemProvider
}

// MARK: - Drag and Drop Delegate

struct DropViewDelegate: DropDelegate {
    let item: ClipboardItem
    @Binding var items: [ClipboardItem]
    let queueManager: QueueManager
    let animationSpeed: Double
    
    func dropEntered(info: DropInfo) {
        // Find the source and destination indices
        guard let draggedItem = draggedItem,
              let sourceIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let destinationIndex = items.firstIndex(where: { $0.id == item.id }),
              sourceIndex != destinationIndex else {
            return
        }
        
        // Perform the move with a faster, smoother animation
        let animation = Animation.spring(response: 0.3, dampingFraction: 0.8).speed(animationSpeed)
        withAnimation(animation) {
            queueManager.moveItem(from: sourceIndex, to: destinationIndex)
        }
        
        print("🔄 Moved item from index \(sourceIndex) to \(destinationIndex)")
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Clear the dragged item when drop completes
        draggedItem = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return draggedItem != nil
    }
}

// Helper to track dragged item globally
private var draggedItem: ClipboardItem?

// MARK: - Link Detection

/// A text view that detects URLs and renders them as clickable blue underlined links
struct LinkDetectingText: View {
    let content: String
    let lineLimit: Int
    let font: Font
    let foregroundStyle: Color
    @ObservedObject private var preferences = Preferences.shared

    private static let urlPattern = try! NSRegularExpression(
        pattern: #"https?://[^\s<>\[\]{}|\\^`"']+"#,
        options: .caseInsensitive
    )

    init(_ content: String, lineLimit: Int = 2, font: Font = .callout, foregroundStyle: Color = .primary) {
        self.content = content
        self.lineLimit = lineLimit
        self.font = font
        self.foregroundStyle = foregroundStyle
    }

    var body: some View {
        let segments = parseContent()

        if !preferences.highlightURLs || segments.allSatisfy({ !$0.isURL }) {
            // Highlighting disabled or no URLs, just show plain text
            Text(content)
                .lineLimit(lineLimit)
                .font(font)
                .foregroundStyle(foregroundStyle)
        } else {
            // Has URLs and highlighting enabled, render with clickable links
            HStack(spacing: 0) {
                ForEach(Array(segments.prefix(maxSegmentsForDisplay).enumerated()), id: \.offset) { _, segment in
                    if segment.isURL {
                        Text(segment.text)
                            .font(font)
                            .foregroundColor(.blue)
                            .underline()
                            .onTapGesture {
                                openURL(segment.text)
                            }
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    } else {
                        Text(segment.text)
                            .font(font)
                            .foregroundStyle(foregroundStyle)
                    }
                }
            }
            .lineLimit(lineLimit)
        }
    }

    private var maxSegmentsForDisplay: Int {
        // Limit segments to prevent performance issues with very long content
        20
    }

    private struct TextSegment {
        let text: String
        let isURL: Bool
    }

    private func parseContent() -> [TextSegment] {
        var segments: [TextSegment] = []
        let nsContent = content as NSString
        let range = NSRange(location: 0, length: nsContent.length)

        var lastEnd = 0

        let matches = Self.urlPattern.matches(in: content, options: [], range: range)

        for match in matches {
            // Add text before this URL
            if match.range.location > lastEnd {
                let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let text = nsContent.substring(with: textRange)
                if !text.isEmpty {
                    segments.append(TextSegment(text: text, isURL: false))
                }
            }

            // Add the URL
            let urlText = nsContent.substring(with: match.range)
            segments.append(TextSegment(text: urlText, isURL: true))

            lastEnd = match.range.location + match.range.length
        }

        // Add any remaining text after the last URL
        if lastEnd < nsContent.length {
            let textRange = NSRange(location: lastEnd, length: nsContent.length - lastEnd)
            let text = nsContent.substring(with: textRange)
            if !text.isEmpty {
                segments.append(TextSegment(text: text, isURL: false))
            }
        }

        // If no URLs found, return the whole content as one segment
        if segments.isEmpty {
            segments.append(TextSegment(text: content, isURL: false))
        }

        return segments
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
