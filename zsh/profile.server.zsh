# zsh/profile.server.zsh — headless Linux server extras.
# (Loaded only when ~/.config/dotfiles/profile == "server".)
# The modern-CLI aliases come from the shared aliases.zsh — identical to the Mac.
# This file adds server-admin quality-of-life on top.

# Debian renames: expose bat/fd under real names if only the *cat/*find exist
# (setup.sh also symlinks them into ~/.local/bin).
command -v bat >/dev/null 2>&1 || { command -v batcat >/dev/null 2>&1 && alias bat='batcat'; }
command -v fd  >/dev/null 2>&1 || { command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'; }

# ── system / services ────────────────────────────────────────────────────────
alias ports='sudo ss -tulpn'              # listening sockets
alias myip='curl -fsS ifconfig.me; echo'
alias j='journalctl -xe'
alias ju='journalctl -u'
alias sc='systemctl'
alias scs='systemctl status'
alias reload-sysd='sudo systemctl daemon-reload'

# ── docker ───────────────────────────────────────────────────────────────────
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}"'
alias dl='docker logs -f --tail=100'
alias dex='docker exec -it'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=100'

# ── Proxmox (only if present) ────────────────────────────────────────────────
command -v qm  >/dev/null 2>&1 && alias vms='qm list'
command -v pct >/dev/null 2>&1 && alias cts='pct list'

# ── fastfetch on login shells only (not every tmux pane) ─────────────────────
if command -v fastfetch >/dev/null 2>&1 && [[ -o login ]]; then
  fastfetch
fi
