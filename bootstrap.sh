#!/usr/bin/env bash
# bootstrap.sh — set up these dotfiles on a fresh (or existing) macOS machine.
# Idempotent: safe to re-run. Steps needing admin/sudo will PAUSE and tell you
# what to run, rather than assuming passwordless sudo.
#
# Usage:
#   ./bootstrap.sh            # prompts for home|work
#   ./bootstrap.sh home
#   ./bootstrap.sh work
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
step() { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m!! %s\033[0m\n" "$*"; }
pause_for() { warn "$1"; read -r -p "Press Enter once that's done... " _; }

# ── 1. Profile ───────────────────────────────────────────────────────────────
PROFILE="${1:-}"
if [[ -z "$PROFILE" ]]; then
  read -r -p "Which profile is this machine? [home/work] " PROFILE
fi
[[ "$PROFILE" == home || "$PROFILE" == work ]] || { echo "profile must be home or work"; exit 1; }
step "Profile: $PROFILE"
mkdir -p "$HOME/.config/dotfiles"
echo "$PROFILE" > "$HOME/.config/dotfiles/profile"

# ── 2. Xcode Command Line Tools (git, compilers) ─────────────────────────────
step "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  warn "Command Line Tools not installed. A GUI installer will open."
  xcode-select --install || true
  pause_for "Finish the Command Line Tools install in the popup."
else
  echo "already installed."
fi

# ── 3. Homebrew ──────────────────────────────────────────────────────────────
step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew install will ask for your sudo password (admin required)."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
echo "brew: $(brew --version | head -1)"

# ── 4. Packages (core + profile). Casks may prompt for your password. ────────
step "Installing packages (brew bundle)"
warn "Some casks need admin rights and will prompt for your password."
"$DOTFILES/brew/install.sh" "$PROFILE"

# ── 5. oh-my-zsh + Powerlevel10k + plugins ──────────────────────────────────
step "oh-my-zsh, Powerlevel10k, plugins"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [[ ! -d "$ZSH" ]]; then
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZCUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
clone_if_absent() { [[ -d "$2" ]] || git clone --depth=1 "$1" "$2"; }
clone_if_absent https://github.com/romkatv/powerlevel10k.git        "$ZCUSTOM/themes/powerlevel10k"
clone_if_absent https://github.com/zsh-users/zsh-autosuggestions     "$ZCUSTOM/plugins/zsh-autosuggestions"
clone_if_absent https://github.com/zsh-users/zsh-syntax-highlighting "$ZCUSTOM/plugins/zsh-syntax-highlighting"

# ── 6. Symlink dotfiles ──────────────────────────────────────────────────────
step "Linking dotfiles"
TS="$(date +%Y%m%d-%H%M%S)"
link() {  # link <source> <target>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then rm "$dst"
  elif [[ -e "$dst" ]]; then warn "backing up $dst -> $dst.$TS.bak"; mv "$dst" "$dst.$TS.bak"; fi
  ln -s "$src" "$dst"
  echo "  $dst -> $src"
}
# topic/*.symlink  ->  ~/.<name>
while IFS= read -r f; do
  base="$(basename "$f")"; name="${base%.symlink}"
  link "$DOTFILES/$f" "$HOME/.$name"
done < <(cd "$DOTFILES" && ls */*.symlink 2>/dev/null)
# config/**  ->  ~/.config/**
if [[ -d "$DOTFILES/config" ]]; then
  while IFS= read -r f; do
    rel="${f#config/}"
    link "$DOTFILES/$f" "$HOME/.config/$rel"
  done < <(cd "$DOTFILES" && find config -type f)
fi

# ── 7. Runtimes via mise ─────────────────────────────────────────────────────
step "mise runtimes"
if command -v mise >/dev/null 2>&1; then
  mise install
  mise ls
fi

# ── 8. Global npm CLIs (mise node) ──────────────────────────────────────────
step "Global npm tools"
if command -v npm >/dev/null 2>&1; then
  npm install -g @anthropic-ai/claude-code || warn "claude-code global install failed (non-fatal)"
fi

# ── 9. Misc tool init ────────────────────────────────────────────────────────
step "Tool data"
command -v tldr  >/dev/null 2>&1 && tldr --update || true
command -v atuin >/dev/null 2>&1 && atuin import auto || true

# ── 10. macOS defaults (optional) ────────────────────────────────────────────
step "macOS defaults"
if [[ -f "$DOTFILES/osx/set-defaults.sh" ]]; then
  read -r -p "Apply macOS defaults from osx/set-defaults.sh? [y/N] " yn
  [[ "$yn" == [yY] ]] && bash "$DOTFILES/osx/set-defaults.sh" || echo "skipped."
fi

# ── 11. Login shell ──────────────────────────────────────────────────────────
step "Login shell"
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [[ "$SHELL" != "$BREW_ZSH" && -x "$BREW_ZSH" ]]; then
  warn "To use Homebrew zsh as your login shell, run (needs your password):"
  echo "    echo '$BREW_ZSH' | sudo tee -a /etc/shells && chsh -s '$BREW_ZSH'"
fi

bold "\nDone. Open a new terminal (or run: exec zsh)."
