#!/bin/bash
# ClipQueue - Clean up old Xcode builds from DerivedData
# This prevents confusion when adding to Accessibility settings

echo "🧹 Cleaning up old ClipQueue builds..."

# Kill running instances
killall ClipQueue 2>/dev/null || true
sleep 1

# Find and remove DerivedData for ClipQueue
DERIVED_DATA_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "ClipQueue-*" -type d 2>/dev/null)

if [ -z "$DERIVED_DATA_DIRS" ]; then
    echo "✅ No DerivedData builds found (already clean)"
else
    echo "🗑️  Removing DerivedData builds:"
    echo "$DERIVED_DATA_DIRS" | while read dir; do
        echo "   - $dir"
        rm -rf "$dir"
    done
    echo "✅ Cleaned up DerivedData"
fi

echo ""
echo "📍 Your stable build location:"
if [ -d ~/Applications/ClipQueue.app ]; then
    echo "   ✅ ~/Applications/ClipQueue.app ($(stat -f '%Sm' -t '%Y-%m-%d %H:%M' ~/Applications/ClipQueue.app))"
else
    echo "   ⚠️  No stable build found at ~/Applications/ClipQueue.app"
    echo "   Run ./rebuild_stable.sh after building in Xcode"
fi

echo ""
echo "💡 Next time you build in Xcode, run ./rebuild_stable.sh to update the stable version"
