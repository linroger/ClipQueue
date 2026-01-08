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
    let isFavorite: Bool
    /// File path for image items (stored on disk due to size)
    let imagePath: String?

    enum ItemType: String, Codable {
        case text
        case url
        case image
        case other
    }
    
    init(
        content: String,
        type: ItemType = .text,
        sourceAppBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        categoryId: UUID? = nil,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        imagePath: String? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.imagePath = imagePath
    }

    init(
        id: UUID,
        content: String,
        timestamp: Date,
        type: ItemType,
        sourceAppBundleIdentifier: String?,
        sourceAppName: String?,
        categoryId: UUID?,
        isPinned: Bool,
        isFavorite: Bool,
        imagePath: String? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.imagePath = imagePath
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
            isPinned: isPinned,
            isFavorite: isFavorite,
            imagePath: imagePath
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
            isPinned: pinned,
            isFavorite: isFavorite,
            imagePath: imagePath
        )
    }

    func withFavorite(_ favorite: Bool) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            timestamp: timestamp,
            type: type,
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            sourceAppName: sourceAppName,
            categoryId: categoryId,
            isPinned: isPinned,
            isFavorite: favorite,
            imagePath: imagePath
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case timestamp
        case type
        case sourceAppBundleIdentifier
        case sourceAppName
        case categoryId
        case isPinned
        case isFavorite
        case imagePath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(ItemType.self, forKey: .type)
        sourceAppBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleIdentifier)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(sourceAppBundleIdentifier, forKey: .sourceAppBundleIdentifier)
        try container.encodeIfPresent(sourceAppName, forKey: .sourceAppName)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
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
    var isFavorite: Bool
    var imagePath: String?
    var lastPastedDate: Date?

    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        typeRaw: String,
        sourceAppBundleIdentifier: String? = nil,
        sourceAppName: String? = nil,
        categoryId: UUID? = nil,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        imagePath: String? = nil,
        lastPastedDate: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.typeRaw = typeRaw
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.sourceAppName = sourceAppName
        self.categoryId = categoryId
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.imagePath = imagePath
        self.lastPastedDate = lastPastedDate
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
