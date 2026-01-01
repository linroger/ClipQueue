#!/bin/bash
# Setup GitHub repository for ClipQueue

set -e

echo "🚀 Setting up GitHub repository for ClipQueue"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "🔐 You need to authenticate with GitHub first"
    echo "Running: gh auth login"
    echo ""
    gh auth login
fi

echo ""
echo "📝 Creating GitHub repository..."
echo ""
echo "Repository name: ClipQueue"
echo "Description: A macOS menu bar app that queues clipboard items and lets you paste them sequentially"
echo "Visibility: Public (for open source)"
echo ""

# Create the repository
gh repo create ClipQueue \
    --public \
    --description "A macOS menu bar app that queues clipboard items and lets you paste them sequentially using keyboard shortcuts" \
    --source=. \
    --remote=origin \
    --push

echo ""
echo "✅ Repository created and pushed!"
echo ""
echo "🌐 View your repository:"
gh repo view --web

echo ""
echo "📋 Next steps:"
echo "  - Add topics/tags on GitHub: swift, macos, clipboard, menubar-app"
echo "  - Consider adding a LICENSE file"
echo "  - Add screenshots to README"
