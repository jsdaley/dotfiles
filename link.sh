#!/usr/bin/env bash
# link.sh — symlink dotfiles into place from links.conf (the single manifest).
# OS-aware (the 3rd column: all|macos|linux). Idempotent; backs up real files to
# backups/. Used by bootstrap.sh (macOS) and server/setup.sh (Linux), or run
# directly:  bash link.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
case "$(uname -s)" in Darwin) OS=macos;; Linux) OS=linux;; *) OS=other;; esac
TS="$(date +%Y%m%d-%H%M%S)"
trim(){ local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

linked=0 skipped=0
while IFS='|' read -r src dst when; do
  src="$(trim "${src:-}")"; [ -z "$src" ] && continue
  case "$src" in \#*) continue;; esac
  dst="$(trim "${dst:-}")"; when="$(trim "${when:-}")"; when="${when:-all}"
  if [ "$when" != all ] && [ "$when" != "$OS" ]; then skipped=$((skipped+1)); continue; fi
  dst="${dst/#\~/$HOME}"
  local_src="$REPO/$src"
  [ -e "$local_src" ] || { echo "  ! missing source, skipping: $src"; continue; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then rm "$dst"
  elif [ -e "$dst" ]; then mkdir -p "$REPO/backups"; mv "$dst" "$REPO/backups/$(basename "$dst").$TS.bak"; echo "  backed up $dst -> backups/"; fi
  ln -s "$local_src" "$dst"
  echo "  $dst -> $src"
  linked=$((linked+1))
done < "$REPO/links.conf"
echo "==> linked $linked, skipped $skipped (OS=$OS)"
