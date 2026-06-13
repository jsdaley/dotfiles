# server/shell.sh — portable QoL for headless Linux servers.
# Sourced from ~/.bashrc and ~/.zshrc by server/setup.sh. Works in bash AND zsh.
#
# Aliasing is intentionally MORE conservative than the macOS profile: servers are
# paste-heavy admin contexts, so only ls/cat/top/df are swapped. grep/find/ps stay
# native — use rg/fd/procs by name. (Originals always reachable via \cmd.)

# ~/.local/bin first (holds the bat/fd shims setup.sh creates)
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac

# Expose bat/fd under their real names if only the Debian-renamed binaries exist
command -v bat >/dev/null 2>&1 || { command -v batcat >/dev/null 2>&1 && alias bat='batcat'; }
command -v fd  >/dev/null 2>&1 || { command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'; }

# --- modern replacements (safe subset; originals via \cmd) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh  --group-directories-first --git'
  alias la='eza -lah --group-directories-first --git'
  alias lt='eza --tree --level=2'
fi
command -v batcat >/dev/null 2>&1 && alias cat='batcat --paging=never'
command -v bat    >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v btop   >/dev/null 2>&1 && alias top='btop'
command -v duf    >/dev/null 2>&1 && alias df='duf'

# --- smart cd (zoxide) ---
if command -v zoxide >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then eval "$(zoxide init zsh)"
  elif [ -n "$BASH_VERSION" ]; then eval "$(zoxide init bash)"; fi
fi

# --- fzf keybindings (Ctrl-R / Ctrl-T) ---
if [ -n "$BASH_VERSION" ]; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
elif [ -n "$ZSH_VERSION" ]; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && . /usr/share/doc/fzf/examples/key-bindings.zsh
fi

# --- server admin QoL ---
alias ports='sudo ss -tulpn'        # listening sockets
alias myip='curl -fsS ifconfig.me; echo'
alias dush='du -sh -- * 2>/dev/null | sort -h'
alias j='journalctl -xe'
alias ju='journalctl -u'
alias sc='systemctl'
alias scstat='systemctl status'
# docker
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}"'
alias dl='docker logs -f --tail=100'
alias dex='docker exec -it'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=100'

# --- bash history QoL (zsh handled by oh-my-zsh/p10k if present) ---
if [ -n "$BASH_VERSION" ]; then
  HISTSIZE=100000; HISTFILESIZE=200000; HISTCONTROL=ignoreboth:erasedups
  shopt -s histappend checkwinsize 2>/dev/null
fi

# --- fastfetch on LOGIN shells only (not every pane) ---
if command -v fastfetch >/dev/null 2>&1; then
  if { [ -n "$BASH_VERSION" ] && shopt -q login_shell 2>/dev/null; } \
  || { [ -n "$ZSH_VERSION" ] && [[ -o login ]]; }; then
    fastfetch
  fi
fi
