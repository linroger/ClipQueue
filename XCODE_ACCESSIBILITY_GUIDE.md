# Xcode Development - Accessibility Permissions Guide

## The Problem

When you run from Xcode (Cmd+R), the app runs from a **temporary location** in DerivedData, NOT from ~/Applications. Each build gets a new signature, so macOS treats it as a "different" app and revokes permissions.

## The Solution - Step by Step

### Step 1: Build in Xcode

```bash
# Open Xcode
cd ~/dev/ClipQueue
open ClipQueue.xcodeproj

# Press Cmd+B to build (or Cmd+R to build and run)
```

### Step 2: Find the Xcode Build Location

Run this helper script:

```bash
cd ~/dev/ClipQueue
./grant_accessibility.sh
```

This will show you the EXACT path to copy. It looks like:
```
/Users/dfaeh/Library/Developer/Xcode/DerivedData/ClipQueue-XXXXX/Build/Products/Debug/ClipQueue.app
```

**Copy this entire path!**

### Step 3: Grant Accessibility Permissions

1. **Open System Settings**
   - Click Apple menu → System Settings
   - Or press Cmd+Space, type "System Settings"

2. **Navigate to Accessibility**
   - Click "Privacy & Security" (in left sidebar)
   - Click "Accessibility"

3. **Unlock Settings**
   - Click the 🔒 lock icon at bottom
   - Enter your password

4. **Remove Old Entries**
   - Look for any "ClipQueue" entries
   - Click each one
   - Click the minus (-) button to remove
   - Remove ALL of them (there might be 2-3)

5. **Add the NEW Build**
   - Click the plus (+) button
   - A file picker opens
   - **Press Cmd+Shift+G** (this is the key!)
   - A "Go to folder" dialog appears
   - **Paste the path** from Step 2
   - Click "Go"
   - Click "Open"

6. **Enable It**
   - Find "ClipQueue" in the list
   - Toggle the switch ON (should turn blue)
   - You should see a checkmark ✓

7. **Lock and Close**
   - Click the 🔒 lock icon to lock
   - Close System Settings

### Step 4: Run from Xcode

```bash
# In Xcode, press Cmd+R
# The app should now have accessibility permissions!
```

### Step 5: Verify

Check the Xcode console. You should see:
```
✅ Accessibility permissions granted
```

Instead of:
```
⚠️ Accessibility permissions not granted!
```

## Why This is Annoying

Every time you build in Xcode, you'll need to repeat this process because:
- The app signature changes
- macOS revokes the permission
- You need to re-add the NEW build location

## Alternative: Use Stable Build Location

If this is too annoying, use the stable build workflow instead:

```bash
# 1. Build in Xcode (Cmd+B)
# 2. Deploy to stable location
./rebuild_stable.sh

# 3. Grant permissions ONCE to ~/Applications/ClipQueue.app
# 4. Permissions persist across builds!
```

**Trade-off**: Extra step between code changes and testing, but permissions don't reset.

## Quick Reference

### When Running from Xcode:
- **App Location**: `~/Library/Developer/Xcode/DerivedData/.../Debug/ClipQueue.app`
- **Permissions**: Reset every build
- **Best For**: Active development, quick iteration

### When Running from ~/Applications:
- **App Location**: `~/Applications/ClipQueue.app`
- **Permissions**: Persist across builds
- **Best For**: Final testing, longer sessions

## Troubleshooting

### "I added it but it still says permission denied"

1. Make sure you added the CORRECT path (from DerivedData, not Applications)
2. Make sure the toggle is ON (blue)
3. Try quitting and restarting ClipQueue
4. Check if there are multiple ClipQueue entries (remove all, add only the new one)

### "I can't find the path with Cmd+Shift+G"

The path is hidden by default. You MUST use Cmd+Shift+G in the file picker to navigate to hidden folders like `Library`.

### "It worked once but not after rebuilding"

This is expected! Each build = new signature = need to re-grant permissions. This is why the stable build location exists.

### "Can I disable this security feature?"

No, and you shouldn't. It's a macOS security feature. The workaround is to use code signing with a Developer ID, but that requires a $99/year Apple Developer account.

## My Recommendation

For this drag & drop feature testing:

1. Use the **stable build workflow** (`./rebuild_stable.sh`)
2. Grant permissions ONCE to `~/Applications/ClipQueue.app`
3. Test your changes
4. Rebuild and redeploy when you make code changes
5. Permissions persist!

This is less frustrating than re-granting every time.
