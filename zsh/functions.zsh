# zsh/functions.zsh — shell functions

# ── Local LLM stack (Ollama + Open WebUI), carried over from old .zshrc ──────
llm-start() {
  echo "Starting Ollama..."
  OLLAMA_FLASH_ATTENTION=1 open -a Ollama
  sleep 3
  echo "Starting Open WebUI..."
  docker start open-webui
  echo "Done. Open http://localhost:3000"
}

llm-stop() {
  echo "Stopping Open WebUI..."
  docker stop open-webui
  echo "Stopping Ollama..."
  pkill -x "Ollama"
  echo "LLM stack stopped."
}

# ── mkcd: make a directory and cd into it ────────────────────────────────────
mkcd() { mkdir -p "$1" && builtin cd "$1"; }

# ── extract: unpack most archive types ───────────────────────────────────────
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2|*.tbz2) tar xjf "$1" ;;
      *.tar.gz|*.tgz)   tar xzf "$1" ;;
      *.tar.xz)         tar xJf "$1" ;;
      *.tar)            tar xf  "$1" ;;
      *.zip)            unzip "$1" ;;
      *.7z)             7z x "$1" ;;
      *.gz)             gunzip "$1" ;;
      *.bz2)            bunzip2 "$1" ;;
      *)                echo "extract: don't know how to handle '$1'" ;;
    esac
  else
    echo "extract: '$1' is not a file"
  fi
}
