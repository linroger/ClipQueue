import SwiftUI
import AppKit

struct QueueView: View {
    @ObservedObject var queueManager: QueueManager
    let historyStore: HistoryStore?
    let categoryStore: CategoryStore?
    var onOpenPreferences: (() -> Void)?
    @State private var selectedSection: QueueSection = .queue
    @State private var selectedQueueID: UUID?
    @State private var searchText = ""
    @ObservedObject private var preferences = Preferences.shared
    
    var body: some View {
        VStack(spacing: 0) {
            header

            switch selectedSection {
            case .queue:
                queueList
            case .history:
                HistoryView(historyStore: historyStore, categoryStore: categoryStore, showAppIcon: preferences.showAppIcons, searchText: searchText)
            }
            footer
        }
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
    }

    private var header: some View {
        GlassBar(edge: .bottom) {
            HStack(spacing: 8) {
                Picker("View", selection: $selectedSection) {
                    ForEach(availableSections) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 120, maxWidth: 200)
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
        .onChange(of: preferences.historyEnabled) { _, enabled in
            if !enabled {
                selectedSection = .queue
            }
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
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if let historyStore, hasPinnedItems {
                            pinnedSection(historyStore: historyStore, query: searchText)
                        }
                        ForEach(filteredQueueItems) { item in
                            QueueItemRow(
                                item: item,
                                isOldest: item.id == queueManager.items.first?.id,
                                isSelected: selectedQueueID == item.id,
                                category: categoryStore?.category(for: item.categoryId),
                                showAppIcon: preferences.showAppIcons,
                                compactMode: preferences.compactMode,
                                previewLines: preferences.showPreviewLines,
                                queueManager: queueManager
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedQueueID = item.id
                            }
                            .contextMenu {
                                Button("Copy") {
                                    copyToPasteboard(item.content)
                                }
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
                                print("🎯 Started dragging: \(item.shortPreview)")

                                NSCursor.pop()
                                NSCursor.closedHand.set()

                                let itemProvider = NSItemProvider(object: item.id.uuidString as NSString)
                                itemProvider.suggestedName = "Moving..."

                                return itemProvider
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(
                                item: item,
                                items: $queueManager.items,
                                queueManager: queueManager,
                                animationSpeed: preferences.animationSpeed
                            ))
                        }
                    }
                    .padding(8)
                }
                .contextMenu {
                    Button("Clear Queue") {
                        queueManager.clearQueue()
                    }
                }
            }
        }
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

                if selectedSection == .queue {
                    Button {
                        queueManager.clearQueue()
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

    private var availableSections: [QueueSection] {
        preferences.historyEnabled ? QueueSection.allCases : [.queue]
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

    private func pinnedSection(historyStore: HistoryStore, query: String) -> AnyView {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pinnedItems = trimmed.isEmpty
            ? historyStore.pinnedItems
            : historyStore.pinnedItems.filter { $0.content.localizedCaseInsensitiveContains(trimmed) }

        guard !pinnedItems.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(VStack(alignment: .leading, spacing: 6) {
            Text("Pinned")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(pinnedItems, id: \.id) { entry in
                PinnedItemRow(
                    entry: entry,
                    category: categoryStore?.category(for: entry.categoryId),
                    showAppIcon: preferences.showAppIcons,
                    compactMode: preferences.compactMode,
                    previewLines: preferences.showPreviewLines
                )
                .contextMenu {
                    Button("Copy") {
                        copyToPasteboard(entry.content)
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

            Divider()
                .padding(.vertical, 4)
        })
    }
}

enum QueueSection: String, CaseIterable, Identifiable {
    case queue
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .queue:
            return "Queue"
        case .history:
            return "History"
        }
    }
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

    private var rowPadding: CGFloat { compactMode ? 6 : 10 }
    private var contentSpacing: CGFloat { compactMode ? 2 : 4 }

    var body: some View {
        HStack(alignment: .top, spacing: compactMode ? 6 : 8) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: compactMode ? 8 : 10))
                .foregroundColor(.secondary.opacity(0.5))
                .help("Drag to reorder")
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: item.sourceAppBundleIdentifier,
                    appName: item.sourceAppName,
                    size: compactMode ? 14 : 16
                )
                .help(item.sourceAppName ?? "Unknown App")
            }
            // Content preview
            VStack(alignment: .leading, spacing: contentSpacing) {
                Text(item.shortPreview)
                    .lineLimit(previewLines)
                    .font(compactMode ? .caption : .callout)
                    .foregroundStyle(isOldest ? .primary : .secondary)

                HStack(spacing: 4) {
                    // Type icon
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundColor(iconColor)

                    Text(item.timeAgo)
                        .font(compactMode ? .system(size: 9) : .caption2)
                        .foregroundStyle(.tertiary)

                    if let category {
                        CategoryBadge(category: category, compact: compactMode)
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
        .padding(rowPadding)
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
                        .contextMenu {
                            Button("Copy") {
                                copyToPasteboard(entry.content)
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

struct HistoryItemRow: View {
    let entry: ClipboardHistoryEntry
    let isSelected: Bool
    let category: ClipboardCategory?
    let showAppIcon: Bool
    let compactMode: Bool
    let previewLines: Int
    @ObservedObject private var preferences = Preferences.shared
    @State private var isHovering = false

    private var rowPadding: CGFloat { compactMode ? 6 : 10 }
    private var contentSpacing: CGFloat { compactMode ? 2 : 4 }

    var body: some View {
        HStack(alignment: .top, spacing: compactMode ? 6 : 8) {
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: entry.sourceAppBundleIdentifier,
                    appName: entry.sourceAppName,
                    size: compactMode ? 14 : 16
                )
                .help(entry.sourceAppName ?? "Unknown App")
            }

            VStack(alignment: .leading, spacing: contentSpacing) {
                Text(entry.shortPreview)
                    .lineLimit(previewLines)
                    .font(compactMode ? .caption : .callout)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundColor(iconColor)

                    Text(entry.timeAgo)
                        .font(compactMode ? .system(size: 9) : .caption2)
                        .foregroundStyle(.tertiary)

                    if let category {
                        CategoryBadge(category: category, compact: compactMode)
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
        .padding(rowPadding)
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
        .textSelection(.enabled)
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

    private var rowPadding: CGFloat { compactMode ? 6 : 10 }
    private var contentSpacing: CGFloat { compactMode ? 2 : 4 }

    var body: some View {
        HStack(alignment: .top, spacing: compactMode ? 6 : 8) {
            if showAppIcon {
                SourceAppIconView(
                    bundleIdentifier: entry.sourceAppBundleIdentifier,
                    appName: entry.sourceAppName,
                    size: compactMode ? 14 : 16
                )
                .help(entry.sourceAppName ?? "Unknown App")
            }

            Image(systemName: "pin.fill")
                .font(compactMode ? .system(size: 8) : .caption2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: contentSpacing) {
                Text(entry.shortPreview)
                    .lineLimit(previewLines)
                    .font(compactMode ? .caption : .callout)
                    .foregroundStyle(.primary)

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
                }
            }

            Spacer()
        }
        .padding(rowPadding)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .textSelection(.enabled)
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

private func copyToPasteboard(_ content: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
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
