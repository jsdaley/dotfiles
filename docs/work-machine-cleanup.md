# Work-Machine Cleanup — Post-Install Handoff (Cyclops)

**Hand this to the Claude Code session on Jared's *work* MacBook (Cyclops).**
Self-contained — assume no prior context.

The dotfiles audit + install already ran here: the machine is now on the
modernized dotfiles (`~/.zshrc` → repo, profile = `work`, mise manages
node/python/go, native `claude` in `~/.local/bin`). The Brewfiles, VS Code
settings/extensions, and mise config were reconciled centrally by the home
session. **What remains is cleanup of drift that is NOT in the dotfiles** —
mostly uninstalls — plus a couple of safety-critical ordering steps.

> ⚠️ **Workflow rules (unchanged):** present a plan and get Jared's explicit
> "go" before uninstalling anything. **Hand all sudo / admin / GUI / App-Store /
> pkg-uninstaller steps to Jared as copy-paste commands** — do not run them
> yourself. Timestamp-backup anything you overwrite.
>
> ⛔ **Do NOT touch:** SentinelOne, Rippling (MDM/security-managed).

---

## 0. First: pull the latest dotfiles

```bash
cd ~/workspace/dotfiles && git pull
brew bundle --file brew/Brewfile.work        # installs redis-insight; azure-data-studio dropped
code --install-extension ms-mssql.mssql      # SQL Server access (Azure Data Studio successor)
```

---

## 1. SAFETY-CRITICAL ORDER — do these BEFORE removing nodenv

The home machine lost its global npm packages (incl. claude-code) by deleting
`~/.nodenv` before saving/​re-homing them. Do not repeat that here.

**1a. Save every node global to a file (recovery record):**
```bash
{ for v in $(nodenv versions --bare 2>/dev/null); do
    echo "===== nodenv $v ====="; NODENV_VERSION="$v" nodenv exec npm ls -g --depth=0 2>/dev/null
  done
  echo "===== pnpm ====="; pnpm ls -g --depth=0 2>/dev/null
} > ~/Desktop/cyclops-node-globals.txt
```
Review it with Jared. Anything worth keeping → re-home as a **brew formula** or
the tool's **own installer** (NOT an npm global — they don't survive node teardown).

**1b. Fix the `claude` PATH, then drop the npm shadow:**
```bash
which claude            # MUST be ~/.local/bin/claude (native), not a nodenv shim
claude --version
```
- If it resolves to `~/.local/bin/claude`, remove the old npm global:
  `npm rm -g @anthropic-ai/claude-code`
- If it still resolves to a nodenv shim, the relinked `zsh/path.zsh` (which puts
  `~/.local/bin` first) isn't active yet — open a fresh shell / `exec zsh` and
  recheck **before** removing anything.

**Only after 1a + 1b:** nodenv itself can be pruned (§3).

---

## 2. Tap trust / cleanup (new Homebrew tap-trust feature)

```bash
brew trust --formula common-fate/granted/granted   # we use 'granted' — trust the tap
brew untap powershell/tap                           # orphan: powershell is a core formula now
# turbot/tap provides steampipe. If Jared uses steampipe, trust it; else untap:
brew trust --formula turbot/tap/steampipe           # …OR…  brew untap turbot/tap
```

---

## 3. PRUNE LIST — drift not in the dotfiles (confirm each with Jared)

Verify reverse-deps before removing brew leaves: `brew uses --installed <name>`.

**Replaced by something already installed:**
| Remove | Because |
|--------|---------|
| Docker Desktop (app + `/usr/local/bin/docker`,`kubectl` shims) | OrbStack provides docker + kubectl. **Admin/GUI — Jared.** |
| `clipy` (cask) + `Clipy.app` | replaced by `maccy` (now in core) |
| `BloomRPC.app` (direct download) | replaced by `kreya` |
| AWS CLI official pkg (`/usr/local/bin/aws`) | replaced by `brew 'awscli'`. Use AWS's pkg uninstall steps. **Admin — Jared.** |
| `midnight-commander` (brew) | superseded by `yazi` (core) |
| `go` (brew leaf) | now via mise — verify `brew uses --installed go` first |
| Azure Data Studio (if a direct-download `.app` exists) | discontinued upstream; `ms-mssql.mssql` VS Code ext replaces it |

**No longer used:**
- `circleci` (brew leaf) — uninstall.
- `Tableau.app` (direct download) — manual uninstall. **Jared.**
- `putty` — keep ONLY if `plink`/`pscp`/serial are actually used.

**Run as containers, not on metal:**
- `postgresql@14` (brew) — uninstall; Postgres runs in Docker.
- `redis` (brew) — uninstall; Redis runs in Docker.

**Runtime migration to mise (do AFTER §1):**
- `nodenv` + `~/.nodenv` — prune only after §1a + §1b are done.
- `rbenv` (ruby 2.6.2, EOL) — mise can manage ruby; prune after migrating.
- `python@3.8`, `python@3.9` (EOL) — prune after mise; **keep 3.10/3.11 if other
  formulae depend on them** (`brew uses --installed python@3.11`).
- `openssl@1.1` (EOL) — verify `brew uses --installed openssl@1.1` first.
- Go dev tools (`dlv`, `gopls`, `staticcheck`, `go-outline`) — reinstall via
  `go install …` under mise's go after the switch (they live in GOPATH/bin).

**Dedupe (do NOT prune):**
- DBeaver — KEEP (Postico 2 is primary). A brew cask AND a stray `/Applications`
  `.app` both exist → adopt the cask, remove the duplicate app.

---

## 4. Loose ends

- **Stray `git/gitconfig.symlink`** in the repo working tree — safe to delete;
  the one setting worth keeping (`core.ignorecase = false`) is already in the
  modern `git/gitconfig`. `rm -f ~/workspace/dotfiles/git/gitconfig.symlink`.
- **VS Code** settings/keybindings/extensions are already reconciled centrally
  (this pull includes `ms-mssql.mssql`). No action beyond the `code --install`
  in §0. (Harmless leftover: `pascal.formatter.enginePath` is a home/Pascal path
  that won't exist here — ignore.)
- **`claude`** is 2.1.x; it self-updates, or `claude update`.

---

## 5. Report back

When done, summarize for Jared: what was pruned, what was kept and why, the
contents of `~/Desktop/cyclops-node-globals.txt` (so anything important gets
re-homed reproducibly), and any reverse-dependency surprises from
`brew uses --installed`.
