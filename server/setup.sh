#!/usr/bin/env bash
# server/setup.sh — provision a headless Linux server to match the Mac zsh setup.
# Installs the shared toolset + zsh + oh-my-zsh + Powerlevel10k + plugins, then
# symlinks the SAME dotfiles the Mac uses (zshrc, p10k, gitconfig, ssh config).
# Idempotent; safe to re-run. Uses sudo (prompts if passwordless sudo is off).
#
# Run from inside the repo on the server (rsync/clone it to ~/dotfiles first):
#   bash ~/dotfiles/server/setup.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
step(){ printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# --- 1. apt packages (skip any not available on this distro) + zsh ----------
step "Installing packages (apt)"
sudo apt-get update -qq
mapfile -t WANT < <(grep -vE '^\s*#|^\s*$' "$HERE/packages.apt"); WANT+=(zsh)
AVAIL=(); for p in "${WANT[@]}"; do apt-cache show "$p" >/dev/null 2>&1 && AVAIL+=("$p") || echo "  skip (not in apt): $p"; done
sudo apt-get install -y "${AVAIL[@]}"

# --- 2. Debian bat/fd shims --------------------------------------------------
step "bat/fd shims"
mkdir -p "$HOME/.local/bin"
command -v batcat >/dev/null 2>&1 && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
command -v fdfind >/dev/null 2>&1 && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

# --- 2b. snap fallbacks for tools missing from apt ---------------------------
# Some tools (e.g. procs) ship in Debian's apt but not Ubuntu's enabled repos.
# Where apt didn't provide them and snapd is available, fall back to snap.
step "Snap fallbacks (tools missing from apt)"
if command -v snap >/dev/null 2>&1; then
  if ! command -v procs >/dev/null 2>&1; then
    sudo snap install procs && echo "  installed procs via snap" || echo "  snap install procs failed"
  fi
else
  command -v procs >/dev/null 2>&1 || echo "  procs missing (not in apt, snap unavailable) — skipped"
fi

# --- 3. oh-my-zsh + Powerlevel10k + plugins ----------------------------------
step "oh-my-zsh + Powerlevel10k + plugins"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
[[ -d "$ZSH" ]] || RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ZC="${ZSH_CUSTOM:-$ZSH/custom}"
clone(){ [[ -d "$2" ]] || git clone --depth=1 "$1" "$2"; }
clone https://github.com/romkatv/powerlevel10k.git           "$ZC/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions       "$ZC/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting   "$ZC/plugins/zsh-syntax-highlighting"
clone https://github.com/Aloxaf/fzf-tab                      "$ZC/plugins/fzf-tab"
clone https://github.com/MichaelAquilina/zsh-you-should-use  "$ZC/plugins/you-should-use"

# --- 4. profile marker + local (uncommitted) files ---------------------------
step "Profile + local files"
mkdir -p "$HOME/.config/dotfiles"; echo server > "$HOME/.config/dotfiles/profile"
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  printf '[user]\n\tname = Jared Daley\n\temail = jsdaley@users.noreply.github.com\n' > "$HOME/.gitconfig.local"
fi
[[ -f "$HOME/.ssh/config.local" ]] || { mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"; : > "$HOME/.ssh/config.local"; chmod 600 "$HOME/.ssh/config.local"; }
# fastfetch: seed the shared base dashboard ONLY if this box has none yet, so
# machine-specific dashboards (Proxmox/Plex/RAID/GPU panels) are never clobbered.
if [[ ! -f "$HOME/.config/fastfetch/config.jsonc" ]]; then
  mkdir -p "$HOME/.config/fastfetch"
  cp "$REPO/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  echo "  seeded ~/.config/fastfetch/config.jsonc (base — customize freely)"
fi

# --- 5. symlink the SAME dotfiles the Mac uses (via the shared manifest) ------
step "Linking shared dotfiles (links.conf)"
bash "$REPO/link.sh"
chmod 600 "$HOME/.ssh/config" 2>/dev/null || true

# --- 6. make zsh the login shell ---------------------------------------------
step "Login shell"
ZSH_BIN="$(command -v zsh)"
if [[ "${SHELL:-}" != "$ZSH_BIN" ]]; then
  sudo chsh -s "$ZSH_BIN" "$USER" && echo "  default shell -> $ZSH_BIN (re-login to take effect)" || \
    echo "  could not chsh; run: chsh -s $ZSH_BIN"
fi

step "Done. Re-login (or run: exec zsh). Set your terminal font to a Nerd Font for p10k icons."
