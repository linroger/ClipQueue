import SwiftUI
import AppKit

// MARK: - SF Symbol Option Model

struct SFSymbolOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let displayName: String

    init(_ name: String, displayName: String? = nil) {
        self.name = name
        self.displayName = displayName ?? name.replacingOccurrences(of: ".", with: " ").capitalized
    }

    static func hash(_ lhs: SFSymbolOption, _ rhs: SFSymbolOption) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    // Common menu bar symbols (quick access)
    static let menuBarSymbols: [SFSymbolOption] = [
        SFSymbolOption("list.clipboard", displayName: "List Clipboard"),
        SFSymbolOption("doc.on.clipboard", displayName: "Doc on Clipboard"),
        SFSymbolOption("clipboard", displayName: "Clipboard"),
        SFSymbolOption("clipboard.fill", displayName: "Clipboard Fill"),
        SFSymbolOption("square.on.square", displayName: "Square on Square"),
        SFSymbolOption("doc.on.doc", displayName: "Doc on Doc"),
        SFSymbolOption("rectangle.stack", displayName: "Rectangle Stack"),
        SFSymbolOption("tray.full", displayName: "Tray Full"),
        SFSymbolOption("archivebox", displayName: "Archive Box"),
        SFSymbolOption("folder", displayName: "Folder"),
        SFSymbolOption("note.text", displayName: "Note Text"),
        SFSymbolOption("list.bullet", displayName: "List Bullet"),
    ]

    // Comprehensive list of SF Symbols organized by category
    static let allSymbols: [String: [SFSymbolOption]] = [
        "Clipboard & Documents": [
            SFSymbolOption("list.clipboard"),
            SFSymbolOption("doc.on.clipboard"),
            SFSymbolOption("clipboard"),
            SFSymbolOption("clipboard.fill"),
            SFSymbolOption("doc.on.doc"),
            SFSymbolOption("doc.on.doc.fill"),
            SFSymbolOption("doc.text"),
            SFSymbolOption("doc.text.fill"),
            SFSymbolOption("doc.richtext"),
            SFSymbolOption("doc.plaintext"),
            SFSymbolOption("note.text"),
            SFSymbolOption("note.text.badge.plus"),
        ],
        "Lists & Stacks": [
            SFSymbolOption("list.bullet"),
            SFSymbolOption("list.bullet.rectangle"),
            SFSymbolOption("list.dash"),
            SFSymbolOption("list.number"),
            SFSymbolOption("list.star"),
            SFSymbolOption("rectangle.stack"),
            SFSymbolOption("rectangle.stack.fill"),
            SFSymbolOption("square.stack"),
            SFSymbolOption("square.stack.fill"),
            SFSymbolOption("square.on.square"),
            SFSymbolOption("square.on.square.dashed"),
        ],
        "Storage & Files": [
            SFSymbolOption("tray"),
            SFSymbolOption("tray.fill"),
            SFSymbolOption("tray.full"),
            SFSymbolOption("tray.full.fill"),
            SFSymbolOption("tray.2"),
            SFSymbolOption("tray.2.fill"),
            SFSymbolOption("archivebox"),
            SFSymbolOption("archivebox.fill"),
            SFSymbolOption("folder"),
            SFSymbolOption("folder.fill"),
            SFSymbolOption("folder.badge.plus"),
            SFSymbolOption("externaldrive"),
        ],
        "Text & Editing": [
            SFSymbolOption("text.alignleft"),
            SFSymbolOption("text.aligncenter"),
            SFSymbolOption("text.alignright"),
            SFSymbolOption("text.justify"),
            SFSymbolOption("text.quote"),
            SFSymbolOption("textformat"),
            SFSymbolOption("textformat.abc"),
            SFSymbolOption("pencil"),
            SFSymbolOption("pencil.circle"),
            SFSymbolOption("pencil.circle.fill"),
            SFSymbolOption("highlighter"),
            SFSymbolOption("scribble.variable"),
        ],
        "Interface & Windows": [
            SFSymbolOption("sidebar.left"),
            SFSymbolOption("sidebar.right"),
            SFSymbolOption("rectangle.split.3x1"),
            SFSymbolOption("rectangle.3.group"),
            SFSymbolOption("square.grid.2x2"),
            SFSymbolOption("square.grid.3x3"),
            SFSymbolOption("uiwindow.split.2x1"),
            SFSymbolOption("macwindow"),
            SFSymbolOption("macwindow.on.rectangle"),
            SFSymbolOption("menubar.rectangle"),
            SFSymbolOption("dock.rectangle"),
        ],
        "Actions & Commands": [
            SFSymbolOption("plus"),
            SFSymbolOption("plus.circle"),
            SFSymbolOption("plus.circle.fill"),
            SFSymbolOption("minus"),
            SFSymbolOption("minus.circle"),
            SFSymbolOption("xmark"),
            SFSymbolOption("xmark.circle"),
            SFSymbolOption("checkmark"),
            SFSymbolOption("checkmark.circle"),
            SFSymbolOption("checkmark.circle.fill"),
            SFSymbolOption("arrow.right"),
            SFSymbolOption("arrow.clockwise"),
        ],
        "Common Symbols": [
            SFSymbolOption("star"),
            SFSymbolOption("star.fill"),
            SFSymbolOption("heart"),
            SFSymbolOption("heart.fill"),
            SFSymbolOption("bolt"),
            SFSymbolOption("bolt.fill"),
            SFSymbolOption("bell"),
            SFSymbolOption("bell.fill"),
            SFSymbolOption("tag"),
            SFSymbolOption("tag.fill"),
            SFSymbolOption("bookmark"),
            SFSymbolOption("bookmark.fill"),
        ],
        "Objects": [
            SFSymbolOption("paperclip"),
            SFSymbolOption("link"),
            SFSymbolOption("pin"),
            SFSymbolOption("pin.fill"),
            SFSymbolOption("scissors"),
            SFSymbolOption("wand.and.stars"),
            SFSymbolOption("sparkles"),
            SFSymbolOption("gift"),
            SFSymbolOption("hammer"),
            SFSymbolOption("wrench"),
            SFSymbolOption("gearshape"),
            SFSymbolOption("gearshape.fill"),
        ],
        "Communication": [
            SFSymbolOption("bubble.left"),
            SFSymbolOption("bubble.right"),
            SFSymbolOption("bubble.left.and.bubble.right"),
            SFSymbolOption("quote.bubble"),
            SFSymbolOption("text.bubble"),
            SFSymbolOption("captions.bubble"),
            SFSymbolOption("ellipsis.bubble"),
            SFSymbolOption("message"),
            SFSymbolOption("message.fill"),
            SFSymbolOption("envelope"),
            SFSymbolOption("envelope.fill"),
            SFSymbolOption("phone"),
        ],
        "Media": [
            SFSymbolOption("play"),
            SFSymbolOption("play.fill"),
            SFSymbolOption("pause"),
            SFSymbolOption("pause.fill"),
            SFSymbolOption("stop"),
            SFSymbolOption("stop.fill"),
            SFSymbolOption("photo"),
            SFSymbolOption("photo.fill"),
            SFSymbolOption("camera"),
            SFSymbolOption("video"),
            SFSymbolOption("music.note"),
            SFSymbolOption("waveform"),
        ],
    ]

    /// Returns all symbols flattened into a single array
    static var allSymbolsFlat: [SFSymbolOption] {
        allSymbols.values.flatMap { $0 }
    }

    /// Returns category names sorted
    static var categoryNames: [String] {
        Array(allSymbols.keys).sorted()
    }
}

// MARK: - SF Symbol Picker View

struct SFSymbolPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var preferences = Preferences.shared
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @Binding var selectedSymbol: String

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    private var filteredSymbols: [SFSymbolOption] {
        let symbols: [SFSymbolOption]

        if let category = selectedCategory {
            // Use validated symbols from SFSymbolDatabase (filters unavailable symbols)
            symbols = SFSymbolDatabase.validatedSymbols(for: category)
        } else {
            // Get all validated symbols across all categories
            symbols = SFSymbolDatabase.allValidatedSymbols()
        }

        if searchText.isEmpty {
            return symbols
        } else {
            return symbols.filter { option in
                option.name.localizedCaseInsensitiveContains(searchText) ||
                option.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose SF Symbol")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search and filter
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search symbols...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color(NSColor.separatorColor).opacity(0.5))
                )

                // Category picker - uses comprehensive SFSymbolDatabase categories
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as String?)
                    ForEach(SFSymbolDatabase.categoryNames, id: \.self) { category in
                        Text(category).tag(category as String?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
            }
            .padding()

            Divider()

            // Symbol grid
            ScrollView {
                if filteredSymbols.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No symbols found")
                            .foregroundStyle(.secondary)
                        if !searchText.isEmpty {
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                        ForEach(filteredSymbols) { option in
                            SymbolGridItem(
                                option: option,
                                isSelected: selectedSymbol == option.name,
                                accentColor: accentColor
                            ) {
                                selectedSymbol = option.name
                            }
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer with current selection and actions
            HStack {
                // Current selection preview
                HStack(spacing: 8) {
                    if let image = NSImage(systemSymbolName: selectedSymbol, accessibilityDescription: nil) {
                        Image(nsImage: image)
                            .frame(width: 20, height: 20)
                    }
                    Text(selectedSymbol)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Custom symbol input
                TextField("Or enter custom symbol name", text: $selectedSymbol)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
            }
            .padding()
        }
        .frame(width: 520, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Symbol Grid Item

struct SymbolGridItem: View {
    let option: SFSymbolOption
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let image = NSImage(systemSymbolName: option.name, accessibilityDescription: nil) {
                    Image(nsImage: image)
                        .font(.title2)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.title2)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.tertiary)
                }

                Text(option.name.split(separator: ".").last.map(String.init) ?? option.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(width: 64, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help(option.displayName)
    }
}

// MARK: - Preview

#Preview {
    SFSymbolPickerView(selectedSymbol: .constant("list.clipboard"))
}
