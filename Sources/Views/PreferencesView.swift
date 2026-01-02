import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PreferencesView: View {
    @ObservedObject var preferences = Preferences.shared
    @State private var selectedTab = 0
    let categoryStore: CategoryStore?

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView(preferences: preferences)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)

            ShortcutsPreferencesView(preferences: preferences)
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(1)

            AppearancePreferencesView(preferences: preferences)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
                .tag(2)

            BehaviorPreferencesView(preferences: preferences)
                .tabItem {
                    Label("Behavior", systemImage: "hand.tap")
                }
                .tag(3)

            if let categoryStore {
                CategoriesPreferencesView(categoryStore: categoryStore)
                    .tabItem {
                        Label("Categories", systemImage: "tag")
                    }
                    .tag(4)
            }
        }
        .frame(width: 620, height: 560)
        .tabViewStyle(.automatic)
        .tint(accentColor)
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject var preferences: Preferences
    @State private var showSymbolPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Startup
                VStack(alignment: .leading, spacing: 8) {
                    Text("Startup")
                        .font(.headline)

                    Toggle("Launch at login", isOn: $preferences.launchAtLogin)

                    Text("ClipQueue will start automatically when you log in.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Window
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window")
                        .font(.headline)

                    Toggle("Keep window on top", isOn: $preferences.keepWindowOnTop)

                    Text("The queue window will stay above other windows.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Show in menu bar", isOn: $preferences.showInMenuBar)

                    Text("Show the clipboard icon in the menu bar.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Show queue count on Dock icon", isOn: $preferences.showDockBadge)

                    Text("Display a badge with the number of items in the queue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Menu Bar Icon
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Bar Icon")
                        .font(.headline)

                    HStack {
                        Text("Icon style")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.menuBarIconStyle) {
                            ForEach(MenuBarIconStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    if preferences.menuBarIconStyle == .sfSymbol {
                        HStack {
                            Text("SF Symbol")
                                .frame(width: 120, alignment: .leading)

                            Button {
                                showSymbolPicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    if let image = NSImage(systemSymbolName: preferences.customMenuBarSymbol, accessibilityDescription: nil) {
                                        Image(nsImage: image)
                                            .frame(width: 16, height: 16)
                                    }
                                    Text(preferences.customMenuBarSymbol)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "square.grid.2x2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(width: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color(NSColor.separatorColor).opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Click to browse SF Symbols or enter a custom name.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if preferences.menuBarIconStyle == .custom {
                        HStack {
                            Text("Image path")
                                .frame(width: 120, alignment: .leading)
                            TextField("Path to image", text: $preferences.customMenuBarImagePath)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)

                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.allowedContentTypes = [.png, .jpeg, .tiff]
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    preferences.customMenuBarImagePath = url.path
                                }
                            }
                        }

                        Text("Use a 18x18 or 36x36 pixel PNG image for best results.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // MARK: - Monitoring
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monitoring")
                        .font(.headline)

                    Toggle("Record history", isOn: $preferences.historyEnabled)
                    Toggle("Show app icons", isOn: $preferences.showAppIcons)
                    Toggle("Pause monitoring when window is hidden", isOn: $preferences.pauseMonitoringWhenHidden)

                    Text("History and icons improve context, while pausing monitoring can reduce background work.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Limits
                VStack(alignment: .leading, spacing: 8) {
                    Text("Limits")
                        .font(.headline)

                    HStack {
                        Text("Max queue size")
                            .frame(width: 120, alignment: .leading)
                        Stepper(value: $preferences.maxQueueSize, in: 10...1000, step: 10) {
                            Text("\(preferences.maxQueueSize) items")
                                .frame(width: 80, alignment: .trailing)
                        }
                    }

                    HStack {
                        Text("History retention")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.historyRetentionDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("1 year").tag(365)
                            Text("Forever").tag(0)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Text("Older history items will be automatically removed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        preferences.resetToDefaults()
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $preferences.customMenuBarSymbol)
        }
    }
}

struct ShortcutsPreferencesView: View {
    @ObservedObject var preferences: Preferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 14) {
                ShortcutRow(
                    label: "Copy and record:",
                    shortcut: $preferences.copyAndRecordShortcut,
                    description: "Copy selected text and add to queue (alternative to Cmd+C)"
                )
                
                ShortcutRow(
                    label: "Toggle window:",
                    shortcut: $preferences.toggleWindowShortcut,
                    description: "Show or hide the ClipQueue window"
                )
                
                ShortcutRow(
                    label: "Paste next item:",
                    shortcut: $preferences.pasteNextShortcut,
                    description: "Paste the oldest item from the queue"
                )
                
                ShortcutRow(
                    label: "Paste all items:",
                    shortcut: $preferences.pasteAllShortcut,
                    description: "Paste all items from the queue"
                )
                
                ShortcutRow(
                    label: "Clear all items:",
                    shortcut: $preferences.clearAllShortcut,
                    description: "Remove all items from the queue"
                )
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 12) {
                Text("Note: Changes to shortcuts require restarting ClipQueue to take effect.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                }
                .controlSize(.small)
            }
            
            Spacer()
        }
        .padding(20)
    }
}

struct ShortcutRow: View {
    let label: String
    @Binding var shortcut: String
    let description: String
    @State private var isRecording = false
    
    var body: some View {
        GridRow {
            Text(label)
                .frame(width: 170, alignment: .leading)
            
            Button(action: {
                isRecording.toggle()
            }) {
                ShortcutKeyView(text: shortcut, isRecording: isRecording)
            }
            .buttonStyle(.plain)
            
            if isRecording {
                Text("Press keys…")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            } else {
                Color.clear
                    .frame(width: 1, height: 1)
            }
        }
        
        GridRow {
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .gridCellColumns(3)
        }
    }
}

struct ShortcutKeyView: View {
    let text: String
    let isRecording: Bool

    var body: some View {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(isRecording ? .primary : .secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .frame(minWidth: 84)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color(NSColor.separatorColor).opacity(0.6))
            )
    }
}

struct BehaviorPreferencesView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Item Interaction
                VStack(alignment: .leading, spacing: 8) {
                    Text("Item Interaction")
                        .font(.headline)

                    HStack {
                        Text("Double-click action")
                            .frame(width: 140, alignment: .leading)
                        Picker("", selection: $preferences.doubleClickAction) {
                            ForEach(DoubleClickAction.allCases) { action in
                                Text(action.displayName).tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Text("What happens when you double-click a clipboard item.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Display Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Options")
                        .font(.headline)

                    Toggle("Show timestamps", isOn: $preferences.showTimestamps)
                    Toggle("Show character count", isOn: $preferences.showCharacterCount)
                    Toggle("Highlight URLs in text", isOn: $preferences.highlightURLs)
                    Toggle("Show tooltips", isOn: $preferences.showTooltips)

                    Text("Additional information displayed with each clipboard item.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Text Processing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Processing")
                        .font(.headline)

                    Toggle("Trim whitespace", isOn: $preferences.trimWhitespace)

                    Text("Removes leading and trailing spaces from copied text.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Strip formatting when pasting", isOn: $preferences.stripFormatting)

                    Text("Pastes plain text without rich text formatting.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Clipboard Behavior
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clipboard Behavior")
                        .font(.headline)

                    Toggle("Skip duplicate items", isOn: $preferences.skipDuplicates)
                    Toggle("Auto-clear item after pasting", isOn: $preferences.autoClearAfterPaste)
                    Toggle("Confirm before clearing all", isOn: $preferences.confirmBeforeClear)

                    Text("Control how clipboard items are captured and managed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Notifications & Feedback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications & Feedback")
                        .font(.headline)

                    Toggle("Play sound effects", isOn: $preferences.playSoundEffects)

                    if preferences.playSoundEffects {
                        HStack {
                            Text("Copy sound")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: $preferences.copySoundEffect) {
                                ForEach(CopySoundEffect.allCases) { effect in
                                    Text(effect.displayName).tag(effect)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 120)

                            Button {
                                SoundManager.shared.previewCopySound(preferences.copySoundEffect)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                            }
                            .buttonStyle(.borderless)
                            .help("Preview sound")
                        }

                        HStack {
                            Text("Paste sound")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: $preferences.pasteSoundEffect) {
                                ForEach(PasteSoundEffect.allCases) { effect in
                                    Text(effect.displayName).tag(effect)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 120)

                            Button {
                                SoundManager.shared.previewPasteSound(preferences.pasteSoundEffect)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                            }
                            .buttonStyle(.borderless)
                            .help("Preview sound")
                        }
                    }

                    Toggle("Notify when item copied", isOn: $preferences.notifyOnCopy)

                    Text("Audio and visual feedback for clipboard operations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Window Behavior
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window Behavior")
                        .font(.headline)

                    HStack {
                        Text("Window style")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.windowStyle) {
                            ForEach(WindowStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Text(preferences.windowStyle.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Auto-hide toolbar", isOn: $preferences.autoHideToolbar)
                }

                Spacer()

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        preferences.resetToDefaults()
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct AppearancePreferencesView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Theme
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.headline)

                    Picker("Appearance", selection: $preferences.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)

                    Text("Choose between light, dark, or system appearance.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Liquid Glass
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass")
                        .font(.headline)

                    HStack {
                        Text("Glass variant")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.glassVariant) {
                            ForEach(GlassVariant.allCases) { variant in
                                Text(variant.displayName).tag(variant)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 180)
                    }

                    Text(preferences.glassVariant.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Material")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.materialThickness) {
                            ForEach(MaterialThickness.allCases) { thickness in
                                Text(thickness.displayName).tag(thickness)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Text(preferences.materialThickness.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Opacity")
                            .frame(width: 120, alignment: .leading)
                        Slider(value: $preferences.windowTranslucency, in: 0.2...1.0, step: 0.05)
                            .frame(maxWidth: 180)
                        Text(String(format: "%.0f%%", preferences.windowTranslucency * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }

                    HStack {
                        Text("Blur intensity")
                            .frame(width: 120, alignment: .leading)
                        Slider(value: $preferences.blurIntensity, in: 0.5...1.5, step: 0.1)
                            .frame(maxWidth: 180)
                        Text(String(format: "%.0f%%", preferences.blurIntensity * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }

                    Toggle("Enable vibrancy effects", isOn: $preferences.useVibrancy)
                    Toggle("Show shadows", isOn: $preferences.showShadows)
                }

                Divider()

                // MARK: - Accent Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accent Color")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                        ForEach(AccentColorOption.allCases) { option in
                            AccentColorButton(
                                option: option,
                                isSelected: !preferences.useCustomAccentColor && preferences.accentColorOption == option
                            ) {
                                preferences.useCustomAccentColor = false
                                preferences.accentColorOption = option
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Toggle("Use custom color", isOn: $preferences.useCustomAccentColor)

                    if preferences.useCustomAccentColor {
                        HStack(spacing: 12) {
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: preferences.customAccentColorHex) },
                                set: { newColor in
                                    if let hex = newColor.toHex() {
                                        preferences.customAccentColorHex = hex
                                    }
                                }
                            ))
                            .labelsHidden()
                            .frame(width: 40, height: 28)

                            TextField("Hex color", text: $preferences.customAccentColorHex)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)

                            Text("Click the color well or enter hex code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Choose accent color for buttons, selections, and highlights.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // MARK: - Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display")
                        .font(.headline)

                    HStack {
                        Text("Text size")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.textSize) {
                            ForEach(TextSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }

                    HStack {
                        Text("Preview lines")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.showPreviewLines) {
                            Text("1 line").tag(1)
                            Text("2 lines").tag(2)
                            Text("3 lines").tag(3)
                            Text("4 lines").tag(4)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Toggle("Compact mode", isOn: $preferences.compactMode)
                }

                Divider()

                // MARK: - Item Style
                VStack(alignment: .leading, spacing: 8) {
                    Text("Item Style")
                        .font(.headline)

                    HStack {
                        Text("Row density")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.rowDensity) {
                            ForEach(RowDensity.allCases) { density in
                                Text(density.displayName).tag(density)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    HStack {
                        Text("Corner style")
                            .frame(width: 120, alignment: .leading)
                        Picker("", selection: $preferences.cornerStyle) {
                            ForEach(CornerStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    Toggle("Show item borders", isOn: $preferences.showBorders)
                    Toggle("Show item index numbers", isOn: $preferences.showItemIndex)
                }

                Divider()

                // MARK: - Animations & Accessibility
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animations & Accessibility")
                        .font(.headline)

                    HStack {
                        Text("Animation speed")
                            .frame(width: 120, alignment: .leading)
                        Slider(value: $preferences.animationSpeed, in: 0.5...2.0, step: 0.1)
                            .frame(maxWidth: 180)
                        Text(String(format: "%.1fx", preferences.animationSpeed))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }

                    Toggle("Reduce motion", isOn: $preferences.reduceMotion)

                    Text("Reduces animations for accessibility and performance.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        preferences.resetToDefaults()
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Accent Color Button

struct AccentColorButton: View {
    let option: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(option.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .shadow(color: option.color.opacity(0.4), radius: isSelected ? 4 : 0)

                Text(option.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoriesPreferencesView: View {
    @Bindable var categoryStore: CategoryStore
    @State private var newCategoryName = ""
    @State private var selectedColorHex = CategoryColorOption.options.first?.hex ?? "#4F6BED"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TextField("New category", text: $newCategoryName)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 180)

                    Picker("Color", selection: $selectedColorHex) {
                        ForEach(CategoryColorOption.options) { option in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 10, height: 10)
                                Text(option.name)
                            }
                            .tag(option.hex)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Add") {
                        categoryStore.create(name: newCategoryName, colorHex: selectedColorHex)
                        newCategoryName = ""
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Text("Categories are used for color-coded organization.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            if categoryStore.categories.isEmpty {
                Text("No categories yet.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(categoryStore.categories, id: \.id) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 10, height: 10)
                            Text(category.name)
                            Spacer()
                            Button {
                                categoryStore.delete(category)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Delete category")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(minHeight: 160)
            }

            Spacer()
        }
        .padding(20)
    }
}

struct CategoryColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    var color: Color { Color(hex: hex) }

    static let options: [CategoryColorOption] = [
        CategoryColorOption(name: "Blue", hex: "#4F6BED"),
        CategoryColorOption(name: "Green", hex: "#2FA866"),
        CategoryColorOption(name: "Orange", hex: "#F2994A"),
        CategoryColorOption(name: "Red", hex: "#EB5757"),
        CategoryColorOption(name: "Purple", hex: "#9B51E0"),
        CategoryColorOption(name: "Gray", hex: "#8E8E93")
    ]
}
