#!/bin/bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_NAME="antigravity-bin"

log() { echo "[INFO] $1"; }

get_installed_version() {
    if pacman -Q "$PKG_NAME" &>/dev/null; then
        pacman -Q "$PKG_NAME" | awk '{print $2}'
    fi
}

log "Updating package info from Google's apt repo..."
"$SCRIPT_DIR/update.sh"

# Get versions
INSTALLED=$(get_installed_version)
AVAILABLE=$(grep "^pkgver=" "$SCRIPT_DIR/PKGBUILD" | cut -d= -f2)-$(grep "^pkgrel=" "$SCRIPT_DIR/PKGBUILD" | cut -d= -f2)

if [ -n "$INSTALLED" ]; then
    log "Installed: $INSTALLED"
    log "Available: $AVAILABLE"

    if [ "$INSTALLED" = "$AVAILABLE" ]; then
        printf "Already up-to-date. Reinstall anyway? (y/N): "
        read -r choice </dev/tty
        [[ ! "$choice" =~ ^[Yy]$ ]] && { log "Skipping."; exit 0; }
    else
        printf "Update to $AVAILABLE? (Y/n): "
        read -r choice </dev/tty
        [[ "$choice" =~ ^[Nn]$ ]] && { log "Skipping."; exit 0; }
    fi
else
    log "Not installed. Available: $AVAILABLE"
    printf "Install? (Y/n): "
    read -r choice </dev/tty
    [[ "$choice" =~ ^[Nn]$ ]] && { log "Skipping."; exit 0; }
fi

log "Building and installing..."
cd "$SCRIPT_DIR"
makepkg -si --needed
