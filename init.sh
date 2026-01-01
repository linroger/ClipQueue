#!/usr/bin/env bash
set -euo pipefail

PROJECT="ClipQueue.xcodeproj"
SCHEME="ClipQueue"

if [[ "${1:-}" == "--build" ]]; then
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "platform=macOS"
  exit 0
fi

echo "Usage: ./init.sh --build"
echo "Opens Xcode for development: open $PROJECT"
