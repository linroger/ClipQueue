#!/bin/bash
# ClipQueue - Rebuild and deploy to stable location
# This avoids Accessibility permission issues with Xcode rebuilds

set -e

echo "🔨 Rebuilding ClipQueue to stable location..."
cd ~/dev/ClipQueue

# Kill existing instance
killall ClipQueue 2>/dev/null || true
sleep 1

# Find the latest build
BUILD_PATH=$(find ~/Library/Developer/Xcode/DerivedData/ClipQueue-*/Build/Products/Debug/ClipQueue.app -maxdepth 0 2>/dev/null | head -1)

if [ -z "$BUILD_PATH" ]; then
    echo "❌ No build found. Please build in Xcode first (Cmd+B or Cmd+R)"
    exit 1
fi

echo "📦 Found build at: $BUILD_PATH"

# Copy to stable location
echo "📋 Copying to ~/Applications/ClipQueue.app..."
rm -rf ~/Applications/ClipQueue.app
cp -R "$BUILD_PATH" ~/Applications/

echo "🚀 Launching from stable location..."
open ~/Applications/ClipQueue.app

echo ""
echo "✅ ClipQueue launched from ~/Applications/ClipQueue.app"
echo ""
echo "💡 TIP: If shortcuts don't work, update Accessibility permissions:"
echo "   System Settings → Privacy & Security → Accessibility"
echo "   Remove old ClipQueue entries, then add the one from:"
echo "   📁 /Users/$USER/Applications/ClipQueue.app"
echo "   (NOT from DerivedData or other locations!)"
