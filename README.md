# ClipQueue

A macOS menu bar app that queues clipboard items and lets you paste them sequentially using keyboard shortcuts.

## ✨ Features

- 📋 **Automatic clipboard monitoring** - Captures everything you copy
- ⌨️ **Keyboard shortcuts** - Paste without clicking
- 🪟 **Floating window** - Always on top, stays visible
- 🔄 **FIFO queue** - First copied, first pasted
- 💾 **Persistence** - Queue survives app restarts
- 🎯 **Drag to reorder** - Change paste order by dragging items
- 👋 **Intuitive cursors** - Open/closed hand feedback while dragging
- 🎨 **Clean UI** - Minimal, native macOS design

## 🚀 Getting Started

### Build & Run

1. Open the project:
   ```bash
   cd ~/dev/ClipQueue
   open ClipQueue.xcodeproj
   ```

2. Build in Xcode: `Cmd+B`

3. Deploy to stable location (avoids permission issues):
   ```bash
   ./rebuild_stable.sh
   ```

4. **Grant Accessibility Permissions** (required for keyboard shortcuts):
   - Open System Settings → Privacy & Security → Accessibility
   - Remove any old ClipQueue entries
   - Click `+` and add: `/Users/YOUR_USERNAME/Applications/ClipQueue.app`
   - Toggle it ON

5. Look for the clipboard icon in your menu bar

### Development Workflow

**Important**: Xcode rebuilds change the app signature, causing macOS to revoke Accessibility permissions each time. To avoid this:

1. Make changes in Xcode
2. Build with `Cmd+B`
3. Run `./rebuild_stable.sh` to deploy to `~/Applications/`
4. The app launches from the stable location (permissions persist!)

**Cleanup old builds** (optional):
```bash
./cleanup_old_builds.sh
```
This removes DerivedData builds that can cause confusion in Accessibility settings.

## ⌨️ Keyboard Shortcuts

- **⌃⌥⌘C** - Toggle window show/hide
- **⌃W** - Paste next item (oldest in queue)
- **⌃E** - Paste all items
- **⌃X** - Clear all items

## 📖 How to Use

### Basic Workflow

1. **Copy multiple items** (Cmd+C, Cmd+C, Cmd+C)
   - Each copy adds to the queue
   - Newest items appear at bottom
   - Oldest items appear at top

2. **Press ⌃W to paste**
   - Pastes the oldest item (top of queue)
   - Item is removed after pasting
   - Press ⌃W again for next item

3. **View your queue**
   - Click 📋 menu bar icon
   - Or press ⌃⌥⌘C
   - Floating window shows all items

### Advanced Features

- **Reorder items**: Drag and drop items in the queue
- **Delete item**: Hover over item, click X
- **Clear all**: Click "Clear" button or press ⌃X
- **Paste all**: Press ⌃E to paste everything at once

## 🎨 UI Features

### Floating Window
- Always stays on top of other windows
- Resizable - drag corners to resize
- Remembers position and size
- Shows item count in title: "ClipQueue (5)"

### Queue Display
- **Oldest at top** (pastes first) - marked with "• Next"
- **Newest at bottom** (pastes last)
- **Dashed borders** indicate drag-and-drop capability
- **Timestamps** show when each item was copied
- **Type icons** differentiate text vs URLs

## 🔧 Technical Details

### Architecture
- **SwiftUI** for modern UI
- **AppKit** for floating window and menu bar
- **Carbon** for global keyboard shortcuts
- **UserDefaults** for persistence

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later

## 📊 Project Structure

```
ClipQueue/
├── Sources/
│   ├── ClipQueue/
│   │   ├── ClipQueueApp.swift          # App entry point
│   │   └── AppDelegate.swift            # Window & lifecycle management
│   ├── Models/
│   │   └── ClipboardItem.swift          # Data model
│   ├── Services/
│   │   ├── ClipboardMonitor.swift       # Monitors system clipboard
│   │   ├── QueueManager.swift           # Queue logic (FIFO)
│   │   └── KeyboardShortcutManager.swift # Global hotkeys
│   └── Views/
│       └── QueueView.swift              # SwiftUI interface
└── ClipQueue.xcodeproj/
```

## 🐛 Troubleshooting

### Keyboard shortcuts not working?

**Most common issue**: Accessibility permissions pointing to wrong build location.

1. Open System Settings → Privacy & Security → Accessibility
2. Remove **ALL** ClipQueue entries (you might see multiple)
3. Close and reopen System Settings
4. Add the correct one: `/Users/YOUR_USERNAME/Applications/ClipQueue.app`
   - ⚠️ **NOT** from DerivedData or other locations!
   - Look for the one with today's date if multiple appear
5. Toggle it ON

**Still not working?**
- Make sure no other app is using the same shortcuts
- Check System Settings > Keyboard > Keyboard Shortcuts for conflicts
- Check Console.app for "Accessibility permissions not granted!" messages

### Window not staying on top?
- This is expected behavior - the window floats but doesn't steal focus
- Click the window to bring it forward if needed

### Items not being captured?
- Only text clipboard content is captured (images not yet supported)
- Make sure you're actually copying (Cmd+C), not just selecting

## 🎯 Roadmap

- [ ] Customizable keyboard shortcuts
- [ ] Preferences window
- [ ] Image support
- [ ] Search/filter functionality
- [ ] Categories and tags
- [ ] Launch at login option
- [ ] Sound effects
- [ ] Themes

## 📝 License

MIT License - Feel free to use and modify!

## 🙏 Acknowledgments

Inspired by PasteQueue from the Mac App Store.
