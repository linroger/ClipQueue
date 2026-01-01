#!/bin/bash
# Configure git user information

echo "🔧 Git Configuration Setup"
echo ""

# Check current config
CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$CURRENT_NAME" ] && [ -n "$CURRENT_EMAIL" ]; then
    echo "✅ Git is already configured:"
    echo "   Name:  $CURRENT_NAME"
    echo "   Email: $CURRENT_EMAIL"
    echo ""
    read -p "Do you want to change these? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Please enter your information:"
echo ""

read -p "Your name (e.g., John Doe): " name
read -p "Your email (e.g., john@example.com): " email

if [ -z "$name" ] || [ -z "$email" ]; then
    echo "❌ Name and email are required"
    exit 1
fi

git config --global user.name "$name"
git config --global user.email "$email"

echo ""
echo "✅ Git configured successfully!"
echo "   Name:  $name"
echo "   Email: $email"
echo ""
echo "💡 You may want to amend your last commit with the correct author:"
echo "   cd /Users/dfaeh/dev/ClipQueue"
echo "   git commit --amend --reset-author --no-edit"
