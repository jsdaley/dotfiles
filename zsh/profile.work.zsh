# zsh/profile.work.zsh — work-machine-specific shell config.
# (Loaded only when ~/.config/dotfiles/profile == "work".)
# This is a template — the work-machine Claude session will tailor it.

# ── Project navigation (Orderful) ───────────────────────────────────────────
alias ord='cd ~/workspace/orderful'                    # repo root
alias be='cd ~/workspace/orderful/orderful-workspace'  # backend
alias fe='cd ~/workspace/orderful/o2-app-ui'           # frontend

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
command -v terraform >/dev/null 2>&1 && alias tf='terraform'   # IaC tool here now (was opentofu)
command -v tofu      >/dev/null 2>&1 && alias tf='tofu'        # fallback if a project uses opentofu
command -v terragrunt >/dev/null 2>&1 && alias tg='terragrunt'
