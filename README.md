# Jared's dotfiles

Personal macOS (Apple Silicon) dotfiles — a modern zsh + Powerlevel10k setup with
a curated, mostly-Rust CLI toolchain and a **two-profile** package system
(home / work) over a shared core.

> Lineage: forked long ago from a Holman-style setup (the `*.symlink` convention).
> Modernized in 2026 — see [`docs/GUIDE.md`](docs/GUIDE.md) for the full tour and
> the rationale behind every tool.

## Quick start (new machine)

```bash
git clone https://github.com/jsdaley/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./bootstrap.sh            # asks home or work; idempotent, safe to re-run
exec zsh                  # or open a new terminal
```

`bootstrap.sh` installs Xcode CLT + Homebrew, runs `brew bundle` for the core +
chosen profile, sets up oh-my-zsh / Powerlevel10k / plugins, symlinks the
dotfiles, provisions runtimes via `mise`, and installs global npm CLIs. Anything
needing admin (Homebrew install, some casks, changing your login shell) pauses
and tells you exactly what to run.

## Profiles

Each machine is `home` or `work`, stored in `~/.config/dotfiles/profile`:

| Profile | Adds on top of core |
|---------|---------------------|
| `home`  | virtualization, retro emulation, media, games, disk tools |
| `work`  | AWS, OpenTofu/Terragrunt/Ansible, registry tooling, VPN |

Switch a machine's profile:

```bash
echo work > ~/.config/dotfiles/profile && brew/install.sh work && exec zsh
```

## Layout

```
bootstrap.sh              one-command setup
brew/
  Brewfile.core           shared packages (all machines)
  Brewfile.home           home-only
  Brewfile.work           work-only
  install.sh              brew bundle wrapper (core + active profile)
zsh/
  zshrc.symlink           orchestrator (→ ~/.zshrc)
  zprofile.symlink        login-shell init: brew shellenv + OrbStack (→ ~/.zprofile)
  path.zsh                PATH / Homebrew shellenv
  aliases.zsh             modern-CLI aliases (ls→eza, cat→bat, …)
  tools.zsh               fzf / zoxide / atuin / direnv / mise init
  functions.zsh           shell functions (llm-start, extract, mkcd…)
  profile.zsh             loads profile.{home,work}.zsh
  p10k.zsh.symlink        Powerlevel10k prompt config (→ ~/.p10k.zsh)
git/gitconfig.symlink     delta pager, aliases, sane defaults
config/                   XDG configs → ~/.config (atuin, mise, micro, …)
bin/                      helper scripts (added to PATH)
osx/set-defaults.sh       optional macOS defaults
docs/
  GUIDE.md                full feature/rationale/usage reference
  STATE-CHANGES.md        reversible log of changes made
  work-machine-audit.md   handoff prompt for the work machine's Claude session
backups/                  timestamped backups of replaced files (gitignored)
```

## Maintenance

```bash
brew/install.sh                 # re-sync packages for this profile
mise install                    # install/refresh pinned runtimes
brew bundle cleanup --file brew/Brewfile.core   # list anything not in the manifest
git -C ~/workspace/dotfiles pull                # update, then re-run bootstrap if needed
```

## Local / machine-specific (never committed)

Anything sensitive or machine-specific stays out of the repo and is created in
place by `bootstrap.sh`:

- **`~/.localrc`** — shell secrets / per-machine env (sourced last by `.zshrc`).
- **`~/.gitconfig.local`** — git identity (name, email, signing key). The
  committed `gitconfig` ends with `[include] path = ~/.gitconfig.local`, so each
  machine/profile can use its own email (e.g. a work address on the work box).
