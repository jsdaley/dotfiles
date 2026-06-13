# State Changes Log

A running, reversible record of every change made during the dotfiles
modernization. Each entry says **what changed** and **how to undo just that
change** without reverting everything else.

- Most repo file changes are also recoverable via `git` (this repo:
  `github.com/jsdaley/dotfiles`).
- Backups of replaced real files use the suffix `.backup` or live under
  `backups/` with a timestamp.
- Status legend: ⏳ in progress · ✅ done · ↩️ reverted

---

## Session 2026-06-13 — Phase 2: tool integration

### Preflight (no changes)
- Verified: admin group ✅, **passwordless sudo NOT available** (sudo/cask steps
  handed to you), Homebrew prefix `/opt/homebrew` owned by you (formulae need no
  sudo), 41Gi free, brew API reachable, git remote `origin` present.
- Reality vs assumptions: OrbStack/docker daemon **not running**, `orbstack` CLI
  not on PATH, `mise` not installed (expected). Container tools install anyway.

---

### C1 — Brewfile profile system ✅
- **Added:** `brew/Brewfile.core`, `brew/Brewfile.home`, `brew/Brewfile.work`
- **Undo:** `rm -rf brew/` (nothing else references it yet).

### C2 — Work-machine handoff doc ✅
- **Added:** `docs/work-machine-audit.md`
- **Undo:** `rm docs/work-machine-audit.md`

### C3 — Memory (Claude's persistent memory, outside this repo) ✅
- **Added:** `~/.claude/projects/-Users-jsdaley-workspace-dotfiles/memory/`
  → `admin-command-handoff.md`, `dotfiles-modernization.md`, `MEMORY.md`
- **Undo:** delete those files.

### C4 — Install core+home formulae ✅
- **Action:** `brew bundle` of all `brew` lines from Brewfile.core + Brewfile.home
  (formulae only; casks handled separately). 45 formulae installed.
- **First attempt aborted** on `virt-viewer` (untrusted tap) → removed virt-viewer
  from Brewfile.home (use UTM/VMware GUIs instead). Re-ran clean.
- **Side effect fixed:** the bundle's failed *upgrade* of `libvirt` removed
  `libvirt`, `libvirt-glib`, `gtk-vnc`, `spice-gtk`. **Restored** via
  `brew install libvirt libvirt-glib gtk-vnc spice-gtk` (all present again).
- **Undo (per tool):** `brew uninstall <formula>`. Full list = the `brew` lines in
  `brew/Brewfile.core` + `brew/Brewfile.home`.

### C5 — zsh modular refactor ✅
- **Added modules:** `zsh/{path,aliases,tools,functions,profile,profile.home,profile.work}.zsh`
- **Rewrote:** `zsh/zshrc.symlink` into a thin orchestrator (backup:
  `backups/zshrc.symlink.20260613-145511.bak`).
- Behavior changes: `cd`→zoxide (`--cmd cd`), Ctrl-R→atuin, fzf via `fzf --zsh`
  (no more `~/.fzf.zsh`), mise replaces nodenv init, dropped forced
  `TERM=screen-256color` and legacy MacPorts/X11 PATH entries.
- **Undo:** `cp backups/zshrc.symlink.<ts>.bak zsh/zshrc.symlink` and delete the
  new `zsh/*.zsh` modules; `exec zsh`.

### C6 — git config ✅
- **Rewrote** `git/gitconfig.symlink`: delta pager, difftastic alias (`dft`),
  aliases, sane defaults. (backup: `backups/gitconfig.symlink.20260613-145511.bak`)
- **Undo:** restore that backup.

### C7 — tool configs symlinked into ~/.config ✅
- **Added:** `config/atuin/config.toml`, `config/mise/config.toml`
- **Symlinked:** `~/.config/atuin/config.toml`, `~/.config/mise/config.toml`
- **Wrote marker:** `~/.config/dotfiles/profile` = `home` (local state, not in repo)
- **Undo:** `rm ~/.config/atuin/config.toml ~/.config/mise/config.toml` (restore
  any `*.bak` siblings if present).

### C8 — GUI casks ✅ (you ran it) — mostly done
- **Adopted/installed/upgraded (27):** visual-studio-code, iterm2, orbstack,
  bruno, tableplus, cyberduck, obsidian, ollama, 1password, 1password-cli,
  localsend, the-unarchiver, powershell, **font-meslo-lg-nerd-font (new)**,
  **iina (new)**, vlc, plex, plexamp, downie, xld, musescore, steam, gog-galaxy,
  carbon-copy-cloner, keepingyouawake, audacity, fpc-laz.
- **Failed: version mismatch (need `--force`):** utm, dosbox-staging, retroarch,
  snes9x, shotcut, balenaetcher, grandperspective. (Installed app older than cask;
  fixed with `brew install --cask --force <name>`.)
- **Failed: wireshark-app** → `brew reinstall --cask --force wireshark-app`.
- **Removed from Brewfile.home:** `vmware-fusion` (cask disabled by Homebrew),
  `fpc-src-laz` (deprecated + pkg incompatible with current macOS). Keep manual
  installs. `xld` installed but flagged deprecated (disabled 2026-09-01).
- **Undo (per cask):** `brew uninstall --cask <name>` (the app stays if you used
  `--force`; Homebrew just stops managing it).

### C9 — mise runtime migration ✅
- `mise install` → node 22.22.3, python 3.11.15 (from `config/mise/config.toml`).
- Reinstalled `@anthropic-ai/claude-code` under mise node (was under nodenv);
  `claude` now resolves to mise node (v2.1.177).
- **Undo:** re-init nodenv in `zsh/tools.zsh` (fallback branch already present);
  `mise uninstall node python` if desired.

### C10 — prune ✅
- **Removed:** `midnight-commander` (→ yazi; also pulled its private deps
  `s-lang`, `diffutils`). `nodenv` + `node-build` (→ mise; pulled `autoconf`,`m4`).
- **Kept intentionally:** `python@3.11` (system fallback), `htop` (btop fallback).
- `brew autoremove` (no orphans) + `brew cleanup` (freed ~394MB).
- **Undo:** `brew install midnight-commander` / `brew install nodenv node-build`.
- Left on disk (optional manual cleanup): `~/.nodenv`, `~/.config/mc`.

### C11 — automation scripts ✅
- **Added:** `bootstrap.sh` (idempotent new-machine setup), `brew/install.sh`
  (profile-aware bundle). Both `chmod +x`.
- **Undo:** `rm bootstrap.sh brew/install.sh`.

### C12 — docs ✅
- **Rewrote:** `README.md`. **Added:** `docs/GUIDE.md`, this file.
- **Undo:** restore README from git; `rm docs/GUIDE.md`.

### C13 — Intel-app cleanup & native swaps ✅ (you ran removals)
- **Added to Brewfile.home:** `openmtp` (native Android file transfer).
- **Apps removed (direct-installed, by you):** Android File Transfer, Pocket,
  RenameMyTVSeries, TeamViewer, Reeder, Luminar Neo, Stacher,
  Softorino YouTube Converter PRO, WebTools-NG.
- **Kept (your call):** Harmony Desktop (frozen but functional). Simple Comic —
  you'll update to the Universal build yourself.
- **Native migrations done via brew --force:** utm, dosbox-staging, snes9x,
  shotcut, balenaetcher, grandperspective (all now arm64). retroarch reinstalled
  but Intel upstream → Rosetta.
- **wireshark-app:** reinstall hit a Homebrew bug (uninstall script referenced a
  missing `Remove Wireshark from the system path.pkg`). Fixed by clearing the
  caskroom dir then `brew install --cask --force` — now 4.6.6, native, managed.
- **App removals done via Finder (drag to Trash):** the listed apps + TeamViewer.
  TeamViewer launch agents/daemons removed with `sudo rm` from
  `/Library/Launch{Agents,Daemons}/com.teamviewer.*`.
- **Verified remaining Intel apps (all expected — no native exists or kept):**
  GOG Galaxy, Steam Link, RetroArch, Origin, QNAP External RAID Manager,
  Harmony Desktop, Simple Comic, Hocus Pocus, SimCity 2000, Theme Hospital.
- **Undo:** reinstall any app from its vendor / the App Store; trashed apps are in
  `~/.Trash` until emptied.

---

### C14 — Commit & push ✅
- Branch **`modernized-2026`** (off master) committed (21 files) and pushed.
- Cleaned up: 9 junk files (`<cask>; brew install …`) from a mangled terminal
  paste were accidentally committed by `git add .`, then removed via `git rm` +
  `git commit --amend` before push.
- **Remote switched HTTPS → SSH** (`git@github.com:jsdaley/dotfiles.git`) — push
  over HTTPS password is no longer supported; SSH key already authenticates.
- `master` is untouched. Merge/PR when ready.
- **Undo:** `git checkout master` (branch isolated). Per-change reverts above.

---

## Session 2026-06-13 — Phase 1: prune & integrate (branch `modernized-2026`)

### P1-A — Remove dead topics ✅
- `git rm -r ack emacs vim` (superseded by VSCode/micro + ripgrep; none were
  symlinked into `$HOME`). **Undo:** `git revert <commit>` or restore from history.

### P1-B — .gitignore + .DS_Store ✅
- Fixed wrong-case `**/*.DS_STORE` → `.DS_Store` / `**/.DS_Store` (the bug that
  let `.DS_Store` get tracked). Untracked `.DS_Store`, removed dead emacs/vim
  rules, un-ignored `git/gitconfig.symlink`. **Undo:** `git revert <commit>`.

### P1-C — Version-control git config ✅
- Committed `git/gitconfig.symlink` (delta/aliases) — Phase 2 wrote it but
  .gitignore was hiding it, so it had never been committed. **Undo:** re-add the
  ignore line + `git rm --cached`.

### P1-D — Integrate stray home-dir dotfiles ✅
- Moved into repo + symlinked back: `~/.p10k.zsh` → `zsh/p10k.zsh.symlink`,
  `~/.zprofile` → `zsh/zprofile.symlink`, `~/.config/micro/bindings.json` →
  `config/micro/bindings.json`.
- **Skipped:** empty `micro/settings.json` (Phase 3), bash-only `.bashrc`, stale
  `~/.Brewfile` (superseded by `brew/Brewfile.*`), stale `~/.fzf.{zsh,bash}` (no
  longer sourced — `fzf --zsh` used instead). Secrets untouched (.ssh/.aws/.netrc/
  .gnupg/.config/{op,gh}/.docker).
- **Undo:** `mv` each file back out of the repo and remove the symlink.

## Still pending (flagged for your decision)
- Legacy `Rakefile` + `git/gitconfig.template` are superseded by `bootstrap.sh` —
  remove? (not done unprompted)
- Stale `~/.Brewfile`, `~/.fzf.{zsh,bash}`, `~/.config/mc` can be deleted to declutter.
- Phase 3 (power-user settings) & Phase 4 (Linux server profile) — not started.
- C8 — install/adopt GUI casks (handed to you; sudo).
- Optional: set Homebrew zsh as login shell; delete dormant `~/.nodenv`.
- Phase 1 (later): prune dead `vim/`, `emacs/`, `ack/` topics; integrate stray
  home-dir dotfiles.
