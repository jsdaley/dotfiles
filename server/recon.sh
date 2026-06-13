#!/usr/bin/env bash
# server/recon.sh — READ-ONLY audit of a Linux server for the dotfiles "server"
# profile. Installs nothing, changes nothing. Writes a report to:
#     ./<hostname>-recon.txt   (send that file back)
#
# Run on each server:   bash recon.sh
set +e
OUT="$(hostname)-recon.txt"

{
sec(){ printf '\n===== %s =====\n' "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }

sec "META";            date; echo "host: $(hostname)"; echo "user: $(whoami) (uid $(id -u))"; echo "login shell: $SHELL"; id
sec "OS / KERNEL";     cat /etc/os-release 2>/dev/null; uname -a; echo "arch: $(uname -m)"
                       [ -f /etc/debian_version ] && echo "debian_version: $(cat /etc/debian_version)"
                       have pveversion && { echo "--- PROXMOX ---"; pveversion; }
sec "ROLE / VIRT";     have systemd-detect-virt && echo "virt: $(systemd-detect-virt 2>/dev/null)"
                       have docker && { echo "docker: $(docker --version)"; echo "containers:"; docker ps --format '  {{.Names}} ({{.Image}})' 2>/dev/null; }
                       have qm  && echo "Proxmox VMs (qm) present"
                       have pct && echo "Proxmox CTs (pct) present"
                       have caddy && echo "caddy: $(caddy version 2>/dev/null)"
                       have nginx && echo "nginx present"
sec "SHELLS";          cat /etc/shells 2>/dev/null; for s in bash zsh fish; do have $s && echo "$s: $($s --version 2>/dev/null|head -1)"; done
                       [ -d ~/.oh-my-zsh ] && echo "oh-my-zsh: yes"; have starship && echo "starship: yes"
sec "PKG MANAGERS";    for p in apt dpkg snap flatpak brew nala; do have $p && echo "$p: yes"; done
                       have snap && { echo "snaps:"; snap list 2>/dev/null|awk 'NR>1{print "  "$1}'; }
                       have brew && echo "linuxbrew prefix: $(brew --prefix 2>/dev/null)"

sec "MANUALLY-INSTALLED APT PACKAGES (primary signal)"
                       apt-mark showmanual 2>/dev/null | sort | tr '\n' ' '; echo

sec "MODERN CLI TOOLS — presence + binary name (Debian renames bat->batcat, fd->fdfind)"
for t in eza exa lsd bat batcat fd fdfind rg ripgrep fzf zoxide delta git-delta difft duf dust ncdu procs btop htop glances tree tmux screen jq yq gh lazygit lazydocker ctop dive tldr tealdeer mtr doggo xh httpie sd direnv mise micro nano neovim vim ranger; do
  have "$t" && echo "  $t -> $(command -v "$t")  [$("$t" --version 2>/dev/null|head -1)]"
done

sec "APT AVAILABILITY of candidate tools (what we can apt-install here)"
for t in eza bat fd-find ripgrep fzf zoxide git-delta duf ncdu procs btop jq yq tmux micro tldr mtr tree htop ncdu rsync; do
  v=$(apt-cache policy "$t" 2>/dev/null | awk '/Candidate:/{print $2}')
  [ -n "$v" ] && [ "$v" != "(none)" ] && echo "  $t: $v"
done

sec "SERVER / ADMIN TOOLING present"
for t in docker docker-compose caddy nginx ufw fail2ban iptables nft ss lsof rsync rclone borg restic duplicity zfs btrfs smartctl sensors iotop iftop nethogs vnstat bmon tcpdump nmap ncat socat ansible cron systemctl journalctl logrotate unattended-upgrade needrestart; do
  have "$t" && echo "  $t"
done

sec "EXISTING DOTFILES (line counts)"
for f in ~/.bashrc ~/.bash_aliases ~/.profile ~/.bash_profile ~/.zshrc ~/.zprofile ~/.p10k.zsh ~/.tmux.conf ~/.vimrc ~/.nanorc ~/.inputrc ~/.gitconfig ~/.gitexcludes ~/.ssh/config ~/.config/htop/htoprc; do
  [ -e "$f" ] && echo "  $f ($(wc -l <"$f" 2>/dev/null) lines)"
done

sec "~/.bashrc (to see existing aliases/QoL)";  cat ~/.bashrc 2>/dev/null
sec "~/.bash_aliases";                          cat ~/.bash_aliases 2>/dev/null
sec "~/.profile";                               cat ~/.profile 2>/dev/null
sec "PS1 / PROMPT";                             echo "PS1=$PS1"

sec "SUDO";            sudo -n true 2>/dev/null && echo "passwordless sudo: YES" || echo "passwordless sudo: no (needs password)"
sec "FULL dpkg LIST (reference; large)"
                       echo "count: $(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)"
                       dpkg-query -f '${binary:Package}\t${Version}\n' -W 2>/dev/null | sort

sec "END"
} > "$OUT" 2>&1

echo "Done. Wrote: $OUT"
echo "Send that file back. (Run on Cerebro, Colossus, and Vulcan.)"
