# zsh/profile.work.zsh — work-machine-specific shell config.
# (Loaded only when ~/.config/dotfiles/profile == "work".)
# This is a template — the work-machine Claude session will tailor it.

# ── AWS via Granted (assume) ────────────────────────────────────────────────
# `assume` needs to be sourced as a shell function to export creds; granted
# installs an `assume` alias automatically on first run. Common helpers:
if command -v granted >/dev/null 2>&1; then
  alias a='assume'
fi

# Default AWS region/profile (override per project with direnv .envrc)
# export AWS_REGION='us-east-1'
# export AWS_PROFILE='default'

# ── OpenTofu / Terragrunt ───────────────────────────────────────────────────
command -v tofu >/dev/null 2>&1 && alias tf='tofu'
command -v terragrunt >/dev/null 2>&1 && alias tg='terragrunt'
