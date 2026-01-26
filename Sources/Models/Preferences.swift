import Foundation
import ServiceManagement
import AppKit
import Carbon

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

    var contentSpacing: CGFloat {
        switch self {
        case .comfortable: return 4
        case .standard: return 3
        case .compact: return 2
        }
    }

    var rowSpacing: CGFloat {
        switch self {
        case .comfortable: return 10
        case .standard: return 8
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

// MARK: - Sound Effects

enum CopySoundEffect: String, CaseIterable, Identifiable {
    case none = "none"
    case pop = "pop"
    case tink = "tink"
    case glass = "glass"
    case morse = "morse"
    case purr = "purr"
    case submarine = "submarine"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .pop: return "Pop"
        case .tink: return "Tink"
        case .glass: return "Glass"
        case .morse: return "Morse"
        case .purr: return "Purr"
        case .submarine: return "Submarine"
        }
    }

    var systemSoundName: String? {
        switch self {
        case .none: return nil
        case .pop: return "Pop"
        case .tink: return "Tink"
        case .glass: return "Glass"
        case .morse: return "Morse"
        case .purr: return "Purr"
        case .submarine: return "Submarine"
        }
    }
}

enum PasteSoundEffect: String, CaseIterable, Identifiable {
    case none = "none"
    case pop = "pop"
    case tink = "tink"
    case blow = "blow"
    case bottle = "bottle"
    case frog = "frog"
    case funk = "funk"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .pop: return "Pop"
        case .tink: return "Tink"
        case .blow: return "Blow"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .funk: return "Funk"
        }
    }

    var systemSoundName: String? {
        switch self {
        case .none: return nil
        case .pop: return "Pop"
        case .tink: return "Tink"
        case .blow: return "Blow"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .funk: return "Funk"
        }
    }
}

// MARK: - Menu Bar Icon

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case `default` = "default"
    case sfSymbol = "sfSymbol"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .sfSymbol: return "SF Symbol"
        case .custom: return "Custom Image"
        }
    }
}

enum QueueTab: String, CaseIterable, Identifiable {
    case queue
    case favorites
    case history
    case recents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .queue: return "Queue"
        case .favorites: return "Favorites"
        case .history: return "History"
        case .recents: return "Recents"
        }
    }
}

enum QueuePasteNewlineTrigger: String, CaseIterable, Identifiable {
    case none = "none"
    case enter = "enter"
    case shiftEnter = "shiftEnter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Off"
        case .enter: return "Enter"
        case .shiftEnter: return "Shift + Enter"
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

    @Published var showHistoryTab: Bool {
        didSet {
            UserDefaults.standard.set(showHistoryTab, forKey: "showHistoryTab")
        }
    }

    @Published var showFavoritesTab: Bool {
        didSet {
            UserDefaults.standard.set(showFavoritesTab, forKey: "showFavoritesTab")
        }
    }

    @Published var showRecentsTab: Bool {
        didSet {
            UserDefaults.standard.set(showRecentsTab, forKey: "showRecentsTab")
        }
    }

    @Published var selectedQueueTab: QueueTab {
        didSet {
            UserDefaults.standard.set(selectedQueueTab.rawValue, forKey: "selectedQueueTab")
        }
    }

    @Published var returnToQueueOnShow: Bool {
        didSet {
            UserDefaults.standard.set(returnToQueueOnShow, forKey: "returnToQueueOnShow")
        }
    }

    @Published var showAppIcons: Bool {
        didSet {
            UserDefaults.standard.set(showAppIcons, forKey: "showAppIcons")
        }
    }

    @Published var sourceAppIconSize: Double {
        didSet {
            UserDefaults.standard.set(sourceAppIconSize, forKey: "sourceAppIconSize")
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

    @Published var appendNewlineAfterPaste: Bool {
        didSet {
            UserDefaults.standard.set(appendNewlineAfterPaste, forKey: "appendNewlineAfterPaste")
        }
    }

    @Published var pressEnterAfterPaste: Bool {
        didSet {
            UserDefaults.standard.set(pressEnterAfterPaste, forKey: "pressEnterAfterPaste")
        }
    }

    @Published var queuePasteNewlineTrigger: QueuePasteNewlineTrigger {
        didSet {
            UserDefaults.standard.set(queuePasteNewlineTrigger.rawValue, forKey: "queuePasteNewlineTrigger")
        }
    }

    @Published var autoResizeWindowHeight: Bool {
        didSet {
            UserDefaults.standard.set(autoResizeWindowHeight, forKey: "autoResizeWindowHeight")
        }
    }

    // Keyboard shortcuts
    @Published var copyAndRecordShortcut: KeyboardShortcut {
        didSet {
            saveShortcut(copyAndRecordShortcut, key: "copyAndRecordShortcut")
        }
    }

    @Published var toggleWindowShortcut: KeyboardShortcut {
        didSet {
            saveShortcut(toggleWindowShortcut, key: "toggleWindowShortcut")
        }
    }

    @Published var pasteNextShortcut: KeyboardShortcut {
        didSet {
            saveShortcut(pasteNextShortcut, key: "pasteNextShortcut")
        }
    }

    @Published var pasteAllShortcut: KeyboardShortcut {
        didSet {
            saveShortcut(pasteAllShortcut, key: "pasteAllShortcut")
        }
    }

    @Published var clearAllShortcut: KeyboardShortcut {
        didSet {
            saveShortcut(clearAllShortcut, key: "clearAllShortcut")
        }
    }

    // Sound effects
    @Published var copySoundEffect: CopySoundEffect {
        didSet {
            UserDefaults.standard.set(copySoundEffect.rawValue, forKey: "copySoundEffect")
        }
    }

    @Published var pasteSoundEffect: PasteSoundEffect {
        didSet {
            UserDefaults.standard.set(pasteSoundEffect.rawValue, forKey: "pasteSoundEffect")
        }
    }

    // Menu bar icon customization
    @Published var menuBarIconStyle: MenuBarIconStyle {
        didSet {
            UserDefaults.standard.set(menuBarIconStyle.rawValue, forKey: "menuBarIconStyle")
        }
    }

    @Published var customMenuBarSymbol: String {
        didSet {
            UserDefaults.standard.set(customMenuBarSymbol, forKey: "customMenuBarSymbol")
        }
    }

    @Published var customMenuBarImagePath: String {
        didSet {
            UserDefaults.standard.set(customMenuBarImagePath, forKey: "customMenuBarImagePath")
        }
    }

    // Custom accent color (hex)
    @Published var customAccentColorHex: String {
        didSet {
            UserDefaults.standard.set(customAccentColorHex, forKey: "customAccentColorHex")
        }
    }

    @Published var useCustomAccentColor: Bool {
        didSet {
            UserDefaults.standard.set(useCustomAccentColor, forKey: "useCustomAccentColor")
        }
    }

    // Dock badge
    @Published var showDockBadge: Bool {
        didSet {
            UserDefaults.standard.set(showDockBadge, forKey: "showDockBadge")
        }
    }

    // Mini mode (minimize to icon)
    @Published var miniModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(miniModeEnabled, forKey: "miniModeEnabled")
        }
    }

    @Published var miniModeShortcut: String {
        didSet {
            UserDefaults.standard.set(miniModeShortcut, forKey: "miniModeShortcut")
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

        let savedShowHistoryTab = UserDefaults.standard.object(forKey: "showHistoryTab")
        self.showHistoryTab = savedShowHistoryTab == nil ? true : UserDefaults.standard.bool(forKey: "showHistoryTab")

        let savedShowFavoritesTab = UserDefaults.standard.object(forKey: "showFavoritesTab")
        self.showFavoritesTab = savedShowFavoritesTab == nil ? true : UserDefaults.standard.bool(forKey: "showFavoritesTab")

        let savedShowRecentsTab = UserDefaults.standard.object(forKey: "showRecentsTab")
        self.showRecentsTab = savedShowRecentsTab == nil ? true : UserDefaults.standard.bool(forKey: "showRecentsTab")

        let savedSelectedTab = UserDefaults.standard.string(forKey: "selectedQueueTab") ?? QueueTab.queue.rawValue
        self.selectedQueueTab = QueueTab(rawValue: savedSelectedTab) ?? .queue

        let savedReturnToQueue = UserDefaults.standard.object(forKey: "returnToQueueOnShow")
        self.returnToQueueOnShow = savedReturnToQueue == nil ? false : UserDefaults.standard.bool(forKey: "returnToQueueOnShow")

        let savedIcons = UserDefaults.standard.object(forKey: "showAppIcons")
        self.showAppIcons = savedIcons == nil ? true : UserDefaults.standard.bool(forKey: "showAppIcons")

        let savedIconSize = UserDefaults.standard.object(forKey: "sourceAppIconSize")
        self.sourceAppIconSize = savedIconSize == nil ? 16.0 : UserDefaults.standard.double(forKey: "sourceAppIconSize")

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

        // Remove after pasting defaults to true (the user's preferred behavior)
        let savedAutoClear = UserDefaults.standard.object(forKey: "autoClearAfterPaste")
        self.autoClearAfterPaste = savedAutoClear == nil ? true : UserDefaults.standard.bool(forKey: "autoClearAfterPaste")

        let savedSkipDupes = UserDefaults.standard.object(forKey: "skipDuplicates")
        self.skipDuplicates = savedSkipDupes == nil ? true : UserDefaults.standard.bool(forKey: "skipDuplicates")

        self.showCharacterCount = UserDefaults.standard.bool(forKey: "showCharacterCount")
        self.confirmBeforeClear = UserDefaults.standard.bool(forKey: "confirmBeforeClear")
        self.appendNewlineAfterPaste = UserDefaults.standard.bool(forKey: "appendNewlineAfterPaste")
        self.pressEnterAfterPaste = UserDefaults.standard.bool(forKey: "pressEnterAfterPaste")

        let savedQueueNewline = UserDefaults.standard.string(forKey: "queuePasteNewlineTrigger") ?? QueuePasteNewlineTrigger.none.rawValue
        self.queuePasteNewlineTrigger = QueuePasteNewlineTrigger(rawValue: savedQueueNewline) ?? .none

        let savedAutoResize = UserDefaults.standard.object(forKey: "autoResizeWindowHeight")
        self.autoResizeWindowHeight = savedAutoResize == nil ? false : UserDefaults.standard.bool(forKey: "autoResizeWindowHeight")

        // Load shortcuts or use defaults
        self.copyAndRecordShortcut = Self.loadShortcut(
            key: "copyAndRecordShortcut",
            legacyKey: "copyAndRecordShortcut",
            fallback: KeyboardShortcut(
                keyCode: UInt16(kVK_ANSI_Q),
                modifiers: NSEvent.ModifierFlags.control.rawValue,
                keyEquivalent: "q"
            )
        )
        self.toggleWindowShortcut = Self.loadShortcut(
            key: "toggleWindowShortcut",
            legacyKey: "toggleWindowShortcut",
            fallback: KeyboardShortcut(
                keyCode: UInt16(kVK_ANSI_C),
                modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue,
                keyEquivalent: "c"
            )
        )
        self.pasteNextShortcut = Self.loadShortcut(
            key: "pasteNextShortcut",
            legacyKey: "pasteNextShortcut",
            fallback: KeyboardShortcut(
                keyCode: UInt16(kVK_ANSI_W),
                modifiers: NSEvent.ModifierFlags.control.rawValue,
                keyEquivalent: "w"
            )
        )
        self.pasteAllShortcut = Self.loadShortcut(
            key: "pasteAllShortcut",
            legacyKey: "pasteAllShortcut",
            fallback: KeyboardShortcut(
                keyCode: UInt16(kVK_ANSI_E),
                modifiers: NSEvent.ModifierFlags.control.rawValue,
                keyEquivalent: "e"
            )
        )
        self.clearAllShortcut = Self.loadShortcut(
            key: "clearAllShortcut",
            legacyKey: "clearAllShortcut",
            fallback: KeyboardShortcut(
                keyCode: UInt16(kVK_ANSI_X),
                modifiers: NSEvent.ModifierFlags.control.rawValue,
                keyEquivalent: "x"
            )
        )

        // Sound effects
        let savedCopySound = UserDefaults.standard.string(forKey: "copySoundEffect") ?? "tink"
        self.copySoundEffect = CopySoundEffect(rawValue: savedCopySound) ?? .tink

        let savedPasteSound = UserDefaults.standard.string(forKey: "pasteSoundEffect") ?? "pop"
        self.pasteSoundEffect = PasteSoundEffect(rawValue: savedPasteSound) ?? .pop

        // Menu bar icon customization
        let savedMenuBarStyle = UserDefaults.standard.string(forKey: "menuBarIconStyle") ?? "default"
        self.menuBarIconStyle = MenuBarIconStyle(rawValue: savedMenuBarStyle) ?? .default

        self.customMenuBarSymbol = UserDefaults.standard.string(forKey: "customMenuBarSymbol") ?? "list.clipboard"
        self.customMenuBarImagePath = UserDefaults.standard.string(forKey: "customMenuBarImagePath") ?? ""

        // Custom accent color
        self.customAccentColorHex = UserDefaults.standard.string(forKey: "customAccentColorHex") ?? "#007AFF"
        self.useCustomAccentColor = UserDefaults.standard.bool(forKey: "useCustomAccentColor")

        // Dock badge
        let savedDockBadge = UserDefaults.standard.object(forKey: "showDockBadge")
        self.showDockBadge = savedDockBadge == nil ? true : UserDefaults.standard.bool(forKey: "showDockBadge")

        // Mini mode
        self.miniModeEnabled = UserDefaults.standard.bool(forKey: "miniModeEnabled")
        self.miniModeShortcut = UserDefaults.standard.string(forKey: "miniModeShortcut") ?? "⌃⌥M"
    }
    
    func resetToDefaults() {
        launchAtLogin = false
        keepWindowOnTop = true
        showInMenuBar = true
        historyEnabled = true
        showHistoryTab = true
        showFavoritesTab = true
        showRecentsTab = true
        selectedQueueTab = .queue
        returnToQueueOnShow = false
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
        autoClearAfterPaste = true  // Default to removing items after paste
        skipDuplicates = true
        showCharacterCount = false
        confirmBeforeClear = false
        appendNewlineAfterPaste = false
        pressEnterAfterPaste = false
        queuePasteNewlineTrigger = .none
        autoResizeWindowHeight = false
        copyAndRecordShortcut = KeyboardShortcut(
            keyCode: UInt16(kVK_ANSI_Q),
            modifiers: NSEvent.ModifierFlags.control.rawValue,
            keyEquivalent: "q"
        )
        toggleWindowShortcut = KeyboardShortcut(
            keyCode: UInt16(kVK_ANSI_C),
            modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue,
            keyEquivalent: "c"
        )
        pasteNextShortcut = KeyboardShortcut(
            keyCode: UInt16(kVK_ANSI_W),
            modifiers: NSEvent.ModifierFlags.control.rawValue,
            keyEquivalent: "w"
        )
        pasteAllShortcut = KeyboardShortcut(
            keyCode: UInt16(kVK_ANSI_E),
            modifiers: NSEvent.ModifierFlags.control.rawValue,
            keyEquivalent: "e"
        )
        clearAllShortcut = KeyboardShortcut(
            keyCode: UInt16(kVK_ANSI_X),
            modifiers: NSEvent.ModifierFlags.control.rawValue,
            keyEquivalent: "x"
        )
        // Sound effects
        copySoundEffect = .tink
        pasteSoundEffect = .pop
        // Menu bar icon
        menuBarIconStyle = .default
        customMenuBarSymbol = "list.clipboard"
        customMenuBarImagePath = ""
        // Custom accent color
        customAccentColorHex = "#007AFF"
        useCustomAccentColor = false
        // Dock badge
        showDockBadge = true
        // Mini mode
        miniModeEnabled = false
        miniModeShortcut = "⌃⌥M"
    }

    private func saveShortcut(_ shortcut: KeyboardShortcut, key: String) {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadShortcut(key: String, legacyKey: String, fallback: KeyboardShortcut) -> KeyboardShortcut {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            return decoded
        }

        if let legacy = UserDefaults.standard.string(forKey: legacyKey),
           let parsed = parseLegacyShortcut(legacy) {
            return parsed
        }

        return fallback
    }

    private static func parseLegacyShortcut(_ legacy: String) -> KeyboardShortcut? {
        var modifiers: NSEvent.ModifierFlags = []
        var keyString = legacy

        let symbols: [(String, NSEvent.ModifierFlags)] = [
            ("⌃", .control),
            ("⌥", .option),
            ("⇧", .shift),
            ("⌘", .command)
        ]

        for (symbol, flag) in symbols {
            if keyString.contains(symbol) {
                modifiers.insert(flag)
                keyString = keyString.replacingOccurrences(of: symbol, with: "")
            }
        }

        let trimmedKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let keyCode = legacyKeyCode(for: trimmedKey) else { return nil }

        return KeyboardShortcut(
            keyCode: keyCode,
            modifiers: modifiers.rawValue,
            keyEquivalent: trimmedKey.lowercased()
        )
    }

    private static func legacyKeyCode(for key: String) -> UInt16? {
        if key.count == 1, let scalar = key.uppercased().unicodeScalars.first {
            switch scalar {
            case "A": return UInt16(kVK_ANSI_A)
            case "B": return UInt16(kVK_ANSI_B)
            case "C": return UInt16(kVK_ANSI_C)
            case "D": return UInt16(kVK_ANSI_D)
            case "E": return UInt16(kVK_ANSI_E)
            case "F": return UInt16(kVK_ANSI_F)
            case "G": return UInt16(kVK_ANSI_G)
            case "H": return UInt16(kVK_ANSI_H)
            case "I": return UInt16(kVK_ANSI_I)
            case "J": return UInt16(kVK_ANSI_J)
            case "K": return UInt16(kVK_ANSI_K)
            case "L": return UInt16(kVK_ANSI_L)
            case "M": return UInt16(kVK_ANSI_M)
            case "N": return UInt16(kVK_ANSI_N)
            case "O": return UInt16(kVK_ANSI_O)
            case "P": return UInt16(kVK_ANSI_P)
            case "Q": return UInt16(kVK_ANSI_Q)
            case "R": return UInt16(kVK_ANSI_R)
            case "S": return UInt16(kVK_ANSI_S)
            case "T": return UInt16(kVK_ANSI_T)
            case "U": return UInt16(kVK_ANSI_U)
            case "V": return UInt16(kVK_ANSI_V)
            case "W": return UInt16(kVK_ANSI_W)
            case "X": return UInt16(kVK_ANSI_X)
            case "Y": return UInt16(kVK_ANSI_Y)
            case "Z": return UInt16(kVK_ANSI_Z)
            case "0": return UInt16(kVK_ANSI_0)
            case "1": return UInt16(kVK_ANSI_1)
            case "2": return UInt16(kVK_ANSI_2)
            case "3": return UInt16(kVK_ANSI_3)
            case "4": return UInt16(kVK_ANSI_4)
            case "5": return UInt16(kVK_ANSI_5)
            case "6": return UInt16(kVK_ANSI_6)
            case "7": return UInt16(kVK_ANSI_7)
            case "8": return UInt16(kVK_ANSI_8)
            case "9": return UInt16(kVK_ANSI_9)
            default: break
            }
        }

        switch key.lowercased() {
        case "tab": return UInt16(kVK_Tab)
        case "return", "enter": return UInt16(kVK_Return)
        case "space": return UInt16(kVK_Space)
        default: return nil
        }
    }
}
