# ClipQueue - Development Guide

## Quick Start

```bash
# Open project
cd ~/dev/ClipQueue
open ClipQueue.xcodeproj

# Build in Xcode (Cmd+B)
# Then deploy to stable location:
./rebuild_stable.sh
```

## Why the Stable Build Location?

**Problem**: Every time Xcode rebuilds, the app gets a new signature. macOS treats it as a "different" app and revokes Accessibility permissions.

**Solution**: Copy the build to `~/Applications/ClipQueue.app` after each rebuild. This location stays stable, so permissions persist.

## Development Workflow

1. **Make changes** in Xcode
2. **Build** with `Cmd+B` (don't use `Cmd+R` - it runs from DerivedData)
3. **Deploy** with `./rebuild_stable.sh`
4. **Test** - the app launches from `~/Applications/`

## Scripts

### `rebuild_stable.sh`
Copies latest Xcode build to `~/Applications/ClipQueue.app` and launches it.

```bash
./rebuild_stable.sh
```

### `cleanup_old_builds.sh`
Removes old DerivedData builds to prevent confusion in Accessibility settings.

```bash
./cleanup_old_builds.sh
```

## Accessibility Permissions Setup

### First Time Setup

1. Build and run `./rebuild_stable.sh`
2. Open **System Settings** → Privacy & Security → Accessibility
3. Click `+` button
4. Navigate to: `/Users/YOUR_USERNAME/Applications/ClipQueue.app`
5. Add it and toggle ON

### After Each Rebuild

If you used `./rebuild_stable.sh`, permissions should persist. If not:

1. Remove ALL ClipQueue entries from Accessibility settings
2. Close and reopen System Settings
3. Add the one from `~/Applications/ClipQueue.app` (look for today's date)
4. Toggle ON

## Common Issues

### "Multiple ClipQueue apps in Accessibility settings"

This happens when:
- Old DerivedData builds still exist
- You added the wrong location

**Fix**: Run `./cleanup_old_builds.sh` and re-add from `~/Applications/`

### "Shortcuts registered but don't work"

Check console for: `⚠️ Accessibility permissions not granted!`

**Fix**: Follow Accessibility setup steps above

### "Can't find the right ClipQueue to add"

When adding to Accessibility, you might see multiple ClipQueue apps. Choose the one:
- From `/Users/YOUR_USERNAME/Applications/`
- With today's date
- NOT from DerivedData

## Project Structure

```
ClipQueue/
├── Sources/
│   ├── ClipQueue/
│   │   ├── ClipQueueApp.swift          # Main entry point
│   │   ├── AppDelegate.swift            # Window/menu bar management
│   │   └── Assets.xcassets/            # App icons
│   ├── Models/
│   │   ├── ClipboardItem.swift         # Queue item model
│   │   └── Preferences.swift           # Settings model
│   ├── Services/
│   │   ├── ClipboardMonitor.swift      # Polls NSPasteboard
│   │   ├── QueueManager.swift          # FIFO queue logic
│   │   └── KeyboardShortcutManager.swift # Carbon hotkeys + paste simulation
│   └── Views/
│       ├── QueueView.swift             # Main window UI
│       └── PreferencesView.swift       # Settings UI
├── ClipQueue.xcodeproj/
├── Info.plist                          # LSUIElement = true (menu bar only)
├── rebuild_stable.sh                   # Deploy script
├── cleanup_old_builds.sh               # Cleanup script
└── README.md
```

## Key Technical Details

### Clipboard Monitoring
- Polls `NSPasteboard.general` every 0.5 seconds
- Compares `changeCount` to detect new copies
- Only captures text (images not yet supported)

### Queue Management (FIFO)
- New items: `items.append(item)` (added to end)
- Paste: `items.removeFirst()` (remove from front)
- Display: Index 0 (oldest) shown at top

### Keyboard Shortcuts
- Uses Carbon API (`RegisterEventHotKey`)
- Requires Accessibility permissions for key simulation
- Simulates `Cmd+C` and `Cmd+V` using `CGEvent`

### Window Management
- AppKit `NSWindow` with `.floating` level (always on top)
- SwiftUI content via `NSHostingView`
- Position/size persisted in `UserDefaults`

## Testing Checklist

- [ ] ⌃Q - Copy and record (simulates Cmd+C)
- [ ] ⌃⌥⌘C - Toggle window show/hide
- [ ] ⌃W - Paste next item (oldest)
- [ ] ⌃E - Paste all items
- [ ] ⌃X - Clear all items
- [ ] Menu bar icon toggles window
- [ ] Window stays on top
- [ ] Window position/size remembered
- [ ] Queue count in title
- [ ] Individual item delete (X button)
- [ ] Clear button empties queue
- [ ] Preferences window opens (gear icon)

## Pending Features

1. **Drag & Drop Reordering** - Items have dashed borders but not functional yet
2. **Shortcut Customization** - Preferences shows shortcuts but can't change them
3. **Preferences Wiring** - Toggles exist but don't do anything yet:
   - Launch at login
   - Keep window on top
   - Show in menu bar
   - Queue size limit

## Debugging

### Console Messages

**Good**:
```
✅ ClipQueue started
✅ Accessibility permissions granted
⌨️ Keyboard shortcuts registered
```

**Bad**:
```
⚠️ Accessibility permissions not granted!
⚠️ Failed to register hotkey
```

### Check Permissions Programmatically

The app checks on startup and prints a detailed message if permissions are missing.

### View Logs

```bash
# Watch logs in real-time
log stream --predicate 'process == "ClipQueue"' --level debug

# Or use Console.app and filter for "ClipQueue"
```

## Release Preparation (Future)

For distributing to users:

1. **Code signing** - Need Apple Developer account ($99/year)
2. **Notarization** - Required for Gatekeeper
3. **DMG creation** - For easy installation
4. **GitHub releases** - Distribute via releases page

Currently: Development builds only (not signed/notarized)
