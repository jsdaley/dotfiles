# zsh/tools.zsh — initialize interactive tools (all guarded by command -v)
# Order matters: fzf first, then atuin (so atuin owns Ctrl-R).

# ── tool config locations ────────────────────────────────────────────────────
[[ -f ~/.config/ripgrep/config ]] && export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# ── fzf: fuzzy finder (Ctrl-T files, Alt-C cd, ** completion) ────────────────
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48 provides `--zsh`; older distro builds (e.g. Ubuntu 24.04's 0.44)
  # ship integration files instead.
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for _f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh \
              /usr/share/fzf/key-bindings.zsh /usr/share/fzf/completion.zsh \
              "$(brew --prefix 2>/dev/null)/opt/fzf/shell/key-bindings.zsh"; do
      [[ -r $_f ]] && source "$_f"
    done
    unset _f
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  # Use fd for fzf's file/dir walks if available
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  # Preview with bat / eza
  command -v bat >/dev/null 2>&1 && export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {} 2>/dev/null || cat {}'"
  command -v eza >/dev/null 2>&1 && export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"
fi

# ── atuin: searchable shell history on Ctrl-R (keep up-arrow native) ─────────
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# ── direnv: per-directory env / auto runtime activation ─────────────────────
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ── mise: polyglot runtime manager (replaces nodenv) ────────────────────────
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# ── zsh-autosuggestions colour (carried over) ───────────────────────────────
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=63'

# ── broot launcher (`br`) ───────────────────────────────────────────────────
[[ -f ~/.config/broot/launcher/bash/br ]] && source ~/.config/broot/launcher/bash/br

# ── iTerm2 shell integration ────────────────────────────────────────────────
[[ -e ~/.iterm2_shell_integration.zsh ]] && source ~/.iterm2_shell_integration.zsh

# ── zoxide LAST — smarter cd (`z foo` jumps, `cdi` picks; `builtin cd` is plain).
#    Initialized after mise/direnv/atuin so its chpwd hook is last. _ZO_DOCTOR=0
#    silences zoxide's "not last" heuristic, which false-positives because p10k
#    re-juggles hooks at first prompt — zoxide still tracks correctly. ──────────
if command -v zoxide >/dev/null 2>&1; then
  export _ZO_DOCTOR=0
  eval "$(zoxide init zsh --cmd cd)"
fi
