#!/usr/bin/env bash
# server/setup.sh — provision a headless Linux server with the shared toolset + QoL.
# Idempotent; safe to re-run. Uses sudo (will prompt if passwordless sudo is off).
#
# Usage (copy the server/ folder to the box, then):
#   bash setup.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

step(){ printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# --- 1. install shared packages (skip any not available on this distro) ---
step "Updating apt and selecting available packages"
sudo apt-get update -qq
mapfile -t WANT < <(grep -vE '^\s*#|^\s*$' "$HERE/packages.apt")
AVAIL=()
for p in "${WANT[@]}"; do
  if apt-cache show "$p" >/dev/null 2>&1; then AVAIL+=("$p"); else echo "  not in apt here, skipping: $p"; fi
done
step "Installing ${#AVAIL[@]} packages"
sudo apt-get install -y "${AVAIL[@]}"

# --- 2. Debian binary-name shims (bat/fd) ---
step "Linking bat/fd shims into ~/.local/bin"
mkdir -p "$HOME/.local/bin"
command -v batcat >/dev/null 2>&1 && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
command -v fdfind >/dev/null 2>&1 && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

# --- 3. install QoL shell config + wire into rc files ---
step "Installing QoL shell config"
mkdir -p "$HOME/.config"
cp "$HERE/shell.sh" "$HOME/.config/server-shell.sh"
LINE='[ -f ~/.config/server-shell.sh ] && . ~/.config/server-shell.sh'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  if ! grep -qF 'server-shell.sh' "$rc"; then
    printf '\n# dotfiles server profile\n%s\n' "$LINE" >> "$rc"
    echo "  wired into $rc"
  else
    echo "  already wired in $rc"
  fi
done

step "Done. Start a new shell, or run:  source ~/.config/server-shell.sh"
