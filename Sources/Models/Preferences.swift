import Foundation
import ServiceManagement

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum DoubleClickAction: String, CaseIterable, Identifiable {
    case copy = "copy"
    case paste = "paste"
    case none = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .copy: return "Copy to Clipboard"
        case .paste: return "Paste Immediately"
        case .none: return "Do Nothing"
        }
    }
}

enum RowDensity: String, CaseIterable, Identifiable {
    case comfortable = "comfortable"
    case standard = "standard"
    case compact = "compact"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .comfortable: return "Comfortable"
        case .standard: return "Standard"
        case .compact: return "Compact"
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .comfortable: return 12
        case .standard: return 8
        case .compact: return 5
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .comfortable: return 12
        case .standard: return 10
        case .compact: return 6
        }
    }
}

enum CornerStyle: String, CaseIterable, Identifiable {
    case rounded = "rounded"
    case smooth = "smooth"
    case sharp = "sharp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: return "Rounded"
        case .smooth: return "Smooth"
        case .sharp: return "Sharp"
        }
    }

    var radius: CGFloat {
        switch self {
        case .rounded: return 12
        case .smooth: return 8
        case .sharp: return 4
        }
    }
}

// MARK: - Liquid Glass Configuration

enum MaterialThickness: String, CaseIterable, Identifiable {
    case ultraThin = "ultraThin"
    case thin = "thin"
    case regular = "regular"
    case thick = "thick"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ultraThin: return "Ultra Thin"
        case .thin: return "Thin"
        case .regular: return "Regular"
        case .thick: return "Thick"
        }
    }

    var description: String {
        switch self {
        case .ultraThin: return "Maximum background visibility"
        case .thin: return "Subtle blur with good visibility"
        case .regular: return "Balanced blur and visibility"
        case .thick: return "Maximum blur, minimal visibility"
        }
    }
}

enum GlassVariant: String, CaseIterable, Identifiable {
    case regular = "regular"
    case clear = "clear"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .clear: return "Clear"
        }
    }

    var description: String {
        switch self {
        case .regular: return "Blurs background for better legibility"
        case .clear: return "Highly translucent for immersive content"
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case system = "system"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case graphite = "graphite"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .graphite: return "Graphite"
        }
    }

    var color: Color {
        switch self {
        case .system: return Color.accentColor
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .pink: return Color.pink
        case .red: return Color.red
        case .orange: return Color.orange
        case .yellow: return Color.yellow
        case .green: return Color.green
        case .graphite: return Color.gray
        }
    }
}

import SwiftUI

enum WindowStyle: String, CaseIterable, Identifiable {
    case floating = "floating"
    case panel = "panel"
    case standard = "standard"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .floating: return "Floating"
        case .panel: return "Panel"
        case .standard: return "Standard"
        }
    }

    var description: String {
        switch self {
        case .floating: return "Compact floating window style"
        case .panel: return "Utility panel appearance"
        case .standard: return "Standard macOS window"
        }
    }
}

enum TextSize: String, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

class Preferences: ObservableObject {
    static let shared = Preferences()
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            // Actually enable/disable launch at login
            LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    @Published var keepWindowOnTop: Bool {
        didSet {
            UserDefaults.standard.set(keepWindowOnTop, forKey: "keepWindowOnTop")
        }
    }
    
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }

    @Published var historyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(historyEnabled, forKey: "historyEnabled")
        }
    }

    @Published var showAppIcons: Bool {
        didSet {
            UserDefaults.standard.set(showAppIcons, forKey: "showAppIcons")
        }
    }

    @Published var pauseMonitoringWhenHidden: Bool {
        didSet {
            UserDefaults.standard.set(pauseMonitoringWhenHidden, forKey: "pauseMonitoringWhenHidden")
        }
    }

    @Published var animationSpeed: Double {
        didSet {
            UserDefaults.standard.set(animationSpeed, forKey: "animationSpeed")
        }
    }

    @Published var windowTranslucency: Double {
        didSet {
            UserDefaults.standard.set(windowTranslucency, forKey: "windowTranslucency")
        }
    }

    @Published var useVibrancy: Bool {
        didSet {
            UserDefaults.standard.set(useVibrancy, forKey: "useVibrancy")
        }
    }

    // Queue and history limits
    @Published var maxQueueSize: Int {
        didSet {
            UserDefaults.standard.set(maxQueueSize, forKey: "maxQueueSize")
        }
    }

    @Published var historyRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(historyRetentionDays, forKey: "historyRetentionDays")
        }
    }

    // Appearance
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    @Published var compactMode: Bool {
        didSet {
            UserDefaults.standard.set(compactMode, forKey: "compactMode")
        }
    }

    @Published var showPreviewLines: Int {
        didSet {
            UserDefaults.standard.set(showPreviewLines, forKey: "showPreviewLines")
        }
    }

    @Published var rowDensity: RowDensity {
        didSet {
            UserDefaults.standard.set(rowDensity.rawValue, forKey: "rowDensity")
        }
    }

    @Published var showBorders: Bool {
        didSet {
            UserDefaults.standard.set(showBorders, forKey: "showBorders")
        }
    }

    @Published var cornerStyle: CornerStyle {
        didSet {
            UserDefaults.standard.set(cornerStyle.rawValue, forKey: "cornerStyle")
        }
    }

    // Liquid Glass options
    @Published var materialThickness: MaterialThickness {
        didSet {
            UserDefaults.standard.set(materialThickness.rawValue, forKey: "materialThickness")
        }
    }

    @Published var glassVariant: GlassVariant {
        didSet {
            UserDefaults.standard.set(glassVariant.rawValue, forKey: "glassVariant")
        }
    }

    @Published var accentColorOption: AccentColorOption {
        didSet {
            UserDefaults.standard.set(accentColorOption.rawValue, forKey: "accentColorOption")
        }
    }

    @Published var blurIntensity: Double {
        didSet {
            UserDefaults.standard.set(blurIntensity, forKey: "blurIntensity")
        }
    }

    @Published var windowStyle: WindowStyle {
        didSet {
            UserDefaults.standard.set(windowStyle.rawValue, forKey: "windowStyle")
        }
    }

    @Published var textSize: TextSize {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: "textSize")
        }
    }

    @Published var showShadows: Bool {
        didSet {
            UserDefaults.standard.set(showShadows, forKey: "showShadows")
        }
    }

    @Published var reduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "reduceMotion")
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }

    @Published var showTooltips: Bool {
        didSet {
            UserDefaults.standard.set(showTooltips, forKey: "showTooltips")
        }
    }

    @Published var autoHideToolbar: Bool {
        didSet {
            UserDefaults.standard.set(autoHideToolbar, forKey: "autoHideToolbar")
        }
    }

    @Published var showItemIndex: Bool {
        didSet {
            UserDefaults.standard.set(showItemIndex, forKey: "showItemIndex")
        }
    }

    @Published var highlightURLs: Bool {
        didSet {
            UserDefaults.standard.set(highlightURLs, forKey: "highlightURLs")
        }
    }

    @Published var trimWhitespace: Bool {
        didSet {
            UserDefaults.standard.set(trimWhitespace, forKey: "trimWhitespace")
        }
    }

    @Published var stripFormatting: Bool {
        didSet {
            UserDefaults.standard.set(stripFormatting, forKey: "stripFormatting")
        }
    }

    @Published var notifyOnCopy: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnCopy, forKey: "notifyOnCopy")
        }
    }

    // Behavior options
    @Published var doubleClickAction: DoubleClickAction {
        didSet {
            UserDefaults.standard.set(doubleClickAction.rawValue, forKey: "doubleClickAction")
        }
    }

    @Published var showTimestamps: Bool {
        didSet {
            UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps")
        }
    }

    @Published var playSoundEffects: Bool {
        didSet {
            UserDefaults.standard.set(playSoundEffects, forKey: "playSoundEffects")
        }
    }

    @Published var autoClearAfterPaste: Bool {
        didSet {
            UserDefaults.standard.set(autoClearAfterPaste, forKey: "autoClearAfterPaste")
        }
    }

    @Published var skipDuplicates: Bool {
        didSet {
            UserDefaults.standard.set(skipDuplicates, forKey: "skipDuplicates")
        }
    }

    @Published var showCharacterCount: Bool {
        didSet {
            UserDefaults.standard.set(showCharacterCount, forKey: "showCharacterCount")
        }
    }

    @Published var confirmBeforeClear: Bool {
        didSet {
            UserDefaults.standard.set(confirmBeforeClear, forKey: "confirmBeforeClear")
        }
    }

    // Keyboard shortcuts
    @Published var copyAndRecordShortcut: String {
        didSet {
            UserDefaults.standard.set(copyAndRecordShortcut, forKey: "copyAndRecordShortcut")
        }
    }
    
    @Published var toggleWindowShortcut: String {
        didSet {
            UserDefaults.standard.set(toggleWindowShortcut, forKey: "toggleWindowShortcut")
        }
    }
    
    @Published var pasteNextShortcut: String {
        didSet {
            UserDefaults.standard.set(pasteNextShortcut, forKey: "pasteNextShortcut")
        }
    }
    
    @Published var pasteAllShortcut: String {
        didSet {
            UserDefaults.standard.set(pasteAllShortcut, forKey: "pasteAllShortcut")
        }
    }
    
    @Published var clearAllShortcut: String {
        didSet {
            UserDefaults.standard.set(clearAllShortcut, forKey: "clearAllShortcut")
        }
    }
    
    private init() {
        // Load saved preferences or use defaults
        let savedKeepOnTop = UserDefaults.standard.object(forKey: "keepWindowOnTop")
        self.keepWindowOnTop = savedKeepOnTop == nil ? true : UserDefaults.standard.bool(forKey: "keepWindowOnTop")
        
        let savedShowInMenuBar = UserDefaults.standard.object(forKey: "showInMenuBar")
        self.showInMenuBar = savedShowInMenuBar == nil ? true : UserDefaults.standard.bool(forKey: "showInMenuBar")
        
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

        let savedHistory = UserDefaults.standard.object(forKey: "historyEnabled")
        self.historyEnabled = savedHistory == nil ? true : UserDefaults.standard.bool(forKey: "historyEnabled")

        let savedIcons = UserDefaults.standard.object(forKey: "showAppIcons")
        self.showAppIcons = savedIcons == nil ? true : UserDefaults.standard.bool(forKey: "showAppIcons")

        self.pauseMonitoringWhenHidden = UserDefaults.standard.bool(forKey: "pauseMonitoringWhenHidden")

        let savedAnimation = UserDefaults.standard.object(forKey: "animationSpeed")
        self.animationSpeed = savedAnimation == nil ? 1.0 : UserDefaults.standard.double(forKey: "animationSpeed")

        let savedTranslucency = UserDefaults.standard.object(forKey: "windowTranslucency")
        self.windowTranslucency = savedTranslucency == nil ? 0.95 : UserDefaults.standard.double(forKey: "windowTranslucency")

        let savedVibrancy = UserDefaults.standard.object(forKey: "useVibrancy")
        self.useVibrancy = savedVibrancy == nil ? true : UserDefaults.standard.bool(forKey: "useVibrancy")

        // Queue and history limits
        let savedMaxQueue = UserDefaults.standard.object(forKey: "maxQueueSize")
        self.maxQueueSize = savedMaxQueue == nil ? 100 : UserDefaults.standard.integer(forKey: "maxQueueSize")

        let savedRetention = UserDefaults.standard.object(forKey: "historyRetentionDays")
        self.historyRetentionDays = savedRetention == nil ? 30 : UserDefaults.standard.integer(forKey: "historyRetentionDays")

        // Appearance
        let savedAppearance = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: savedAppearance) ?? .system

        self.compactMode = UserDefaults.standard.bool(forKey: "compactMode")

        let savedPreviewLines = UserDefaults.standard.object(forKey: "showPreviewLines")
        self.showPreviewLines = savedPreviewLines == nil ? 2 : UserDefaults.standard.integer(forKey: "showPreviewLines")

        let savedRowDensity = UserDefaults.standard.string(forKey: "rowDensity") ?? "standard"
        self.rowDensity = RowDensity(rawValue: savedRowDensity) ?? .standard

        let savedShowBorders = UserDefaults.standard.object(forKey: "showBorders")
        self.showBorders = savedShowBorders == nil ? true : UserDefaults.standard.bool(forKey: "showBorders")

        let savedCornerStyle = UserDefaults.standard.string(forKey: "cornerStyle") ?? "smooth"
        self.cornerStyle = CornerStyle(rawValue: savedCornerStyle) ?? .smooth

        // Liquid Glass options
        let savedMaterialThickness = UserDefaults.standard.string(forKey: "materialThickness") ?? "regular"
        self.materialThickness = MaterialThickness(rawValue: savedMaterialThickness) ?? .regular

        let savedGlassVariant = UserDefaults.standard.string(forKey: "glassVariant") ?? "regular"
        self.glassVariant = GlassVariant(rawValue: savedGlassVariant) ?? .regular

        let savedAccentColor = UserDefaults.standard.string(forKey: "accentColorOption") ?? "system"
        self.accentColorOption = AccentColorOption(rawValue: savedAccentColor) ?? .system

        let savedBlurIntensity = UserDefaults.standard.object(forKey: "blurIntensity")
        self.blurIntensity = savedBlurIntensity == nil ? 1.0 : UserDefaults.standard.double(forKey: "blurIntensity")

        let savedWindowStyle = UserDefaults.standard.string(forKey: "windowStyle") ?? "floating"
        self.windowStyle = WindowStyle(rawValue: savedWindowStyle) ?? .floating

        let savedTextSize = UserDefaults.standard.string(forKey: "textSize") ?? "medium"
        self.textSize = TextSize(rawValue: savedTextSize) ?? .medium

        let savedShowShadows = UserDefaults.standard.object(forKey: "showShadows")
        self.showShadows = savedShowShadows == nil ? true : UserDefaults.standard.bool(forKey: "showShadows")

        self.reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
        self.hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")

        let savedShowTooltips = UserDefaults.standard.object(forKey: "showTooltips")
        self.showTooltips = savedShowTooltips == nil ? true : UserDefaults.standard.bool(forKey: "showTooltips")

        self.autoHideToolbar = UserDefaults.standard.bool(forKey: "autoHideToolbar")
        self.showItemIndex = UserDefaults.standard.bool(forKey: "showItemIndex")

        let savedHighlightURLs = UserDefaults.standard.object(forKey: "highlightURLs")
        self.highlightURLs = savedHighlightURLs == nil ? true : UserDefaults.standard.bool(forKey: "highlightURLs")

        let savedTrimWhitespace = UserDefaults.standard.object(forKey: "trimWhitespace")
        self.trimWhitespace = savedTrimWhitespace == nil ? true : UserDefaults.standard.bool(forKey: "trimWhitespace")

        self.stripFormatting = UserDefaults.standard.bool(forKey: "stripFormatting")
        self.notifyOnCopy = UserDefaults.standard.bool(forKey: "notifyOnCopy")

        // Behavior options
        let savedDoubleClick = UserDefaults.standard.string(forKey: "doubleClickAction") ?? "copy"
        self.doubleClickAction = DoubleClickAction(rawValue: savedDoubleClick) ?? .copy

        let savedTimestamps = UserDefaults.standard.object(forKey: "showTimestamps")
        self.showTimestamps = savedTimestamps == nil ? true : UserDefaults.standard.bool(forKey: "showTimestamps")

        self.playSoundEffects = UserDefaults.standard.bool(forKey: "playSoundEffects")
        self.autoClearAfterPaste = UserDefaults.standard.bool(forKey: "autoClearAfterPaste")

        let savedSkipDupes = UserDefaults.standard.object(forKey: "skipDuplicates")
        self.skipDuplicates = savedSkipDupes == nil ? true : UserDefaults.standard.bool(forKey: "skipDuplicates")

        self.showCharacterCount = UserDefaults.standard.bool(forKey: "showCharacterCount")
        self.confirmBeforeClear = UserDefaults.standard.bool(forKey: "confirmBeforeClear")

        // Load shortcuts or use defaults
        self.copyAndRecordShortcut = UserDefaults.standard.string(forKey: "copyAndRecordShortcut") ?? "⌃Q"
        self.toggleWindowShortcut = UserDefaults.standard.string(forKey: "toggleWindowShortcut") ?? "⌃⌥⌘C"
        self.pasteNextShortcut = UserDefaults.standard.string(forKey: "pasteNextShortcut") ?? "⌃W"
        self.pasteAllShortcut = UserDefaults.standard.string(forKey: "pasteAllShortcut") ?? "⌃E"
        self.clearAllShortcut = UserDefaults.standard.string(forKey: "clearAllShortcut") ?? "⌃X"
    }
    
    func resetToDefaults() {
        launchAtLogin = false
        keepWindowOnTop = true
        showInMenuBar = true
        historyEnabled = true
        showAppIcons = true
        pauseMonitoringWhenHidden = false
        animationSpeed = 1.0
        windowTranslucency = 0.95
        useVibrancy = true
        maxQueueSize = 100
        historyRetentionDays = 30
        appearanceMode = .system
        compactMode = false
        showPreviewLines = 2
        rowDensity = .standard
        showBorders = true
        cornerStyle = .smooth
        // Liquid Glass options
        materialThickness = .regular
        glassVariant = .regular
        accentColorOption = .system
        blurIntensity = 1.0
        windowStyle = .floating
        textSize = .medium
        showShadows = true
        reduceMotion = false
        hapticsEnabled = false
        showTooltips = true
        autoHideToolbar = false
        showItemIndex = false
        highlightURLs = true
        trimWhitespace = true
        stripFormatting = false
        notifyOnCopy = false
        // Behavior options
        doubleClickAction = .copy
        showTimestamps = true
        playSoundEffects = false
        autoClearAfterPaste = false
        skipDuplicates = true
        showCharacterCount = false
        confirmBeforeClear = false
        copyAndRecordShortcut = "⌃Q"
        toggleWindowShortcut = "⌃⌥⌘C"
        pasteNextShortcut = "⌃W"
        pasteAllShortcut = "⌃E"
        clearAllShortcut = "⌃X"
    }
}
