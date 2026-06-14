# The Guide — features, rationale & use cases

Everything in this setup, why it's here, and how to use it. If you only read one
section, make it [Keybinding & alias cheat sheet](#keybinding--alias-cheat-sheet).

- [Philosophy](#philosophy)
- [The profile system](#the-profile-system)
- [Shell](#shell-zsh--oh-my-zsh--powerlevel10k)
- [Modern CLI replacements](#modern-cli-replacements-full-send)
- [Navigation & history](#navigation--history)
- [Git](#git)
- [Runtimes (mise)](#runtimes-mise)
- [Containers](#containers)
- [Data & JSON](#data--json)
- [Network & HTTP](#network--http)
- [Files, media & misc](#files-media--misc)
- [Home profile](#home-profile)
- [Work profile](#work-profile)
- [Server profile](#server-profile)
- [Keybinding & alias cheat sheet](#keybinding--alias-cheat-sheet)
- [How-to](#how-to)

---

## Philosophy

1. **Modern, mostly-Rust replacements** for the classic Unix tools — faster,
   friendlier defaults, better output. "Full send": the common tools are aliased
   so muscle memory carries over (`ls`, `cat`, `find`, `grep`, `cd`).
2. **Originals are never lost.** Aliases only affect interactive shells; scripts
   are unaffected. Reach the real tool with a backslash (`\ls`, `\grep`) or
   `command ls`. Shadowed builtins: `builtin cd`.
3. **Profiles over a shared core.** `Brewfile.core` is shared; each machine adds
   a profile (`home`/`work`/`server`, and the set is extensible). Symlinks are
   declared once in `links.conf`.
4. **Keep fallbacks.** Familiar/best-practice tools stay even when a fancier one
   exists (e.g. `htop` alongside `btop`, brew `python@3.11` alongside mise).
5. **Reproducible & reversible.** Everything is a committed file; changes are
   logged in [`STATE-CHANGES.md`](STATE-CHANGES.md); replaced files are backed up.

---

## The profile system

`~/.config/dotfiles/profile` holds the active profile (`home`/`work`/`server`;
the set is extensible). It drives:

- **Packages:** macOS → `brew/install.sh` installs `Brewfile.core` then
  `Brewfile.<profile>`. Linux server → `server/setup.sh` + `server/packages.apt`.
- **Shell:** `zsh/profile.zsh` sources `zsh/profile.<profile>.zsh`.

**Symlinks** for every profile/OS come from one manifest — `links.conf` — applied
by `link.sh`; the `when` column (all/macos/linux) gates per-OS files.

Add a profile: create `Brewfile.<name>` (or apt set) + `zsh/profile.<name>.zsh`.
Switch: `echo work > ~/.config/dotfiles/profile && brew/install.sh && exec zsh`.

---

## Shell: zsh + oh-my-zsh + Powerlevel10k

- **Powerlevel10k** prompt with instant-prompt (no startup lag). Reconfigure with
  `p10k configure`; config in `~/.p10k.zsh`. Needs a Nerd Font —
  `font-meslo-lg-nerd-font` is installed; set it in iTerm/VS Code.
- `.zshrc` is a thin **orchestrator** that sources modules in `zsh/`. Edit the
  module, not a giant rc file: `aliases.zsh`, `tools.zsh`, `functions.zsh`, etc.
- oh-my-zsh plugins: `git brew macos npm docker docker-compose fzf direnv
  zsh-autosuggestions zsh-syntax-highlighting`.
- History: large (100k), shared across sessions, dedup'd, space-prefixed commands
  are not recorded.

---

## Modern CLI replacements (full send)

| Command | Now runs | Original | Why |
|---------|----------|----------|-----|
| `ls` / `ll` / `la` / `lt` | **eza** | `\ls` | icons, git status, `--tree` |
| `cat` | **bat** (`--paging=never`) | `\cat` | syntax highlight; pipe-safe (auto-plain when piped); `catp` to page |
| `find` | **fd** | `\find` | simple syntax, fast, respects `.gitignore` |
| `grep` | **ripgrep** (`rg`) | `\grep` | fast recursive search, `.gitignore`-aware |
| `du` | **dust** | `\du` | visual size tree |
| `df` | **duf** | `\df` | readable, colored disk usage |
| `ps` | **procs** | `\ps` | human columns, `--tree` |
| `top` | **btop** | `\top` / `htop` | rich TUI (htop kept as fallback) |
| `dig` | **doggo** | `\dig` | clean DNS output |
| `http` | **xh** | — | ergonomic HTTP client |

Also available by their own names: `sd` (sed-like replace), `rga` (ripgrep over
PDFs/zips/docx), `tldr` (example-first help), `hyperfine` (benchmark), `tokei`
(count code), `mkcert` (local TLS certs).

> ⚠️ `find`→fd and `grep`→rg use **different argument syntax** than the originals.
> A pasted `find . -name '*.go'` will fail — use `\find` or rewrite as `fd -e go`.

**Retired tools nudge you forward.** Typing a removed/legacy tool (`nodenv`,
`nvm`, `pyenv`, `mc`, `ranger`, `ack`, `egrep`, `fgrep`) prints a pointer to its
replacement instead of failing (`zsh/nudges.zsh`). Force the original with
`command <name>`.

---

## Navigation & history

- **zoxide** powers `cd`. `cd` still works for real paths but learns your habits:
  `cd dot` jumps to `~/workspace/dotfiles`. `cdi` is an interactive picker over
  dirs **you've already visited** (frecency) — not the whole disk. `builtin cd`
  is the plain original.
- **`cdf`** — fuzzy-cd into ANY directory (fd + fzf). Use it when `cdi`/`Alt-C`
  don't have what you want.
- **fzf** fuzzy finder, wired with `fd` + `bat`/`eza` previews:
  - `Ctrl-T` — insert a file path (with preview)
  - `Alt-C` — cd into a directory. **macOS gotcha:** set iTerm → Settings →
    Profiles → Keys → Left Option = `Esc+`, or Option won't register as Alt
    (otherwise just use `cdf`).
  - `**<Tab>` — fuzzy-complete after any command (`vim **<Tab>`)
- **atuin** owns `Ctrl-R` — full-text, fuzzy, stats-rich history search across all
  sessions. Local-only (no sync/account). Enter puts the command on the prompt to
  **edit** (won't auto-run). Up-arrow stays the normal previous-command.
- **broot** — `br` launches the tree navigator (your existing config kept).

---

## Git

`git/gitconfig.symlink` wires:

- **delta** as the pager — syntax-highlighted, line-numbered diffs everywhere
  (`git diff`, `log -p`, `show`). `n`/`N` jump between files within a diff.
- **difftastic** on demand — `git dft` (alias) or `gdt` for structural,
  syntax-aware diffs that ignore reformatting noise.
- Sane defaults: `push.autoSetupRemote`, `pull.rebase`, `fetch.prune`,
  `rebase.autosquash/autostash`, `merge.conflictstyle=zdiff3`, histogram diff.
- Aliases: `st co sw br ci cm amend last lg unstage undo` (see the file).
- TUIs: **lazygit** (`lg`) for staging/committing/rebasing by keyboard;
  **tig** for browsing history; **gh** for PRs/issues from the terminal.

---

## Runtimes (mise)

`mise` replaced `nodenv` + manual `python@3.11`. One tool manages all language
runtimes and auto-switches per directory.

- Global versions: `config/mise/config.toml` → node 22, python 3.11.
- Per-project: drop a `mise.toml` (or use existing `.nvmrc`/`.tool-versions`).
- Commands: `mise use -g go@latest` (add a runtime), `mise install`, `mise ls`,
  `mise exec node@20 -- node app.js`.
- `direnv` complements it: an `.envrc` per project for env vars/secrets
  (`direnv allow` to trust it).
- Fallback: brew `python@3.11` is intentionally kept as a system-level Python
  independent of mise. Old `~/.nodenv` is dormant and can be deleted
  (`rm -rf ~/.nodenv`) to reclaim space.

---

## Containers

Runtime is **OrbStack** (the `docker` CLI talks to it). Tools:

- **lazydocker** (`lzd`) — TUI for containers/images/logs/stats.
- **dive** — inspect image layers and wasted space (`dive <image>`).
- **ctop** — top-like live container metrics.
- **hadolint** — lint a Dockerfile (`hadolint Dockerfile`).
- **trivy** — scan images/filesystems/repos for vulns (`trivy image <name>`).

> They need a running daemon — start OrbStack first.

---

## Data & JSON

- **jq** — the JSON workhorse. **yq** — same for YAML/TOML/XML.
- **fx** — interactive JSON explorer (`curl … | fx`).
- **gron** — flatten JSON to greppable lines (`gron file.json | rg foo`).
- **jless** — pager for large JSON.

---

## Network & HTTP

- **xh** (`http`) — fast, friendly HTTP requests (`http GET api/...`).
- **doggo** (`dig`) — modern DNS lookups.
- **mtr** — combined traceroute+ping for path diagnosis.
- Kept: `nmap`, `iftop`, `iperf` (raw L4 bandwidth), plus GUI Wireshark.

---

## Files, media & misc

- **yazi** (`y`) — fast TUI file manager (replaced midnight-commander). Vim-style
  keys: `hjkl` move, `Enter`/`l` open, `Space` select, `y`/`x`/`p` yank/cut/paste,
  `q` quit. `:` for commands.
- Kept utilities: `broot`, `pv`, `wget`, `p7zip`, `ffmpeg`, `yt-dlp`, `wakeonlan`,
  `lftp`, `ocrmypdf`, `poppler` (pdftotext…), `ddrescue`.
- Functions: `mkcd <dir>` (make+enter), `extract <archive>` (any format),
  `llm-start`/`llm-stop` (Ollama + Open WebUI), `reload` (`exec zsh`).

---

## Home profile

Virtualization (`qemu`, `libvirt`, `gtk-vnc`, `spice-gtk`; GUI UTM),
retro/low-level (`cc65`, `wimlib`; emulators DOSBox Staging, RetroArch, Snes9x),
media (Audacity, IINA, VLC, Plex/Plexamp, Downie, Shotcut, MuseScore), games
(Steam, GOG Galaxy), disk tools (Carbon Copy Cloner, balenaEtcher,
GrandPerspective, KeepingYouAwake), and Pascal/Lazarus.

> `virt-viewer` is intentionally **not** in the Brewfile — it only ships in an
> untrusted third-party tap. Install manually if ever needed (see `Brewfile.home`).

---

## Work profile

AWS (`awscli`, `granted`/`assume`, `aws-sso-util`, `chamber`, `awslogs`,
`session-manager-plugin`), IaC (`opentofu`→`tofu`, `terragrunt`→`tg`, `ansible`),
registry/image tooling (`skopeo`, `crane`), VPN (`tunnelblick`). Shell extras in
`zsh/profile.work.zsh` (e.g. `a`=assume, `tf`=tofu, `tg`=terragrunt). Kubernetes
is intentionally excluded — add `k9s`/`helm` only if a machine truly needs it.

The work machine has drifted; run the audit in
[`work-machine-audit.md`](work-machine-audit.md) there to reconcile it.

---

## Server profile

Headless Linux (Debian/Ubuntu), provisioned by `server/setup.sh` (apt, not brew).
Reuses the **same** zsh + p10k + aliases as macOS via `links.conf`; Mac-only tools
no-op. Adds `server/packages.apt` (modern CLI + admin/diagnostics: mtr, nmap,
iftop, nethogs, iotop, tcpdump, smartmontools, lm-sensors, ncdu…) and admin
aliases in `zsh/profile.server.zsh` (`dps`, `dl`, `dcl`, `ports`, `j`, `sc`,
Proxmox `vms`/`cts`) plus `fastfetch` on login. Debian's `bat`/`fd` renames are
shimmed back to their real names. Provision all hosts with `just servers` (host
list in gitignored `~/.config/dotfiles/servers`). See [`server/`](../server/).

---

## Keybinding & alias cheat sheet

| Key / cmd | Action |
|-----------|--------|
| `Ctrl-R` | atuin history search |
| `Ctrl-T` | fzf: insert file path |
| `Alt-C` | fzf: cd into directory |
| `… **<Tab>` | fzf fuzzy completion |
| `cd x` / `cdi` | zoxide jump / interactive |
| `ll` `la` `lt` | eza long / all / tree |
| `lg` `lzd` `y` | lazygit / lazydocker / yazi |
| `gdt` / `git dft` | structural (difftastic) diff |
| `z -` / `cd -` | previous dir |
| `\cmd` / `command cmd` | bypass an alias |
| `builtin cd` | original cd |
| `reload` | restart the shell |

---

## How-to

**Add a CLI tool** → add `brew '<name>'` to the right `brew/Brewfile.*`, run
`brew/install.sh`, and (if it needs aliasing/init) edit `zsh/aliases.zsh` or
`zsh/tools.zsh`.

**Add a config file** → put it under `config/<tool>/…` and re-run `bootstrap.sh`
(or `ln -s` it into `~/.config/<tool>/…`). It'll be symlinked, not copied.

**Add a runtime** → `mise use -g <lang>@<version>` (global) or commit a
`mise.toml` in the project.

**Secrets / machine-specific bits** → `~/.localrc` (sourced last, never committed).

**Undo something** → see [`STATE-CHANGES.md`](STATE-CHANGES.md) for the per-change
revert steps; backups are in `backups/`.
