import Foundation
import AppKit
import SwiftData

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ItemType
    let sourceAppBundleIdentifier: String?
    let sourceAppName: String?
    let categoryId: UUID?
    let isPinned: Bool
    
    enum ItemType: String, Codable {
        case text
        case url
        case other
    }
    
    init(
        content: String,
        type: ItemType = .text,
        sourceAppBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        categoryId: UUID? = nil,
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
    }

    init(
        id: UUID,
        content: String,
        timestamp: Date,
        type: ItemType,
        sourceAppBundleIdentifier: String?,
        sourceAppName: String?,
        categoryId: UUID?,
        isPinned: Bool
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
    }

    func withCategory(_ categoryId: UUID?) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            timestamp: timestamp,
            type: type,
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            sourceAppName: sourceAppName,
            categoryId: categoryId,
            isPinned: isPinned
        )
    }

    func withPinned(_ pinned: Bool) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            timestamp: timestamp,
            type: type,
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            sourceAppName: sourceAppName,
            categoryId: categoryId,
            isPinned: pinned
        )
    }
    
    // Preview text (truncated if too long)
    var preview: String {
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }
    
    // Short preview for list items
    var shortPreview: String {
        let maxLength = 50
        let singleLine = content.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > maxLength {
            return String(singleLine.prefix(maxLength)) + "..."
        }
        return singleLine
    }
    
    // Time ago string
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

@Model
final class ClipboardHistoryEntry {
    @Attribute(.unique) var id: UUID
    var content: String
    var timestamp: Date
    var typeRaw: String
    var sourceAppBundleIdentifier: String?
    var sourceAppName: String?
    var categoryId: UUID?
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        typeRaw: String,
        sourceAppBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        categoryId: UUID? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.typeRaw = typeRaw
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
    }

    var preview: String {
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }

    var shortPreview: String {
        let maxLength = 50
        let singleLine = content.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > maxLength {
            return String(singleLine.prefix(maxLength)) + "..."
        }
        return singleLine
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
