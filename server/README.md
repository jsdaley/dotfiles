# Server profile (headless Linux)

A profile for **headless, terminal-only Linux servers** — distinct from the macOS
home/work profiles. Built for quality-of-life + server administration, not
development.

**Targets:** Cerebro (Proxmox/Debian), Colossus (Ubuntu file+docker), Vulcan
(Debian + Caddy/web). Plus small boxes and throwaway experiments. Optimized for
**headless Debian** (a RedHat or Linux-desktop profile can be added later).

## Principles
- **apt-based**, not Homebrew. Debian renames some tools (`bat`→`batcat`,
  `fd`→`fdfind`) — config handles that with shims/aliases.
- **No UI tools** (no VS Code) and **no AI tools** (no Claude). These boxes may
  have a desktop, but that's not their job.
- **Codify the shared set**, not each machine's full inventory. The goal is a
  consistent, comfortable terminal + admin experience across all servers.
- Lightweight: a curated set of power-user + general + server-admin tools, since
  little time is spent interactively on each box.

## Layout
```
server/
  recon.sh        read-only audit script (run on each box; produces <host>-recon.txt)
  packages.apt    shared apt packages (modern CLI + general + admin/diagnostics)
  shell.sh        portable QoL config — sourced from ~/.bashrc AND ~/.zshrc
  setup.sh        apt install (skips unavailable) + bat/fd shims + wires shell.sh
```

## Install (per server)
Copy the `server/` folder to the box and run `setup.sh`:
```bash
scp -r ~/workspace/dotfiles/server <host>:/tmp/server
ssh <host> 'bash /tmp/server/setup.sh'
```
Idempotent — re-run any time to update. Vulcan has no passwordless sudo, so it
prompts for a password.

## Notes
- Works in **bash and zsh** (Cerebro/Colossus are zsh+oh-my-zsh; Vulcan is bash).
  It does NOT force-install zsh/oh-my-zsh/p10k — those stay as-is per machine.
- Debian renames `bat`→`batcat`, `fd`→`fdfind`; `setup.sh` symlinks them back to
  `bat`/`fd` in `~/.local/bin`.
- Aliasing is conservative vs macOS (servers are paste-heavy): only ls/cat/top/df
  are swapped; grep/find/ps stay native.
- `fastfetch` + `ncdu` (found useful here) were promoted to the macOS core profile.
- TODO (your call): slot `~/.ssh/config` in via an `Include ~/.ssh/config.local`
  template so host/IP details stay local & out of git.
