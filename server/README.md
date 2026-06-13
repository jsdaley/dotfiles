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

## Layout (filled in after recon)
```
server/
  recon.sh        read-only audit script (run on each box; produces <host>-recon.txt)
  packages.apt    shared apt packages (the common, agreed set)        [TODO]
  setup.sh        apt install + dotfile linking + shell QoL            [TODO]
  shell.sh        portable shell config (aliases/prompt) sourced by ~/.bashrc/.zshrc  [TODO]
```

## Workflow
1. Run `recon.sh` on each server; send back the `<host>-recon.txt` files.
2. We diff them, agree on the shared toolset, and promote any broadly-useful
   tools into the macOS core profile too.
3. Build `packages.apt` + `setup.sh` + `shell.sh`; install via a one-liner.
