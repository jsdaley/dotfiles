# Machine Audit & Onboarding — Claude Code Handoff (any machine)

**Hand this to a Claude Code session on *any* machine you want to inventory and
bring into these dotfiles.** It is self-contained — assume no prior context.

Fill these in before you start:

| | |
|---|---|
| **MACHINE** | `<hostname>` |
| **OS** | macOS (Apple Silicon) · Debian/Ubuntu Linux |
| **PROFILE** | `home` · `work` · `server` · `<new-name>` (a new machine *type* → you may CREATE a profile, §5) |

---

## 0. Your mission

1. **Audit** everything actually installed (packages, casks/apps, language-global
   CLIs across *every* version manager, GUI apps outside the package manager).
2. **Reconcile** it against this repo's Brewfiles / apt set.
3. **Make this machine's profile reflect REAL usage** — own its profile file
   (`Brewfile.<profile>` or `server/packages.apt`) and edit it directly.
4. **Propose (do NOT edit) changes to shared files** (`Brewfile.core`, other
   profiles) — emit the relay block in §7 for the home session to apply centrally.
   This stops two machines from fighting over shared files.
5. **Propose a prune list** of drift/redundant/never-used tools (see the
   companion `machine-cleanup.md`).

> ⚠️ **Change nothing until Jared explicitly approves your plan.** Always:
> analyze → present plan → get the go → act. Rules in §6.

---

## 1. The repo you're reconciling against

- Modernized Holman-style dotfiles. **Declarative symlinks:** `links.conf`
  (`source | target | when`), applied by `link.sh` (OS-aware: all/macos/linux).
- **Profiles are first-class & extensible:** stored in `~/.config/dotfiles/profile`.
  Each profile = a `Brewfile.<name>` (macOS) **or** the shared `server/packages.apt`
  (Linux) + an optional `zsh/profile.<name>.zsh`. Installers: `bootstrap.sh`
  (macOS), `server/setup.sh` (Linux). `just` is the cross-machine entry point.
- **First action:** `cd ~/workspace/dotfiles && git pull` (clone from Jared's
  GitHub if absent — ask for the URL). Work against current files.
- **Detect context:** `uname -s`, `sw_vers 2>/dev/null`, `cat ~/.config/dotfiles/profile 2>/dev/null`.

---

## 2. Owner profile & hard preferences (apply to EVERY machine)

- **Role:** programmer / DevOps. **Node is the primary language** — expect many
  CLIs installed as npm/pnpm globals.
- **Editors:** VS Code (GUI) + **micro** (terminal; `nano` is aliased to micro).
  **Never install or configure vim/neovim as the editor.**
- **Shell:** zsh + oh-my-zsh + **Powerlevel10k**.
- **Container runtime:** **OrbStack** (provides docker + kubectl; not Docker Desktop).
  **API client:** Bruno (not Postman, except where work mandates it).
- **Runtimes:** **mise** manages node/python/go/ruby — *not* nodenv/nvm/rbenv/pyenv
  or brew language formulae.
- **Terminal:** Ghostty (primary) / iTerm2. **History:** atuin (Ctrl-R).
  **Git diffs:** delta pager + `git dft` (difftastic) on demand.
- **Modernization stance:** "full send" on modern CLI replacements, but keep the
  originals reachable via backslash (`\ls`). Only remove what he'll *never* use.
- **Privileged steps:** anything needing **sudo / admin / GUI consent / App Store /
  interactive input** is handed to Jared as copy-paste commands — do **not** run
  them yourself. He pastes results back.
- **Secrets:** reads of `~/.ssh`, `.env`, key/cred files may be blocked by policy —
  that's intentional; hand those to Jared. **Never** put secrets or private LAN
  topology in the (public) repo; machine-specific bits go in `~/.*.local` files.

---

## 3. The canonical toolset (the standard to reconcile against)

When you find a tool on the machine, first ask: **does it map to something already
in the standard stack?** If yes, it's covered — note it and move on. If it's novel,
classify it (§5). The standard core stack (see §8 for the full list / real files):

- **Modern CLI:** eza·bat·fd·ripgrep·sd·zoxide·dust·duf·procs·btop·yazi·broot +
  fastfetch·tealdeer·hyperfine·tokei·ncdu.
- **Shell/dev:** atuin·direnv·fzf·tmux·mise·just·gh·git-delta·difftastic·lazygit·tig.
- **Data:** jq·yq·fx·gron·jless. **Containers:** lazydocker·dive·ctop·hadolint·trivy.
- **Net:** xh·mtr·doggo·nmap. **Security:** gnupg·mkcert·trufflehog·gitleaks.
- **Editor:** micro. **Runtimes:** mise (node/python/go/ruby).
- **Claude Code:** the **native installer** (`~/.local/bin/claude`), NOT an npm global.

---

## 4. Phase A — Audit (read-only; safe to run now)

Run the block for this machine's OS and **save the output to a file** — it's the
recovery record (§6). Nothing here changes anything.

### macOS
```bash
brew leaves                      # top-level formulae (the real signal)
brew list --cask                 # casks
brew tap                         # taps (note any untrusted ones)
brew autoremove --dry-run        # orphaned deps (prune candidates)
ls /Applications ~/Applications  # GUI apps installed outside brew
```

### Linux (Debian/Ubuntu)
```bash
apt-mark showmanual               # manually-installed apt packages (the real signal)
snap list 2>/dev/null
ls ~/.local/bin                   # hand-dropped binaries (e.g. bat/fd shims, yazi)
```

### Language-global CLIs (BOTH OSes — the high-value, easy-to-miss part)
npm globals are tied to a **specific** node install, so the active version shows
only a slice. **Enumerate every version of every manager**, not just the current:
```bash
# node: try whichever manager(s) exist (nodenv shown; adapt for nvm/fnm/asdf/mise)
for v in $(nodenv versions --bare 2>/dev/null); do
  echo "== nodenv $v =="; NODENV_VERSION="$v" nodenv exec npm ls -g --depth=0 2>/dev/null
done
nvm ls 2>/dev/null; npm ls -g --depth=0 2>/dev/null   # nvm / current
pnpm ls -g --depth=0 2>/dev/null; pnpm root -g 2>/dev/null
yarn global list 2>/dev/null; bun pm ls -g 2>/dev/null
# python / rust / go / ruby
pipx list 2>/dev/null; uv tool list 2>/dev/null
cargo install --list 2>/dev/null
ls "$(go env GOPATH 2>/dev/null)/bin" 2>/dev/null
gem list --no-versions 2>/dev/null | head -40
# runtime managers present?
for m in mise nodenv nvm fnm asdf rbenv pyenv goenv; do command -v "$m" >/dev/null 2>&1 && echo "manager: $m"; done
```

For **each** global CLI: is it a (a) system/dev tool that belongs in a profile or
re-homed durably, (b) a project dep accidentally global (leave it), or (c)
superseded by a brew/apt package (prefer the package for reproducibility)?

> ⚠️ **SAVE the lists above to a file FIRST** (e.g. `> ~/Desktop/$MACHINE-globals.txt`).
> The home machine permanently lost its node globals (incl. claude-code) by tearing
> down a version manager before saving them. This is the recovery record; the
> teardown order is enforced in `machine-cleanup.md` §1.

---

## 5. Phase B — Reconcile & categorize

Sort every tool into exactly one bucket:

1. **PROFILE-ONLY** → add to this machine's `Brewfile.<profile>` (or `packages.apt`):
   the things genuinely specific to this machine's role.
2. **PROMOTE TO CORE** → used on every machine, missing from core. *Propose only* (§7).
3. **MOVE TO ANOTHER PROFILE** → e.g. a hobby tool on a work box. *Propose only.*
4. **PRUNE** → drift / redundant (a kept tool does it better) / never used.
   *Propose only*; pair each with its superseding tool. (Execution: `machine-cleanup.md`.)
5. **KEEP AS-IS** → fallback / familiar / best-practice; no action.

**New machine *type*?** If no existing profile fits, CREATE one:
- macOS: add `brew/Brewfile.<name>` + (optional) `zsh/profile.<name>.zsh`; it's
  picked up by `bootstrap.sh <name>`.
- Linux: it likely uses the `server` profile + `server/packages.apt`; add a
  `zsh/profile.<name>.zsh` only if it needs machine-class-specific aliases.
- Register the choice in `~/.config/dotfiles/profile`. Mention the new profile in
  the relay block so the home session can wire README/links if needed.

---

## 6. Workflow rules

- **Approval gate:** written plan → explicit "go" → act. Jared is deliberate.
- **Admin handoff:** print sudo/admin/GUI/App-Store/pkg commands for Jared; don't run them.
- **Backups:** `link.sh` timestamp-backs-up anything it replaces (into `backups/`).
  After linking, **check `backups/` for the machine's prior config** and salvage
  anything worth keeping before it's gone.
- **Git hygiene:** own your profile file; **propose** (don't edit) shared files.
  If editing your profile file, do it on master or a short branch and push so the
  home session can pull.
- **Don't break the working setup:** old version managers (nodenv/rbenv/pyenv)
  stay until mise is proven, and **never delete `~/.<manager>` until its globals
  are saved to a file AND re-homed**.
- **Stale package manager:** if `brew --version` (or apt metadata) is old, refresh
  first — `brew update && brew cleanup --prune=all` (macOS) / `sudo apt update`
  (Linux). Stale brew throws spurious "No Cask with this name exists" / `.incomplete`
  errors that look like failures but aren't.
- **Verify every token before proposing it** — `brew info <name>` (macOS) /
  `apt-cache show <name>` (Linux). Packages drift: cask↔formula moves, renames,
  and disabled/discontinued casks are common (recent real ones: `powershell` is now
  a formula; `ollama`→`ollama-app`; `retroarch`→`retroarch-metal`;
  `redisinsight`→`redis-insight`; `azure-data-studio` discontinued → use the
  `ms-mssql.mssql` VS Code extension; `terraform` left core → `hashicorp/tap`).
- **Secret-scan anything before sharing it** (history, dumps): `gitleaks detect
  --no-git --redact` offline — never paste raw history/credentials back.

---

## 7. Required output (the relay-back block)

End the session with this for Jared to paste into the **home** session:

```markdown
## MACHINE AUDIT — RELAY TO HOME SESSION   (machine: <NAME>, profile: <PROFILE>)

### Brewfile.<profile> / packages.apt (edited directly)
- added: <tool> — <why>
- removed: <tool> — <why>

### PROMOTE TO CORE (home session applies)
- <tool> — <why it's used on every machine>

### MOVE TO ANOTHER PROFILE (home session applies)
- <tool> — <which profile + why>

### NEW PROFILE (if created)
- <name> — <machine class + what's distinct>

### GLOBAL CLIs NOT IN THE PACKAGE MANAGER (npm/pnpm/cargo/pipx/go/gem)
- <tool> (<manager>) — keep as managed global / convert to package / re-home / ignore

### PRUNE CANDIDATES (Jared yes/no)
- <tool> — superseded by <kept tool> / never used

### NOTES / QUESTIONS
- <ambiguities for Jared>
```

---

## 8. Reference: condensed current profiles (fallback if repo not synced)

Read the real `brew/Brewfile.*` and `server/packages.apt` first — this is only a backup.

- **core:** GNU utils; modern CLI (eza, bat, fd, ripgrep, ripgrep-all, sd, zoxide,
  dust, duf, procs, btop, htop, ncdu, fastfetch, tealdeer, hyperfine, tokei, parallel);
  shell (atuin, direnv, fzf, tmux, powershell); **mise**; **just**; git (gh, git-delta,
  difftastic, lazygit, tig); data (jq, yq, fx, gron, jless); containers (lazydocker,
  dive, ctop, hadolint, trivy); net (xh, mtr, doggo, nmap, iftop, iperf, wireguard-tools);
  security (gnupg, pinentry-mac, mkcert, trufflehog, gitleaks); micro; files/media
  (broot, yazi, pv, wget, p7zip, yt-dlp, ffmpeg, wakeonlan, lftp, ocrmypdf, poppler,
  ddrescue); casks (visual-studio-code, ghostty, iterm2, orbstack, bruno, tableplus,
  cyberduck, obsidian, ollama-app, 1password(-cli), localsend, the-unarchiver, maccy,
  tunnelblick, wireshark-app, font-meslo-lg-nerd-font); mas (WireGuard); go via mise.
- **home:** qemu/libvirt/spice-gtk/gtk-vnc, cc65, wimlib; casks: utm, dosbox-staging-app,
  retroarch-metal, snes9x, audacity, iina, vlc, plex, plexamp, downie, shotcut, musescore,
  steam, gog-galaxy, carbon-copy-cloner, balenaetcher, grandperspective, keepingyouawake,
  openmtp, fpc-laz.
- **work:** awscli, granted, hashicorp/tap/terraform, protobuf, jmeter, parquet-cli,
  pipenv, pnpm, steampipe, actions-up; casks: postman, kreya, aws-vpn-client, postico,
  dbeaver-community, mysql-shell, redis-insight. (Postgres/Redis are containers;
  docker/kubectl from OrbStack; go from mise — not brew.)
- **server (Linux/apt):** see `server/packages.apt` — modern CLI + general +
  admin/diagnostics; yazi installed from its upstream `.deb`; zsh/p10k identical to
  macOS via `links.conf`.
