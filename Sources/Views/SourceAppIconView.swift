import SwiftUI
import AppKit

struct SourceAppIconView: View {
    let bundleIdentifier: String?
    let appName: String?
    var size: CGFloat = 16

    var body: some View {
        if let icon = AppIconCache.shared.icon(bundleIdentifier: bundleIdentifier, appName: appName) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            Image(systemName: "app")
                .font(.system(size: size))
                .foregroundColor(.secondary)
        }
    }
}

final class AppIconCache {
    static let shared = AppIconCache()

    private let cache = NSCache<NSString, NSImage>()
    private init() {}

    func icon(bundleIdentifier: String?, appName: String?) -> NSImage? {
        if let bundleIdentifier, let cached = cache.object(forKey: bundleIdentifier as NSString) {
            return cached
        }

        if let appName, let cached = cache.object(forKey: appName as NSString) {
            return cached
        }

        var icon: NSImage?
        if let bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            icon = NSWorkspace.shared.icon(forFile: appURL.path)
            if let icon {
                cache.setObject(icon, forKey: bundleIdentifier as NSString)
            }
        } else if let appName,
                  let appPath = NSWorkspace.shared.fullPath(forApplication: appName) {
            icon = NSWorkspace.shared.icon(forFile: appPath)
            if let icon {
                cache.setObject(icon, forKey: appName as NSString)
            }
        }

        return icon
    }
}
