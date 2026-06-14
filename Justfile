# Justfile — one entry point for managing these dotfiles across machines.
# `just` (no args) lists recipes. Cross-platform (macOS + Linux servers).

# List available recipes
default:
    @just --list

# Symlink everything per links.conf (OS-aware, idempotent)
link:
    bash link.sh

# Install / sync packages for the active macOS profile
install:
    brew/install.sh

# Pull latest and apply everywhere it's cheap (links + packages + runtimes)
update:
    git pull --ff-only
    bash link.sh
    -brew/install.sh
    -mise install

# Scan THIS repo for committed/staged secrets (trufflehog + gitleaks)
secrets:
    -gitleaks detect --no-banner
    -trufflehog git file://. --only-verified --no-update

# Provision one Linux server: rsync this repo + run its setup
server host:
    rsync -a --exclude='.git' --exclude='backups/' ./ {{host}}:~/dotfiles/
    ssh -t {{host}} 'bash ~/dotfiles/server/setup.sh'

# Provision all servers listed in ~/.config/dotfiles/servers (one host per line)
servers:
    @f="${DOTFILES_SERVERS:-$HOME/.config/dotfiles/servers}"; \
     [ -f "$f" ] || { echo "create $f (one ssh host per line)"; exit 1; }; \
     while read -r h; do [ -n "$h" ] && just server "$h"; done < "$f"

# Audit Homebrew: anything installed but not in the Brewfiles
brew-orphans:
    brew bundle cleanup --file brew/Brewfile.core
