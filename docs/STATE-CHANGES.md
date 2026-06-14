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

### P1-E — Templatize git identity (machine-specific) ✅
- **Audited tracked configs AND full git history** for secrets/PII: clean — no
  tokens/keys/IPs, no hardcoded user paths, and the real personal email was
  never committed in any blob. Only identity data in
  history is the GitHub **noreply** email + name (public-safe, already the author
  on pushed commits) → no history rewrite warranted. Old upstream-author emails
  (shanejonas/mjrusso) are pre-existing fork lineage, left intact.
- **Hardened `.gitignore`**: `.gitconfig.local`, `*.local`, `.env*`, `.netrc`,
  `secrets/` so local/sensitive files can never be committed.
- Only the git `[user]` block was identity-specific.
- Removed `[user]` from committed `git/gitconfig.symlink`; appended
  `[include] path = ~/.gitconfig.local`. Created `~/.gitconfig.local` (NOT in
  repo) with name/email. Added a `bootstrap.sh` step to create it (prompted) on
  new machines. Lets the work box use a work email.
- **Undo:** put `[user]` back in `gitconfig.symlink`, drop the include.

### P1-F — Remove legacy Rake installer ✅
- Removed `Rakefile` + `git/gitconfig.template` (the old Ruby installer + its
  template), fully superseded by `bootstrap.sh` (which now also handles the git
  identity templating the Rakefile used to do).
- **Undo:** `git revert <commit>`.

### P1-G — Integrate Claude Code + VS Code configs ✅
- **Claude:** `claude/settings.json` ← `~/.claude/settings.json` (unifi plugin/
  marketplace config; no secrets), symlinked back. **Excluded** `~/.claude.json`
  (account/MCP/project history — machine-specific) and all runtime dirs.
- **VS Code:** `vscode/{settings.json,keybindings.json,extensions.txt}`,
  symlinked into `~/Library/Application Support/Code/User/`. Scrubbed before
  commit: removed stale `sync.*` keys (2017 Settings-Sync cruft incl. a gist id);
  de-hardcoded an absolute workspace path → `$home/workspace`.
  33 extensions captured; bootstrap installs them via `code --install-extension`.
- `bootstrap.sh` extended with an "Editor configs" step (mac + Linux-desktop VS
  Code paths). Secret scan of all four files: clean.
- **Undo:** `mv` each file back, remove symlink (originals backed up in `backups/`).
- ⚠️ VS Code/Claude rewrite these files when you change settings in-app — that's
  fine (changes show as repo diffs); if an app ever replaces the symlink with a
  real file, re-run `bootstrap.sh` to relink.

### P1-H — Generalize VSCode path + fix global gitignore ✅
- `vscode/settings.json`: generalized a hardcoded `$home/workspace/<dir>` project
  path down to `$home/workspace`.
- **Fixed dead global gitignore:** `core.excludesfile` was unset, so git used
  `~/.config/git/ignore` and the repo's `~/.gitexcludes` did nothing. Set
  `core.excludesfile = ~/.gitexcludes` in the committed gitconfig and modernized
  `gitexcludes.symlink` (dropped dead SVN/Xcode-era cruft; added macOS + editor
  swap + `.claude/settings.local.json`). `~/.config/git/ignore` is now redundant.
- **Undo:** revert the two commits.

### Config sweep result (other tools — nothing more to add now)
- Default/untouched, not worth versioning: broot `conf.hjson`, gh `config.yml`.
- Secret/excluded: gh `hosts.yml` (token), TablePlus (DB creds), `~/.ssh/config`
  (infra) — the ssh config is high-value but belongs in Phase 4 as a template.
- Deferred to Phase 3 (create good ones / needs export): tmux.conf (repo's is
  stale + unlinked), `.nanorc`, `.ripgreprc`, global `.editorconfig`, bat/lazygit
  configs, iTerm2 prefs sync. `~/.config/htop/htoprc` available on request
  (skipped — htop rewrites it on quit, and btop is primary).

---

## Session 2026-06-13 — Phase 4: Linux server profile (branch `modernized-2026`)

### P4-A — Recon scaffold ✅ (earlier)
- `server/recon.sh` + `server/README.md`. Ran on Cerebro (Proxmox/Debian 13),
  Colossus (Ubuntu 24.04), Vulcan (Debian 13).

### P4-B — Build the shared server profile ✅
- Synthesized the 3 recon reports. All target tools are apt-installable on all
  three; Debian renames bat→batcat, fd→fdfind. Shell divergence: Cerebro/Colossus
  zsh+oh-my-zsh (Colossus also p10k+plugins), Vulcan bash-only.
- **Added:** `server/packages.apt` (modern CLI + general + admin/diagnostics),
  `server/shell.sh` (portable bash+zsh QoL; conservative aliasing; bat/fd shims;
  zoxide/fzf; docker+systemd+journal admin aliases; fastfetch on login),
  `server/setup.sh` (apt install skipping unavailable, shims, wires shell.sh into
  ~/.bashrc and ~/.zshrc — does NOT force zsh/p10k).
- **Promoted to macOS core:** `ncdu`, `fastfetch`.
- **Undo:** `rm -rf server/`; revert the Brewfile.core edit.

### P4-C — Pivot server profile to zsh-identical + SSH config ✅
- Per feedback ("make environments as identical as possible"; Vulcan's bash was
  just un-provisioned), the server profile now reuses the **same** Mac zsh config.
- Made Mac zsh config cross-platform: `path.zsh` adds `~/.local/bin`; `zshrc`
  oh-my-zsh plugins are OS-aware (`brew`/`macos` only on darwin; fzf/direnv moved
  to tools.zsh). Verified Mac still loads (profile=home, brew+macos present).
- Added `zsh/profile.server.zsh` (docker/systemd/journal/proxmox admin aliases +
  fastfetch on login); `profile.zsh` gains a `server` case.
- Rewrote `server/setup.sh`: installs apt packages + zsh + oh-my-zsh + p10k +
  plugins, bat/fd shims, sets profile=server, **symlinks the same dotfiles the
  Mac uses** (zshrc, p10k, gitconfig, gitexcludes, ssh/config), and `chsh` to zsh.
  Removed `server/shell.sh` (bash dup no longer needed).
- **SSH:** added committed `ssh/config` (Cerebro's cipher hardening + keepalive +
  `Include ~/.ssh/config.local`). Migrated this Mac: existing `~/.ssh/config`
  (27 lines, hosts) → `~/.ssh/config.local` (backup in `backups/`), symlinked the
  shared file. Verified `ssh -G cerebro` still resolves host + ciphers. Bootstrap
  does the same migration on new machines. `*.local` already gitignored.
- **Undo:** restore `~/.ssh/config` from backup; revert commits.

### Fixes — 2026-06-13 (later)
- **Merge unblocked:** `origin/master` had advanced (your "4 year update" +
  "remove garbage"); merged it into `modernized-2026`, resolved the one real
  conflict (`zsh/zshrc.symlink` → keep modernized) + kept `.DS_Store` deleted.
  Branch now merges cleanly to master.
- **zoxide init moved LAST** in `zshrc` (after p10k) — fixes the "initialize at end"
  warning and the empty-`cdi` problem (p10k was clobbering zoxide's dir hook).
- **`zsh/nudges.zsh`** added — retired tools (nodenv/node-build/nvm/pyenv/mc/
  ranger/ack/egrep/fgrep) print "use <modern tool>" instead of failing.
- **`cdf`** function — fuzzy-cd into ANY dir (no Alt key needed); `cdi` only lists
  visited dirs by design.

### Refactor — unified linker + first-class profiles ✅
- **Manifest linker:** added `links.conf` (one line per file: `source | target |
  when`) + `link.sh` (OS-aware, idempotent, backs up). Replaces the old mixed
  scheme (`*.symlink` glob + hardcoded config/claude/vscode/ssh mappings).
- **Dropped the `.symlink` suffix** — `git mv` zshrc/zprofile/p10k.zsh/gitconfig/
  gitexcludes; re-linked via manifest; verified the live `~` symlinks + zsh/git.
- **bootstrap.sh** + **server/setup.sh** now both just run `link.sh`; removed
  their bespoke link loops. bootstrap accepts ANY profile name (extensible).
- **First-class `server` profile:** peer of home/work in docs + profile system;
  same zsh/p10k config via the manifest's `when` gating.
- Merge conflict resolved (origin/master merged in); zoxide order fixed; nudges +
  `cdf` added; `~/.ssh/config` migrated to the Include pattern.
- **Undo:** `git revert` the relevant commits; `backups/` holds replaced files.

## Phase 3 — power-user, configs & security (branch `modernized-2026`)

### P3 batch 1 ✅
- **Pruned dead `bin/`:** removed `backup` (prev-owner's volume), `hn`, `webkit2png`,
  `json`, `search` (ack), `db` (old /usr/local), `e`/`et` (emacs). Kept all `git-*`,
  `here`, `flush-dns-cache`.
- **micro:** added `config/micro/settings.json` (sane modern CUA defaults: tabsize 2,
  trim ws, softwrap, system clipboard, incsearch…). Bindings already had comment-toggle.
- **New tool configs:** `config/ripgrep/config` (smart-case/hidden; via
  `RIPGREP_CONFIG_PATH`), `config/bat/config`. Linked via manifest.
- **zsh plugins:** added `fzf-tab` (fuzzy tab completion) + `you-should-use`
  (reminds you of aliases → reinforces the modern-tool habit). Wired into zshrc +
  both installers; cloned locally.
- **Security scanners:** `trufflehog` + `gitleaks` in Brewfile.core; `just secrets`
  recipe scans a repo on demand. (No global git hook — would conflict with husky.)
- **AI safety:** `claude/settings.json` now has `permissions.deny` blocking Claude
  from reading secrets (`.env`, `~/.ssh`, `~/.aws`, `~/.gnupg`, `*.key/*.pem`,
  `*.local`, `secrets/`, `.npmrc`, gh hosts).
- **Coordination:** added `just` + `Justfile` (link/install/update/secrets/server/
  servers) as the cross-machine entry point (chosen over ansible — lighter for a
  handful of hosts).
- **Undo:** `git revert`; `backups/` holds replaced files.

### P3 — ykman dropped + security doc ✅
- Removed `ykman` (no YubiKey anymore) from Brewfile.core + uninstalled.
- Added `docs/SECURITY.md` — posture + AI-safety roadmap. **agent-vault**
  (Infisical credential broker) evaluated & documented for later self-hosted
  deploy; 1Password `op run` noted for runtime secrets; SSH commit signing deferred.

### Fixes — servers rollout + Python consolidation
- p10k: `INSTANT_PROMPT=quiet` (server fastfetch banner) + `fastfetch --pipe false`
  (keep color); figlet hostname banner in the shared fastfetch base (seeded if absent).
- zoxide: init last + `_ZO_DOCTOR=0` (p10k re-juggles hooks → false-positive warning).
- fzf: version-aware init (`--zsh` on ≥0.48, distro files on Ubuntu 24.04's 0.44).
- bat: `--map-syntax *.jsonc/*.json5 → JSON` (older bat 0.24 lacks the mapping).
- Python: removed redundant brew `python@3.11` (nothing depended on it; pulled
  orphan `unbound` with it). mise (python 3.14) is the source of truth. Kept brew
  `python@3.14` (dependency of nmap/ocrmypdf/yt-dlp/pipx) + Apple `/usr/bin/python3`.
- **Undo:** `brew install python@3.11`.

## Still pending
- Run `server/setup.sh` on each box (`just servers` once pushed/synced).
- Terminal emulator (iTerm2 vs Ghostty) — deferred.
- Later: deploy agent-vault on a server; 1Password SSH commit signing; Claude
  skills/marketplaces (security-guidance, Semgrep) — see chat.
- Stale `~/.Brewfile`, `~/.fzf.{zsh,bash}`, `~/.config/mc` can be deleted to declutter.
- Phase 3 (power-user settings) — not started.
- 4 Phase 1 commits + these are local — **not pushed** (you chose Hold).
- Phase 3 (power-user settings) & Phase 4 (Linux server profile) — not started.
- C8 — install/adopt GUI casks (handed to you; sudo).
- Optional: set Homebrew zsh as login shell; delete dormant `~/.nodenv`.
- Phase 1 (later): prune dead `vim/`, `emacs/`, `ack/` topics; integrate stray
  home-dir dotfiles.
