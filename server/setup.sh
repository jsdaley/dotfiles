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

# --- 2c. yazi (not reliably in apt; install the official .deb) ---------------
# yazi is newer than Ubuntu 24.04's repos and version-inconsistent across Debian,
# so install the upstream .deb for a consistent, recent build on every server.
# (The shared config/yazi/keymap.toml is already linked via links.conf.)
step "yazi"
if ! command -v yazi >/dev/null 2>&1; then
  case "$(uname -m)" in
    x86_64)  ydeb="yazi-x86_64-unknown-linux-gnu.deb" ;;
    aarch64) ydeb="yazi-aarch64-unknown-linux-gnu.deb" ;;
    *)       ydeb="" ;;
  esac
  if [[ -n "$ydeb" ]]; then
    ytag="$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest 2>/dev/null \
            | grep -oE '"tag_name": *"[^"]+"' | head -1 | grep -oE 'v[0-9][^"]*')"
    if [[ -n "$ytag" ]]; then
      ytmp="$(mktemp -d)"; chmod 755 "$ytmp"   # readable by the _apt sandbox user
      if curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${ytag}/${ydeb}" -o "$ytmp/yazi.deb"; then
        chmod 644 "$ytmp/yazi.deb"
        # --no-install-recommends: skip the .deb's preview deps (imagemagick,
        # ghostscript, poppler, fonts…) — not needed for headless file management.
        sudo apt-get install -y --no-install-recommends "$ytmp/yazi.deb" \
          && echo "  installed yazi ${ytag} (${ydeb})" || echo "  yazi .deb install failed"
      else
        echo "  could not download yazi .deb ($ydeb @ $ytag)"
      fi
      rm -rf "$ytmp"
    else
      echo "  could not resolve latest yazi release — skipped"
    fi
  else
    echo "  no prebuilt yazi .deb for $(uname -m) — skipped"
  fi
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
