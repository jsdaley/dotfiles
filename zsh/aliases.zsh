# zsh/aliases.zsh — modern CLI replacements + handy aliases
#
# "Full send": core tools are aliased to modern equivalents. Aliases only affect
# INTERACTIVE shells (scripts are unaffected). To reach the original tool, prefix
# with a backslash (\ls) or use `command ls`. For shadowed builtins use `builtin`.

# ── ls → eza ────────────────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh  --group-directories-first --icons=auto --git'
  alias la='eza -lah --group-directories-first --icons=auto --git'
  alias l='eza -lah  --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
  alias tree='eza --tree --icons=auto'
fi

# ── cat → bat (pipe-safe: bat auto-plains when output isn't a TTY) ───────────
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias catp='bat'                 # cat with a pager (theme/style: config/bat/config)
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'
fi

# ── find → fd ───────────────────────────────────────────────────────────────
# NOTE: fd's syntax differs from find. Pasted `find ... -name` commands will
# break — use \find for the real one.
command -v fd >/dev/null 2>&1 && alias find='fd'

# ── grep → ripgrep ──────────────────────────────────────────────────────────
# NOTE: rg ignores .gitignore by default and has different flags than grep.
# Use \grep for POSIX grep.
command -v rg >/dev/null 2>&1 && alias grep='rg'

# ── other modern replacements ───────────────────────────────────────────────
command -v dust    >/dev/null 2>&1 && alias du='dust'
command -v duf     >/dev/null 2>&1 && alias df='duf'
command -v procs   >/dev/null 2>&1 && alias ps='procs'
command -v btop    >/dev/null 2>&1 && alias top='btop'
command -v xh      >/dev/null 2>&1 && alias http='xh'
command -v doggo   >/dev/null 2>&1 && alias dig='doggo'
command -v micro   >/dev/null 2>&1 && alias nano='micro'   # standardize on micro (real nano: \nano)

# ── short launchers for TUIs ────────────────────────────────────────────────
command -v lazygit    >/dev/null 2>&1 && alias lg='lazygit'
command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'
command -v yazi       >/dev/null 2>&1 && alias y='yazi'

# ── git difftastic on demand (delta stays the default pager; see gitconfig) ──
command -v difft >/dev/null 2>&1 && alias gdt='git -c diff.external=difft diff'

# ── personal shortcuts (carried over) ───────────────────────────────────────
alias wsp='cd ~/workspace'
alias album='node ~/workspace/album-generator/index.js'
alias reload='exec zsh'
alias zshrc='${EDITOR:-micro} ~/.zshrc'
