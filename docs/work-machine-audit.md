# Work-Machine Audit & Profile Optimization — Claude Code Handoff

**Hand this file to a Claude Code session running on Jared's *work* MacBook.**
It is self-contained: it assumes you have no prior context.

---

## 0. TL;DR of your mission

This dotfiles repo (`~/workspace/dotfiles`, also on GitHub) was just modernized on
the **home** machine. It uses a **three-file Brewfile profile system**:

- `brew/Brewfile.core` — tools shared by every machine
- `brew/Brewfile.home` — home-only (virtualization, retro, media, games)
- `brew/Brewfile.work` — work-only (AWS, IaC, VPN)

The **work machine has drifted heavily** from this setup over time. Your job:

1. **Audit** everything actually installed on this work machine (brew, casks,
   npm/pnpm/bun globals, cargo, pipx, go, /Applications, mise/nodenv).
2. **Reconcile** it against the existing Brewfiles in this repo.
3. **Optimize `Brewfile.work`** so it reflects Jared's *real* work usage — own
   this file, edit it directly.
4. **Propose (do NOT edit) changes to `Brewfile.core` and `Brewfile.home`** —
   emit a recommendations block (see §6) that Jared relays to the home session,
   which reconciles core/home centrally. This prevents two machines from
   conflicting on shared files.
5. **Propose a prune list** of redundant/never-used tools.

> ⚠️ **Do not install, uninstall, or change anything until Jared explicitly
> approves your plan.** Mirror the home workflow: analyze → present plan →
> get approval → act. See §5 for the rules.

---

## 1. Background: what this repo is

- Originally Holman-style dotfiles (Zach Holman → a coworker → Jared), now
  modernized — the old `*.symlink` convention and Ruby `Rakefile` are **gone**.
- **Symlinks are declarative now:** `links.conf` (`source | target | when`) is the
  single source of truth, applied by `link.sh` (OS-aware: all/macos/linux).
- **Profiles are first-class & extensible:** `home`, `work`, `server` (Linux), set
  in `~/.config/dotfiles/profile`. Each = a `Brewfile.<name>` (or `server/`
  apt set) + a `zsh/profile.<name>.zsh`. Installers: `bootstrap.sh` (macOS),
  `server/setup.sh` (Linux). `just` (Justfile) is the cross-machine entry point.
- Modular `zsh/` config (zshrc + path/aliases/tools/functions/nudges/profile.*),
  shared by macOS and Linux (Mac-only bits are guarded).
- **First action: `cd ~/workspace/dotfiles && git fetch && git status`.** Pull the
  latest so you're working against the current Brewfiles + `links.conf`.
  If the repo isn't here, clone it from Jared's GitHub first (ask him for the URL).

---

## 2. Jared's profile & hard preferences (do not violate)

- **Role:** programmer / DevOps / computer expert. **Node is his primary
  language** — expect many CLIs installed via npm/pnpm globally.
- **Editors:** VS Code (GUI) and **nano/micro** for the terminal. **Never
  install or configure vim/neovim as his editor.**
- **Shell:** zsh + oh-my-zsh + **Powerlevel10k**. Apple Silicon (arm64).
- **Container runtime:** OrbStack. **API client:** Bruno (not Postman).
- **Modernization stance:** "full send" on modern CLI replacements (eza, bat,
  fd, ripgrep, zoxide, delta, etc.), but keep originals reachable via backslash
  (`\ls`). Keep fallbacks/familiar tools; only remove what he'll *never* use.
- **Runtimes:** migrating `nodenv` + manual python → **`mise`**.
- **History:** `atuin` (local-only) on Ctrl-R. **Git diffs:** `delta` as pager,
  `git difft` (difftastic) on demand.
- **Privileged steps:** anything needing **sudo / admin / GUI consent /
  interactive input** must be handed to Jared as copy-paste commands — do **not**
  attempt to run them yourself. He pastes results back.

---

## 3. Phase A — Audit (read-only; safe to run now)

Run these and capture the output. They change nothing.

```bash
# --- Homebrew ---
brew leaves                      # top-level formulae (the real signal)
brew list --cask                 # casks
brew tap                         # taps
brew autoremove --dry-run        # orphaned deps (prune candidates)

# --- Node ecosystem (THE important one for this machine) ---
# npm globals are per-node-version; check the active one AND each installed one:
npm ls -g --depth=0
nodenv versions 2>/dev/null || mise ls node 2>/dev/null
# If multiple node versions exist, repeat for each, e.g.:
#   NODENV_VERSION=20.x.x npm ls -g --depth=0
pnpm ls -g --depth=0 2>/dev/null
yarn global list 2>/dev/null
bun pm ls -g 2>/dev/null
corepack --version 2>/dev/null

# --- Other language-level global tools ---
pipx list 2>/dev/null            # python CLIs
uv tool list 2>/dev/null
cargo install --list 2>/dev/null # rust CLIs
ls "$(go env GOPATH 2>/dev/null)/bin" 2>/dev/null   # go-installed bins
gem list --no-versions 2>/dev/null | head -40

# --- GUI apps installed outside brew ---
ls /Applications ~/Applications 2>/dev/null

# --- Shell / current config ---
cat ~/.zshrc 2>/dev/null
echo "PROFILE: $(cat ~/.config/dotfiles/profile 2>/dev/null || echo 'unset')"
```

For **each global npm/pnpm/cargo/pipx/go tool found**, classify it:
- Is it a **system/dev CLI** (belongs in a Brewfile or a managed global list)?
- Is it a **project dependency accidentally installed globally** (leave alone)?
- Is there a **brew formula that supersedes it** (prefer brew for reproducibility)?

> Note: global npm tools are tied to a specific node install. Under the new
> `mise` setup, the canonical list of global npm CLIs should be captured so the
> `bootstrap.sh` can reinstall them. On the home machine the only real one is
> `@anthropic-ai/claude-code`. Identify the work machine's equivalents.

---

## 4. Phase B — Reconcile & categorize

Compare the audit against `brew/Brewfile.{core,home,work}` in the repo and sort
every work-machine tool into exactly one bucket:

1. **WORK-ONLY** → you add it to `Brewfile.work` (AWS, IaC, work SaaS clients,
   company VPN, k8s if actually used here, internal CLIs, etc.).
2. **PROMOTE TO CORE** → used everywhere, currently missing from core. *Propose
   only* (§6).
3. **MOVE TO HOME** → personal/hobby tool present on work box. *Propose only.*
4. **PRUNE** → redundant (a kept tool does the same or better) or never used.
   *Propose only*; list with the superseding tool.
5. **KEEP AS-IS** → fallback/familiar/best-practice; no action.

Optimization goals for the **work profile** specifically (it has "deviated a
ton"): remove drift cruft, ensure the real work stack is captured (cloud,
secrets, CI, containers/registries, infra clients, internal tooling), and align
its shell/editor/runtime choices with §2.

---

## 5. Workflow rules (mirror the home session)

- **Approval gate:** present a written plan and get Jared's explicit "go" before
  installing/uninstalling/symlinking anything. He is deliberate about this.
- **Admin handoff:** print sudo/admin/GUI/interactive commands for Jared to run;
  don't run them yourself.
- **Backups:** timestamp-backup any file you overwrite (e.g. `~/.zshrc`).
- **Git hygiene:** do your work on a branch, e.g.
  `git switch -c work-machine-audit`. Commit `Brewfile.work` edits there and push
  so the home session can pull. Do **not** edit core/home (propose instead).
- **Don't break the working setup:** nodenv/python stay until mise is proven.

---

## 6. Required output (the relay-back block)

End your session by producing this block for Jared to paste into the **home**
Claude session. Be specific — names + rationale.

```markdown
## WORK MACHINE AUDIT — RELAY TO HOME SESSION

### Brewfile.work (edited directly on branch work-machine-audit)
- added: <formula/cask> — <why>
- removed: <formula/cask> — <why>

### PROMOTE TO CORE (for home session to apply)
- <tool> — <why it's used on every machine>

### MOVE TO HOME (for home session to apply)
- <tool> — <why it's personal/hobby>

### GLOBAL CLIs NOT IN HOMEBREW (npm/pnpm/cargo/pipx/go)
- <tool> (<manager>) — keep as managed global / convert to brew / ignore

### PRUNE CANDIDATES (need Jared's yes/no)
- <tool> — superseded by <kept tool> / never used

### NOTES / QUESTIONS
- <anything ambiguous for Jared to decide>
```

---

## 7. Reference: condensed current core/home/work (fallback if repo not synced)

Read the real files in `brew/` first. This snapshot is only a backup reference.

- **core:** GNU utils; modern CLI (eza, bat, fd, ripgrep, ripgrep-all, sd,
  zoxide, dust, duf, procs, btop, htop, ncdu, fastfetch, tealdeer, hyperfine,
  tokei); shell (atuin, direnv, fzf, tmux); **mise**; **just**; git (gh,
  git-delta, difftastic, lazygit, tig); data (jq, yq, fx, gron, jless);
  containers (lazydocker, dive, ctop, hadolint, trivy); net (xh, mtr, doggo,
  nmap, iftop, iperf); security (gnupg, pinentry-mac, mkcert, **trufflehog,
  gitleaks**); micro; files/media (broot, yazi, pv, wget, p7zip, yt-dlp, ffmpeg,
  wakeonlan, lftp, ocrmypdf, poppler, ddrescue); casks (visual-studio-code,
  iterm2, orbstack, bruno, tableplus, cyberduck, obsidian, ollama,
  1password(-cli), localsend, the-unarchiver, wireshark-app, powershell,
  font-meslo-lg-nerd-font).
- **home:** qemu/libvirt/spice-gtk/gtk-vnc, cc65, wimlib; casks: utm,
  dosbox-staging, retroarch, snes9x, audacity, iina, vlc, plex, plexamp, downie,
  shotcut, musescore, steam, gog-galaxy, carbon-copy-cloner, balenaetcher,
  grandperspective, keepingyouawake, openmtp, fpc-laz.
- **work:** awscli, granted, aws-sso-util, chamber, awslogs, opentofu,
  terragrunt, ansible, skopeo, crane; casks: session-manager-plugin, tunnelblick.
  (Kubernetes intentionally excluded — re-add k9s/helm only if this machine
  actually uses it.)
- **server (Linux/apt, not brew):** see `server/packages.apt` — modern CLI +
  general + admin/diagnostics; zsh/p10k identical to macOS via `links.conf`.
```
