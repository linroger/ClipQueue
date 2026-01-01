# GitHub Setup Guide

## Quick Setup (Recommended)

Run this single command to set everything up:

```bash
cd ~/dev/ClipQueue
./setup_git_config.sh  # Configure your name/email
./setup_github.sh      # Create repo and push
```

This will:
1. Configure your git identity (if not already set)
2. Authenticate with GitHub (if not already logged in)
3. Create a public repository named "ClipQueue"
4. Push your code to GitHub
5. Open the repository in your browser

## Manual Setup (Alternative)

If you prefer to do it manually:

### 1. Configure Git Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Fix the author on the initial commit
cd ~/dev/ClipQueue
git commit --amend --reset-author --no-edit
```

### 2. Authenticate with GitHub

```bash
gh auth login
# Follow the prompts:
# - Choose: GitHub.com
# - Protocol: HTTPS or SSH (HTTPS is easier)
# - Authenticate: Browser or Token
```

### 3. Create Repository

Option A - Using GitHub CLI:
```bash
cd ~/dev/ClipQueue
gh repo create ClipQueue \
    --public \
    --description "A macOS menu bar app that queues clipboard items and lets you paste them sequentially using keyboard shortcuts" \
    --source=. \
    --remote=origin \
    --push
```

Option B - Using GitHub Web + Manual Push:
```bash
# 1. Go to https://github.com/new
# 2. Create repository named "ClipQueue"
# 3. Don't initialize with README (we already have one)
# 4. Then run:

cd ~/dev/ClipQueue
git remote add origin https://github.com/YOUR_USERNAME/ClipQueue.git
git branch -M main
git push -u origin main
```

## What's Already Set Up

✅ Git repository initialized
✅ Initial commit created with all files
✅ `.gitignore` configured for Xcode projects
✅ MIT License added
✅ README.md with comprehensive documentation
✅ DEVELOPMENT.md with development guide

## Current Commit

```
commit 5a357ee
Initial commit - ClipQueue v0.1.0

Features:
- Clipboard monitoring and FIFO queue management
- Menu bar app with floating window UI
- Global keyboard shortcuts (⌃Q, ⌃⌥⌘C, ⌃W, ⌃E, ⌃X)
- Automatic paste simulation via Accessibility API
- Window position/size persistence
- Basic preferences window (General and Shortcuts tabs)
- Development scripts for stable builds
```

## After Pushing

Once your code is on GitHub, you should:

1. **Add Topics/Tags** (on GitHub web interface):
   - swift
   - macos
   - clipboard
   - menubar-app
   - productivity
   - keyboard-shortcuts

2. **Add a Description** (if not already set):
   > A macOS menu bar app that queues clipboard items and lets you paste them sequentially using keyboard shortcuts

3. **Consider Adding**:
   - Screenshots to README
   - GitHub Actions for CI/CD
   - Issue templates
   - Contributing guidelines

## Future Git Workflow

After initial setup, your workflow will be:

```bash
# Make changes
# ...

# Stage and commit
git add -A
git commit -m "Add drag and drop reordering"

# Push to GitHub
git push

# Or use the rebuild script which handles the app deployment
./rebuild_stable.sh
```

## Troubleshooting

### "gh: command not found"
```bash
brew install gh
```

### "Permission denied (publickey)"
Re-run authentication:
```bash
gh auth login
# Choose HTTPS instead of SSH
```

### "Repository already exists"
If you already created it on GitHub:
```bash
git remote add origin https://github.com/YOUR_USERNAME/ClipQueue.git
git push -u origin main
```

### "Author identity unknown"
```bash
./setup_git_config.sh
# Then amend the commit:
git commit --amend --reset-author --no-edit
```

## Viewing Your Repository

```bash
# Open in browser
gh repo view --web

# Or manually:
# https://github.com/YOUR_USERNAME/ClipQueue
```
