# Drag & Drop Testing Guide

## Build & Deploy

```bash
# 1. Build in Xcode (Cmd+B)
# 2. Deploy to stable location
cd ~/dev/ClipQueue
./rebuild_stable.sh
```

## Test Procedure

### 1. Create Test Queue

Copy these items one by one (Cmd+C):
1. "First item"
2. "Second item"  
3. "Third item"
4. "Fourth item"

Expected queue (top to bottom):
- First item (• Next)
- Second item
- Third item
- Fourth item

### 2. Test Cursor Feedback

- Hover over any item
- **Expected**: Cursor changes to open hand 👋
- Move away
- **Expected**: Cursor returns to normal

### 3. Test Drag Operation

- Click and hold on "Third item"
- **Expected in console**: `🎯 Started dragging: Third item`
- Drag it up over "First item"
- **Expected in console**: `🔄 Moved item from index 2 to 0`
- Release

**Expected new order**:
- Third item (• Next) ← Now at top!
- First item
- Second item
- Fourth item

### 4. Test Visual Feedback

While dragging:
- **Expected**: Item being dragged over shows:
  - Thicker blue border (2px instead of 1px)
  - Light blue background
  - More prominent appearance

### 5. Test Paste Order

After reordering, press ⌃W repeatedly:
- **Expected**: Pastes in the NEW order (Third, First, Second, Fourth)
- Check console for paste confirmations

### 6. Test Persistence

1. Close ClipQueue (Cmd+Q)
2. Reopen from ~/Applications/ClipQueue.app
3. **Expected**: Queue maintains the reordered state

### 7. Test Edge Cases

**Drag to same position**:
- Drag item to its own position
- **Expected**: No change, no console message

**Drag last to first**:
- Drag bottom item to top
- **Expected**: Moves correctly, "Next" indicator updates

**Drag first to last**:
- Drag top item to bottom
- **Expected**: Moves correctly, new item becomes "Next"

## Console Messages to Watch For

✅ **Good**:
```
🎯 Started dragging: [item preview]
🔄 Moved item from index X to Y
```

❌ **Bad** (shouldn't see these):
```
⚠️ Failed to move item
Error: ...
```

## Known Limitations

- Can only drag one item at a time
- No multi-select support
- Drag must complete within the window (can't drag outside)

## Troubleshooting

### Drag doesn't work
- Check if items have dashed borders (indicates drag capability)
- Try clicking and holding for a moment before dragging
- Check console for error messages

### No cursor change
- This is visual only, drag should still work
- May be a SwiftUI/AppKit interaction issue

### Items snap back
- Drop might not be registering
- Check console for "🔄 Moved" messages
- Try dragging more slowly

### Order doesn't persist
- Check if QueueManager.moveItem() is being called
- Verify UserDefaults is saving (check console)

## Success Criteria

✅ All these should work:
- [ ] Cursor changes to open hand on hover
- [ ] Can drag items up in queue
- [ ] Can drag items down in queue
- [ ] Visual feedback during drag (blue highlight)
- [ ] Console shows drag/move messages
- [ ] "Next" indicator updates after reorder
- [ ] Paste order (⌃W) follows new arrangement
- [ ] Order persists after app restart
