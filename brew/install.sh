#!/usr/bin/env bash
# brew/install.sh — install the core Brewfile + the active machine profile.
# Usage: brew/install.sh [home|work]   (defaults to ~/.config/dotfiles/profile)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${1:-$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile" 2>/dev/null || echo home)}"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install it first (see bootstrap.sh)." >&2
  exit 1
fi

echo "==> brew bundle: core"
brew bundle --file "$DOTFILES/brew/Brewfile.core"

case "$PROFILE" in
  home|work)
    echo "==> brew bundle: $PROFILE"
    brew bundle --file "$DOTFILES/brew/Brewfile.$PROFILE"
    ;;
  *)
    echo "Unknown profile '$PROFILE' (expected home|work); skipping profile bundle." >&2
    ;;
esac

echo "==> done. Casks already installed by direct download can be taken over with:"
echo "    brew bundle --file <file> --cleanup=false  # then 'brew install --cask --adopt <name>'"
