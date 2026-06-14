# zsh/nudges.zsh — steer muscle memory toward the modern tools.
#
# Two kinds of nudges:
#   1. Retired tools (uninstalled): a function shadows the old name and points
#      you at the replacement instead of a bare "command not found".
#   2. Still-installed legacy tools we want to stop using: same idea, but you can
#      bypass with `command <name>` if you really need the original.
#
# (The day-to-day swaps — ls→eza, cat→bat, grep→rg, find→fd, du→dust, df→duf,
#  ps→procs, top→btop, cd→zoxide, dig→doggo — live in aliases.zsh / tools.zsh.)

_nudge() {  # _nudge <old> <replacement> <hint>
  print -u2 -P "%F{yellow}↪ '$1' is retired here — use %B$2%b.%f ${3:+($3) }(force: command $1)"
  return 127
}

# Runtime managers → mise
nodenv()     { _nudge nodenv     "mise"  "mise use -g node@22"; }
node-build() { _nudge node-build "mise"; }
nvm()        { _nudge nvm        "mise"  "mise use node@…"; }
pyenv()      { _nudge pyenv      "mise"  "mise use -g python@3.11"; }

# File manager → yazi
mc()         { _nudge mc         "yazi (y)"; }
ranger()     { _nudge ranger     "yazi (y)"; }

# Search / find → ripgrep / fd  (these are also aliased, this catches the *grep family)
ack()        { _nudge ack        "rg"; }
egrep()      { _nudge egrep      "rg"  "or \\grep -E"; }
fgrep()      { _nudge fgrep      "rg"  "or \\grep -F"; }

# Editors you've moved off of (nano/micro are your CLI editors; vim stays available)
# (intentionally NOT shadowing vim/nano — kept as real fallbacks)
