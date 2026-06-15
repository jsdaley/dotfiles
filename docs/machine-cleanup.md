# Machine Cleanup — Post-Onboarding Handoff (any machine)

**Hand this to the Claude Code session on a machine *after* it's been onboarded
into the dotfiles** (see `machine-audit.md` first). Self-contained.

Fill in: **MACHINE** = `<hostname>` · **PROFILE** = `<home|work|server|…>`.

By now the machine should be on the modernized dotfiles (`~/.zshrc` → repo,
profile set, mise managing runtimes, native `claude` in `~/.local/bin`, profile
packages installed). **What remains is removing drift that ISN'T in the
dotfiles** — mostly uninstalls — plus safety-critical ordering.

> ⚠️ **Rules:** present a plan and get Jared's explicit "go" before uninstalling
> anything. **Hand all sudo / admin / GUI / App-Store / pkg-uninstaller steps to
> Jared as copy-paste** — don't run them. Back up anything you overwrite.
>
> ⛔ **Never touch** MDM / security-managed software (e.g. SentinelOne, Rippling,
> corp VPN/EDR). When unsure, ask.

---

## 0. Sync + install the profile's packages

```bash
cd ~/workspace/dotfiles && git pull
# macOS: refresh brew FIRST if it's stale (avoids spurious "No Cask" errors)
brew update && brew cleanup --prune=all
brew bundle --file brew/Brewfile.core && brew bundle --file brew/Brewfile.<profile>
# Linux: bash server/setup.sh   (idempotent; installs only what's missing)
```

---

## 1. SAFETY-CRITICAL ORDER — before tearing down any runtime manager

The home machine permanently lost its global npm packages (incl. claude-code) by
deleting `~/.nodenv` before saving/re-homing them. **Do this first, every time.**

**1a. Save every language-global to a file (recovery record):**
```bash
{ for v in $(nodenv versions --bare 2>/dev/null); do
    echo "== nodenv $v =="; NODENV_VERSION="$v" nodenv exec npm ls -g --depth=0 2>/dev/null
  done
  echo "== pnpm =="; pnpm ls -g --depth=0 2>/dev/null
  gem list --no-versions 2>/dev/null
} > ~/Desktop/$MACHINE-globals.txt
```
Review with Jared. Re-home anything worth keeping as a **package or the tool's own
installer** — *not* an npm/gem global (those don't survive a runtime teardown).

**1b. Fix the `claude` PATH, then drop any npm shadow:**
```bash
which claude && claude --version    # MUST be ~/.local/bin/claude (native), not a shim
```
- If native: `npm rm -g @anthropic-ai/claude-code` (remove the old global).
- If it still resolves to a version-manager shim: the relinked `zsh/path.zsh`
  (which puts `~/.local/bin` first, and the repo zsh has no `nodenv/rbenv init`)
  isn't active yet — open a fresh shell / `exec zsh` and recheck **before** removing.

**Only after 1a + 1b** may old version managers be pruned (§3, "runtime migration").

---

## 2. Package-manager hygiene (macOS)

New Homebrew requires trusting third-party taps. **Trust the taps you actually
use; untap orphans:**
```bash
brew tap                                   # list them
brew trust --formula <user>/<tap>/<formula>   # for taps a kept tool needs
brew untap <user>/<tap>                        # for taps nothing uses anymore
```
(If a formula you want migrated from a tap into homebrew-core, reinstall it from
core and untap — e.g. steampipe is core now, not turbot/tap.)

---

## 3. PRUNE — drift not tracked in the dotfiles (confirm each with Jared)

Always check reverse-deps before removing a package: `brew uses --installed <name>`
(macOS) / `apt-rdepends -r <name>` or `apt-mark showmanual` (Linux). Categories,
with real examples from past machines:

**Replaced by a kept tool** — remove the old one:
- Docker Desktop → OrbStack (remove app + `/usr/local/bin/{docker,kubectl}` shims). **Admin/GUI.**
- old clipboard manager (Clipy) → `maccy`; BloomRPC → `kreya`; midnight-commander → `yazi`.
- official AWS CLI pkg (`/usr/local/bin/aws`) → `brew 'awscli'` (use AWS's pkg uninstaller). **Admin.**
- a discontinued app whose successor is an extension/tool (Azure Data Studio → `ms-mssql.mssql`).

**No longer used** — uninstall (Tableau, circleci, putty-if-unused, etc.). **GUI apps → Jared.**

**Run as containers, not on metal** — uninstall the metal install (postgresql@N, redis, …).

**Runtime migration to mise (ONLY after §1):**
- `nodenv`/`nvm` + `~/.nodenv` etc. — prune after globals saved + re-homed.
- `rbenv`/`pyenv` — mise manages ruby/python on demand; prune after migrating.
- EOL brew language formulae (`python@3.8/3.9`, `openssl@1.1`) — **keep any version
  another formula still depends on** (`brew uses --installed`).
- brew `go` → mise; afterward rebuild go-installed dev tools (`dlv`, `gopls`,
  `staticcheck`, …) under mise's go via `go install …@latest`.

**Dedupe (do NOT prune):** when a tool exists both as a managed package and a stray
direct-download `.app`, adopt the package and remove only the duplicate.

---

## 4. Loose ends

- **`backups/`** — `link.sh` saved the machine's prior `~/.zshrc`, editor settings,
  etc. there. Diff against the repo versions and salvage anything machine-relevant
  before deleting the backups.
- **Stray `*.symlink` leftovers** in the repo working tree from an old clone — safe
  to delete once you've confirmed their content is captured in the modern files.
- **`claude`** self-updates, or nudge with `claude update`.

---

## 5. Report back

Summarize for Jared: what was pruned, what was kept and why, the contents of
`~/Desktop/$MACHINE-globals.txt` (so anything important is re-homed reproducibly),
and any reverse-dependency surprises.

> **Don't trust per-file `brew bundle cleanup` as a "zero-drift" check.** It
> compares against ONE Brewfile, so it flags every *other* profile's packages (and
> all untracked real apps) as removable. Use `brew leaves` + "`brew bundle --file
> core`/`--file <profile>` report satisfied" instead.
