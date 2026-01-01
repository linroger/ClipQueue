import Foundation
import AppKit

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ItemType
    
    enum ItemType: String, Codable {
        case text
        case url
        case other
    }
    
    init(content: String, type: ItemType = .text) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
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
