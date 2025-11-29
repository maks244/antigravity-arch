# Google Antigravity - Arch Linux Package (Direct from Google)

Arch Linux package that downloads **directly from Google's official apt repository**.

## Why this exists

Other Arch packages pull from third-party repos, adding supply chain risk. Even this repo could be compromised - so the PKGBUILD is never committed. It's generated fresh from Google's servers every time you install.

## How it works

1. `update.sh` fetches Google's apt repo `Packages` manifest
2. Parses all available versions and selects the latest
3. Extracts the download URL and SHA256 checksum
4. Generates a fresh `PKGBUILD` locally (never committed to this repo)
5. `install.sh` compares your installed version vs available and prompts before proceeding
6. `makepkg` downloads the `.deb` directly from Google and verifies the checksum
7. The generated `PKGBUILD` extracts the `.deb`, sets SUID on chrome-sandbox for sandboxing, and creates launcher scripts
8. `pacman` installs the built package to your system

## Install

```bash
git clone https://github.com/maks244/antigravity-arch.git
cd antigravity-arch
./install.sh
```

Or manually:

```bash
./update.sh    # Generate PKGBUILD from Google's repo
makepkg -si    # Build and install
```

## Update

```bash
cd antigravity-arch
./install.sh
```

## License

The packaging scripts are public domain. Google Antigravity itself is proprietary software by Google.
