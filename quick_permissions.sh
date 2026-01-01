#!/bin/bash
# Quick helper to open Accessibility settings

echo "🔐 Opening Accessibility Settings..."
echo ""
echo "Quick steps:"
echo "1. Remove old ClipQueue entries (click each, then -)"
echo "2. Click + button"
echo "3. Press Cmd+Shift+G"
echo "4. Paste: /Users/$USER/Applications"
echo "5. Select ClipQueue.app"
echo "6. Toggle ON"
echo ""
echo "Opening System Settings in 3 seconds..."
sleep 3

# Open directly to Accessibility settings
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "✅ System Settings opened to Accessibility"
echo ""
echo "After granting permissions, the app should work!"
