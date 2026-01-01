import SwiftUI

struct QueueView: View {
    @ObservedObject var queueManager: QueueManager
    var onOpenPreferences: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Queue items list (oldest at top, newest at bottom)
            if queueManager.items.isEmpty {
                // Empty state
                VStack {
                    Spacer()
                    Text("Queue is empty")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    Text("Copy something to get started")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        // Display items in order: index 0 = oldest (top)
                        ForEach(Array(queueManager.items.enumerated()), id: \.element.id) { index, item in
                            QueueItemRow(
                                item: item,
                                index: index,
                                isOldest: index == 0,
                                queueManager: queueManager
                            )
                            .onDrag {
                                // Set the dragged item globally
                                draggedItem = item
                                print("🎯 Started dragging: \(item.shortPreview)")
                                
                                // Change to closed hand while dragging
                                NSCursor.pop() // Remove open hand
                                NSCursor.closedHand.set()
                                
                                // Create a custom drag preview that's more subtle
                                let itemProvider = NSItemProvider(object: item.id.uuidString as NSString)
                                
                                // Create a subtle preview
                                itemProvider.suggestedName = "Moving..."
                                
                                return itemProvider
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(
                                item: item,
                                items: $queueManager.items,
                                queueManager: queueManager
                            ))
                        }
                    }
                    .padding(8)
                }
            }
            
            Divider()
            
            // Footer with settings and clear
            HStack(spacing: 12) {
                // Settings button
                Button {
                    print("⚙️ Gear button clicked!")
                    onOpenPreferences?()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help("Settings")
                
                Spacer()
                
                // Clear button
                Button {
                    queueManager.clearQueue()
                } label: {
                    Text("Clear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .disabled(queueManager.items.isEmpty)
                .help("Clear all items (⌃X)")
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

struct QueueItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isOldest: Bool
    @ObservedObject var queueManager: QueueManager
    @State private var isHovering = false
    @State private var isDragging = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
                .help("Drag to reorder")
            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(item.shortPreview)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .foregroundStyle(isOldest ? .primary : .secondary)

                HStack(spacing: 4) {
                    // Type icon
                    Image(systemName: iconName)
                        .font(.system(size: 10))
                        .foregroundColor(iconColor)

                    Text(item.timeAgo)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    if isOldest {
                        Text("• Next")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Delete button (always visible but subtle)
            Button(action: {
                queueManager.removeItem(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(isHovering ? .secondary : .secondary.opacity(0.3))
                    .font(.system(size: 14))
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                )
                .foregroundColor(isOldest ? .blue.opacity(0.5) : .secondary.opacity(0.3))
        )
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color(NSColor.selectedControlColor).opacity(0.2) : Color.clear)
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

// MARK: - Drag and Drop Delegate

struct DropViewDelegate: DropDelegate {
    let item: ClipboardItem
    @Binding var items: [ClipboardItem]
    let queueManager: QueueManager
    
    func dropEntered(info: DropInfo) {
        // Find the source and destination indices
        guard let draggedItem = draggedItem,
              let sourceIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let destinationIndex = items.firstIndex(where: { $0.id == item.id }),
              sourceIndex != destinationIndex else {
            return
        }
        
        // Perform the move with a faster, smoother animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
