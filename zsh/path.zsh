# zsh/path.zsh — PATH setup (sourced early, before oh-my-zsh)

# Homebrew (Apple Silicon). Sets PATH, MANPATH, INFOPATH, HOMEBREW_* vars.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Personal + repo bins (repo bin/ holds the git-* helper scripts, etc.)
export PATH="$HOME/bin:${DOTFILES:-$HOME/workspace/dotfiles}/bin:$PATH"

# Homebrew sbin (some formulae install here)
[[ -d /opt/homebrew/sbin ]] && export PATH="/opt/homebrew/sbin:$PATH"

# pnpm global bin
export PNPM_HOME="$HOME/Library/pnpm"
[[ ":$PATH:" == *":$PNPM_HOME:"* ]] || export PATH="$PNPM_HOME:$PATH"

# NOTE: dropped legacy entries from the old .zshrc that no longer apply here:
#   /opt/local/bin (MacPorts — not installed), /usr/X11/bin (XQuartz path),
#   and the manual /usr/local/* ordering (Homebrew shellenv handles ordering).
