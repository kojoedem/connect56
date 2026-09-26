#!/usr/bin/env bash
# ==============================================================================
# CONNECT56 Setup Script
# Installer for required dependencies and man page
# ==============================================================================

set -euo pipefail

echo "=================================================="
echo "          CONNECT56 Dependency Installer         "
echo "=================================================="

# Function to check command presence
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Determine package manager and install packages
install_packages() {
    echo "[*] Detecting package manager..."

    if has_cmd apt-get || has_cmd apt; then
        echo "[+] Debian/Ubuntu detected."
        SUDO=""
        if [[ $EUID -ne 0 ]]; then
            SUDO="sudo"
        fi
        $SUDO apt-get update -y
        $SUDO apt-get install -y curl jq whois dnsutils man-db
    elif has_cmd dnf; then
        echo "[+] Fedora/RHEL detected."
        SUDO=""
        if [[ $EUID -ne 0 ]]; then
            SUDO="sudo"
        fi
        $SUDO dnf install -y curl jq whois bind-utils man-db
    elif has_cmd yum; then
        echo "[+] CentOS/RHEL detected."
        SUDO=""
        if [[ $EUID -ne 0 ]]; then
            SUDO="sudo"
        fi
        $SUDO yum install -y curl jq whois bind-utils man-db
    elif has_cmd pacman; then
        echo "[+] Arch Linux detected."
        SUDO=""
        if [[ $EUID -ne 0 ]]; then
            SUDO="sudo"
        fi
        $SUDO pacman -Sy --noconfirm curl jq whois bind-tools man-db
    elif has_cmd brew; then
        echo "[+] macOS / Homebrew detected."
        brew install curl jq whois bind
    else
        echo "[-] Warning: No supported package manager found. Please manually install: curl, jq, whois, dig/nslookup."
    fi
}

install_manpage() {
    echo "[*] Installing manual page (man connect56)..."
    local MAN_DIR="/usr/local/share/man/man1"

    if [[ -f "connect56.1" ]]; then
        SUDO=""
        if [[ $EUID -ne 0 ]] && has_cmd sudo; then
            SUDO="sudo"
        fi
        $SUDO mkdir -p "$MAN_DIR"
        $SUDO cp connect56.1 "$MAN_DIR/connect56.1"
        $SUDO chmod 644 "$MAN_DIR/connect56.1"
        if has_cmd mandb; then
            $SUDO mandb >/dev/null 2>&1 || true
        fi
        echo "[+] Man page installed successfully. You can now run: man connect56"
    else
        echo "[-] Warning: connect56.1 not found in current directory."
    fi
}

install_packages
install_manpage

echo
echo "[+] Setup completed successfully!"
echo "    Run './connect56.sh --help' or 'man connect56' to get started."
