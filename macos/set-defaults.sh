#!/usr/bin/env bash
# macos/set-defaults.sh — opinionated macOS defaults for a developer/power user.
# Idempotent. Run explicitly (bootstrap.sh prompts before running it):
#   bash macos/set-defaults.sh
#
# Some changes need a logout/restart to fully apply. Quit System Settings first
# so it doesn't overwrite values on exit. Everything here is reversible via
# System Settings or `defaults delete`.
set -u
[[ "$(uname)" == "Darwin" ]] || { echo "macOS only."; exit 0; }

echo "Applying macOS defaults… (close System Settings if it's open)"
# Keep sudo alive for the few settings that need it.
sudo -v 2>/dev/null || true

# ── Keyboard & text (big wins for coding) ────────────────────────────────────
defaults write NSGlobalDomain KeyRepeat -int 2             # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15     # short delay before repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # repeat, not accent popover
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3   # full keyboard access (Tab all controls)
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# NOTE: autocorrect + smart quotes/dashes are intentionally NOT touched — your
# machine has them ON, and we don't override deliberate settings.

# (Tap-to-click intentionally left alone — you use physical click.)

# ── Finder ───────────────────────────────────────────────────────────────────
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true          # show dotfiles
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"   # column view (your preference)
chflags nohidden ~/Library 2>/dev/null || true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on shares
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Dock & Mission Control ───────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false      # don't auto-rearrange Spaces
defaults write com.apple.dock expose-animation-duration -float 0.12

# ── Screenshots → ~/Desktop, PNG, no shadow ──────────────────────────────────
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ── General UX ───────────────────────────────────────────────────────────────
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true   # expand save dialog
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true      # expand print dialog
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false   # save to disk, not iCloud
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true        # AirDrop over Ethernet
defaults write com.apple.TextEdit RichText -int 0                             # TextEdit = plain text
# NOTE: LSQuarantine left ON — keep the Gatekeeper "downloaded app" check (security).

echo "Done. Restarting Finder/Dock/SystemUIServer…"
for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
echo "Some changes require a logout/restart to take full effect."
