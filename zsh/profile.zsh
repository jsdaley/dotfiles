# zsh/profile.zsh — load the machine profile (home | work) and its extras.
# Profile is set in ~/.config/dotfiles/profile (defaults to "home").

DOTFILES_PROFILE="$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile" 2>/dev/null || echo home)"
export DOTFILES_PROFILE

case "$DOTFILES_PROFILE" in
  work) [[ -f "$DOTFILES/zsh/profile.work.zsh" ]] && source "$DOTFILES/zsh/profile.work.zsh" ;;
  *)    [[ -f "$DOTFILES/zsh/profile.home.zsh" ]] && source "$DOTFILES/zsh/profile.home.zsh" ;;
esac
