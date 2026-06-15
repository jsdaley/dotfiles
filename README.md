# Jared's dotfiles

Cross-platform personal dotfiles — **macOS** (Apple Silicon) and **headless
Linux servers** (Debian/Ubuntu) — sharing one modern zsh + Powerlevel10k setup,
a curated mostly-Rust CLI toolchain, and a **profile** system (`home` / `work` /
`server`, extensible) over a shared core.

> Lineage: forked long ago from a Holman-style setup. Modernized in 2026 — see
> [`docs/GUIDE.md`](docs/GUIDE.md) for the full tour and the rationale behind
> every tool, and [`docs/SECURITY.md`](docs/SECURITY.md) for the security posture.

## Quick start

**macOS:**
```bash
git clone https://github.com/jsdaley/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./bootstrap.sh            # asks the profile; idempotent, safe to re-run
exec zsh                  # or open a new terminal
```
`bootstrap.sh` installs Xcode CLT + Homebrew, runs `brew bundle` for the core +
chosen profile, sets up oh-my-zsh / Powerlevel10k / plugins, symlinks the dotfiles
(`link.sh`), provisions runtimes via `mise`, and installs the Claude Code CLI via
its native installer. Privileged steps pause and tell you exactly what to run.

**Linux server:** copy the repo to the box and run `server/setup.sh` (or
`just servers` from the Mac) — see [`server/`](server/).

## Profiles

Each machine has a profile, stored in `~/.config/dotfiles/profile`. Profiles are
first-class peers and the set is extensible — add a new one by creating a
`Brewfile.<name>` (or apt set) and a `zsh/profile.<name>.zsh`.

| Profile | OS | Adds on top of core |
|---------|----|---------------------|
| `home`  | macOS | virtualization, retro emulation, media, games, disk tools |
| `work`  | macOS | AWS, Terraform, build/data tooling, gRPC + DB GUIs, AWS VPN |
| `server`| Linux | headless: same zsh/p10k config + admin tooling (see `server/`) |

Switch a macOS machine's profile:

```bash
echo work > ~/.config/dotfiles/profile && brew/install.sh work && exec zsh
```

## Layout

```
bootstrap.sh              one-command macOS setup
link.sh                   symlinks everything per links.conf (OS-aware, idempotent)
links.conf                THE symlink manifest:  source | target | when(all/macos/linux)
brew/
  Brewfile.{core,home,work}  shared + per-profile packages
  install.sh              brew bundle wrapper (core + active profile)
zsh/
  zshrc                   orchestrator (→ ~/.zshrc)
  zshenv                  global env for ALL zsh contexts (→ ~/.zshenv)
  zprofile                login init: brew + OrbStack (→ ~/.zprofile, macOS)
  path.zsh / aliases.zsh / tools.zsh / functions.zsh / nudges.zsh
  profile.zsh             loads profile.<active>.zsh
  profile.{home,work,server}.zsh   per-profile shell extras
  p10k.zsh                Powerlevel10k prompt (→ ~/.p10k.zsh)
git/gitconfig, git/gitexcludes   git config (delta, aliases) + global ignore
ssh/config                shared SSH options (+ Include ~/.ssh/config.local)
config/                   XDG configs → ~/.config (atuin, mise, micro, ripgrep, bat, yazi; ghostty is macOS-only)
claude/ , vscode/         macOS GUI app settings
server/                   headless-Linux provisioning (recon.sh, packages.apt, setup.sh)
bin/                      helper scripts + custom git subcommands (on PATH)
macos/set-defaults.sh     opinionated macOS defaults (run via bootstrap prompt)
docs/                     GUIDE.md, SECURITY.md, STATE-CHANGES.md, machine-audit.md, machine-cleanup.md
backups/                  timestamped backups of replaced files (gitignored)
```

**Symlinks:** all managed by [`links.conf`](links.conf) — one line per file
(`source | target | when`). `link.sh` applies it (OS-aware via the `when`
column), backing up any real file it replaces. No more `*.symlink` suffix.

## Updating (idempotent — only what changed)

Configs are symlinks into the repo, so updates are cheap and re-runnable:

```bash
# macOS
git -C ~/workspace/dotfiles pull   # symlinked configs update instantly
./link.sh                          # pick up any new/changed symlinks
brew/install.sh                    # install only newly-added packages
mise install                       # refresh pinned runtimes

# Linux servers (same idea)
cd ~/dotfiles && git pull          # or: rsync from the Mac (transfers only deltas)
bash server/setup.sh               # installs only missing packages; re-links
```

Everything above is safe to re-run anytime; nothing redoes work already done.

## Local / machine-specific (never committed)

Anything sensitive or machine-specific stays out of the repo and is created in
place by `bootstrap.sh`:

- **`~/.localrc`** — shell secrets / per-machine env (sourced last by `.zshrc`).
- **`~/.gitconfig.local`** — git identity (name, email, signing key). The
  committed `gitconfig` ends with `[include] path = ~/.gitconfig.local`, so each
  machine/profile can use its own email (e.g. a work address on the work box).
- **`~/.ssh/config.local`** — per-machine SSH hosts (e.g. LAN host aliases). The
  committed `ssh/config` ends with `Include ~/.ssh/config.local`.
