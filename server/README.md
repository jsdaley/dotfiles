# Server profile (headless Linux)

A profile for **headless, terminal-only Linux servers**, set up to be **as
identical as possible to the macOS environment**: same zsh + oh-my-zsh +
Powerlevel10k, the same `zshrc`/aliases/p10k, plus server-admin quality-of-life.

**Targets:** Cerebro (Proxmox/Debian 13), Colossus (Ubuntu 24.04 file+docker),
Vulcan (Debian 13 + Caddy). Plus small boxes and throwaway experiments.

## Principles
- **Same config as the Mac.** Servers symlink the very same `zsh/zshrc.symlink`,
  modules, and `zsh/p10k.zsh.symlink`. The Mac config is guarded so Mac-only bits
  (brew, mise, atuin…) simply no-op on Linux. Profile = `server` adds admin extras
  via `zsh/profile.server.zsh`.
- **apt-based**, not Homebrew. Debian renames `bat`→`batcat`, `fd`→`fdfind`;
  `setup.sh` symlinks them back in `~/.local/bin`.
- **No UI/AI tools** (no VS Code, no Claude). Power-user + general + admin tooling.
- **Codify the shared set**, not each box's full inventory.

## Files
```
server/
  recon.sh        read-only audit (run on a new box → <host>-recon.txt)
  packages.apt    shared apt packages (modern CLI + general + admin/diagnostics)
  setup.sh        apt install + zsh/oh-my-zsh/p10k/plugins + symlink shared dotfiles + chsh
```
zsh server extras live in `../zsh/profile.server.zsh`; the prompt is `../zsh/p10k.zsh.symlink`.

## Install (per server)
Copy the **whole repo** to the box (servers reuse the Mac's zsh modules + p10k),
then run `setup.sh`:
```bash
rsync -a ~/workspace/dotfiles/ <host>:~/dotfiles/
ssh -t <host> 'bash ~/dotfiles/server/setup.sh'
```
Idempotent — re-run (or `rsync` again) to update. `setup.sh` uses sudo
(installs packages, `chsh` to zsh); Vulcan will prompt for a password.
After it finishes, re-login or `exec zsh`.

> p10k icons render using **your terminal's** font, so over SSH from iTerm (which
> has MesloLGS NF) the prompt looks identical to local.

## Notes
- Sets zsh as the login shell on each box (Vulcan was bash only because it hadn't
  been provisioned yet).
- `fastfetch` + `ncdu` were promoted to the macOS core profile.
- SSH: a shared `~/.ssh/config` (cipher hardening + sane defaults) is symlinked;
  host-specific/sensitive entries live in `~/.ssh/config.local` (gitignored).
