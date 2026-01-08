# Bug Fixes Plan

## Issues Identified

### 1. UI Not Updating Automatically ✅
**Problem**: Items don't appear in queue until switching tabs
**Root Cause**: `queueManager.items` is `@Published` but SwiftUI might not be detecting changes
**Solution**: Verify `QueueManager` has proper `@Published` property and is an `ObservableObject`

### 2. Window Height Still Clipping Bottom Item ⚠️
**Problem**: Window height calculation is incorrect, clipping the bottom item
**Root Cause**: My previous calculation didn't account for all spacing properly
**Solution**: Re-calculate with actual measurements from UI components, add debug logging

### 3. Fn + Tab Shortcut Binding ⚠️
**Problem**: Can't bind shortcuts with Fn key
**Root Cause**: Fn key has special handling in macOS and may not be exposed as a modifier
**Solution**: Check if Fn key events can be captured, may need special handling or alternative approach

### 4. Recents Tab Shows All Items ⚠️
**Problem**: Recents tab shows all copied items, should only show pasted items
**Root Cause**: `ClipboardHistoryEntry` doesn't track paste events (line 1068 in QueueView.swift)
**Solution**:
  - Add `lastPastedDate: Date?` field to `ClipboardHistoryEntry`
  - Update field when items are pasted via `onPasteToPreviousApp` callback
  - Filter `recentEntries` to only items where `lastPastedDate != nil`
  - Sort by `lastPastedDate` descending

### 5. Spacebar Quick Look Popup ⚠️
**Problem**: Spacebar adds space to search bar instead of showing Quick Look
**Root Cause**: Search field is capturing spacebar events before KeyEventMonitor
**Solution**:
  - The Quick Look sheet already exists (line 51-53)
  - `showQuickLookForSelection()` already exists (line 450-457)
  - Problem is `shouldIgnoreKeyEvent()` returns true when search field is focused
  - Need to intercept spacebar BEFORE it reaches search field
  - Use custom NSTextField wrapper that ignores spacebar when not editing

### 6. Quick Look Popup Content ⚠️
**Problem**: Need to enhance Quick Look to show full text, stats, and app icon
**Root Cause**: `QuickLookPreview` component needs enhancement
**Solution**: Find and enhance QuickLookPreview with:
  - Full text display (scrollable)
  - Character count, word count, line count
  - Source app icon and name
  - Copy date/time
  - Type indicator
  - Close on second spacebar press

## Implementation Order

1. Fix Recents tab (add lastPastedDate tracking)
2. Fix spacebar Quick Look (search field event handling)
3. Enhance Quick Look popup (add stats and icon)
4. Fix window height (better calculation)
5. Fix UI updating (verify @Published)
6. Investigate Fn + Tab (may not be possible)
