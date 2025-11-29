#!/bin/bash
set -eo pipefail

# Fetches the latest Google Antigravity package info directly from Google's apt repo
# and generates a fresh PKGBUILD with correct version, URL, and checksum.

REPO_BASE="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
PACKAGES_URL="$REPO_BASE/dists/antigravity-debian/main/binary-amd64/Packages"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGBUILD_FILE="$SCRIPT_DIR/PKGBUILD"

log() { echo "[INFO] $1"; }
error_exit() { echo "[ERROR] $1" >&2; exit 1; }

log "Fetching package metadata from Google's apt repo..."

PACKAGES_DATA=$(curl -fsSL "$PACKAGES_URL") || error_exit "Failed to fetch Packages file from $PACKAGES_URL"

# Apt Packages file contains multiple versions - we need to find the latest
# Parse into records and find the one with highest version
LATEST_RECORD=$(echo "$PACKAGES_DATA" | awk '
    BEGIN { RS=""; FS="\n" }
    {
        version = ""; filename = ""; sha256 = ""
        for (i=1; i<=NF; i++) {
            if ($i ~ /^Version:/) { split($i, a, " "); version = a[2] }
            if ($i ~ /^Filename:/) { split($i, a, " "); filename = a[2] }
            if ($i ~ /^SHA256:/) { split($i, a, " "); sha256 = a[2] }
        }
        if (version != "") {
            print version "\t" filename "\t" sha256
        }
    }
' | sort -V -t$'\t' -k1 | tail -1)

VERSION=$(echo "$LATEST_RECORD" | cut -f1)
FILENAME=$(echo "$LATEST_RECORD" | cut -f2)
SHA256=$(echo "$LATEST_RECORD" | cut -f3)

[ -z "$FILENAME" ] && error_exit "Could not parse Filename from Packages"
[ -z "$SHA256" ] && error_exit "Could not parse SHA256 from Packages"
[ -z "$VERSION" ] && error_exit "Could not parse Version from Packages"

# Convert debian version (1.11.9-1764120415) to Arch format
PKGVER=$(echo "$VERSION" | cut -d'-' -f1)
PKGREL=$(echo "$VERSION" | cut -d'-' -f2)

DEB_URL="$REPO_BASE/$FILENAME"

log "Found version: $PKGVER-$PKGREL"
log "URL: $DEB_URL"
log "SHA256: $SHA256"

log "Generating PKGBUILD..."

cat > "$PKGBUILD_FILE" << EOF
pkgname=antigravity-bin
pkgver=$PKGVER
pkgrel=$PKGREL
arch=('x86_64')
url="https://antigravity.google/"
pkgdesc="Google Antigravity IDE - AI-powered development platform (official binary)"
license=('custom')
depends=(
    'alsa-lib'
    'dbus'
    'gnupg'
    'gtk3'
    'libnotify'
    'libsecret'
    'libxkbfile'
    'libxss'
    'nss'
    'xdg-utils'
    'ripgrep'
    'fd'
)
makedepends=('tar')
options=('!strip')
provides=('antigravity' 'google-antigravity' 'google-antigravity-bin')
conflicts=('antigravity' 'google-antigravity' 'google-antigravity-bin')

source=("\${pkgname}-\${pkgver}.deb::$DEB_URL")
sha256sums=('$SHA256')

build() {
    tar -xf data.tar.xz

    mkdir -p usr/share/metainfo
    if [ -d usr/share/appdata ]; then
        mv usr/share/appdata/* usr/share/metainfo/ 2>/dev/null || true
        rmdir usr/share/appdata 2>/dev/null || true
    fi

    chmod 4755 usr/share/antigravity/chrome-sandbox

    cat > antigravity.sh << 'LAUNCHER'
#!/bin/bash
exec /usr/share/antigravity/antigravity "\$@"
LAUNCHER
}

package() {
    cp -r --reflink=auto usr "\${pkgdir}/usr"
    install -Dm755 antigravity.sh "\${pkgdir}/usr/bin/antigravity"
    ln -s /usr/bin/antigravity "\${pkgdir}/usr/bin/google-antigravity"
}
EOF

log "PKGBUILD generated successfully!"
log ""
log "To build and install:"
log "  makepkg -si"
