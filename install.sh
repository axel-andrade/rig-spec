#!/usr/bin/env bash
# rig-spec installer
# Installs the rig-spec command to ~/.local/bin/
# Usage: curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
set -e

REPO="https://github.com/axel-andrade/rig-spec"
RAW="https://raw.githubusercontent.com/axel-andrade/rig-spec/main"
INSTALL_DIR="${HOME}/.local/bin"
CMD_NAME="rig-spec"

# ─────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}rig-spec installer${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
}

print_step() { echo -e "${BOLD}→ $1${RESET}"; }
print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
print_err()  { echo -e "  ${RED}✗${RESET} $1"; }

# ─────────────────────────────────────────────
# Checks
# ─────────────────────────────────────────────

check_dependencies() {
  print_step "Checking dependencies..."
  local missing=0

  if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
    print_err "curl or wget is required but neither was found"
    missing=1
  else
    print_ok "curl/wget found"
  fi

  if ! command -v git &>/dev/null; then
    print_warn "git not found — some features may not work"
  else
    print_ok "git found"
  fi

  if [ "$missing" -eq 1 ]; then
    echo ""
    echo "Please install missing dependencies and try again."
    exit 1
  fi
}

# ─────────────────────────────────────────────
# Download
# ─────────────────────────────────────────────

download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  else
    wget -qO "$dest" "$url"
  fi
}

# ─────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────

install_cli() {
  print_step "Installing rig-spec CLI..."

  mkdir -p "$INSTALL_DIR"

  local dest="$INSTALL_DIR/$CMD_NAME"
  download_file "$RAW/rig-spec.sh" "$dest"
  chmod +x "$dest"

  print_ok "Installed to $dest"
}

# ─────────────────────────────────────────────
# PATH setup
# ─────────────────────────────────────────────

setup_path() {
  if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    return 0
  fi

  print_step "Adding $INSTALL_DIR to PATH..."

  local shell_rc=""
  if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    shell_rc="$HOME/.zshrc"
  elif [ -n "$BASH_VERSION" ] || [ "$(basename "$SHELL")" = "bash" ]; then
    shell_rc="$HOME/.bashrc"
    [ -f "$HOME/.bash_profile" ] && shell_rc="$HOME/.bash_profile"
  fi

  if [ -n "$shell_rc" ]; then
    echo "" >> "$shell_rc"
    echo "# rig-spec" >> "$shell_rc"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_rc"
    print_ok "Added to $shell_rc"
    export PATH="$HOME/.local/bin:$PATH"
  else
    print_warn "Could not detect shell config — add manually:"
    print_warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
}

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

print_summary() {
  echo ""
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo -e "${GREEN}${BOLD}rig-spec installed successfully${RESET}"
  echo -e "${CYAN}──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${BOLD}Command:${RESET} rig-spec"
  echo -e "  ${BOLD}Location:${RESET} $INSTALL_DIR/$CMD_NAME"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo ""
  echo "  1. Reload your shell (or open a new terminal):"
  echo "     source ~/.bashrc   (or ~/.zshrc)"
  echo ""
  echo "  2. Go to any project and initialize the harness:"
  echo "     cd your-project"
  echo "     rig-spec init"
  echo ""
  echo "  3. For an existing project:"
  echo "     rig-spec init --retrofit"
  echo ""
  echo -e "  ${BOLD}Help:${RESET} rig-spec help"
  echo -e "  ${BOLD}Docs:${RESET} $REPO"
  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
  print_header
  check_dependencies
  install_cli
  setup_path
  print_summary
}

main
