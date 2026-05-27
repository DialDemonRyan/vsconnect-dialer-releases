#!/bin/bash
# install.sh — One-shot installer for VS Connect Dialer on Apple Silicon Macs.
# Paste this in Terminal:
#   curl -fsSL https://raw.githubusercontent.com/DialDemonRyan/vsconnect-dialer-releases/main/install.sh | bash
#
# It downloads the latest .dmg, mounts it, installs to /Applications,
# strips Gatekeeper quarantine, and opens the app.

set -e

cat <<'BANNER'

🔥 VS Connect Dialer — Installer
═══════════════════════════════════════════════════════════

BANNER

# Sanity: Apple Silicon only
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  echo "✗ This installer is for Apple Silicon Macs (arm64). Yours: $ARCH"
  echo "  Download the Intel build manually from:"
  echo "  https://github.com/DialDemonRyan/vsconnect-dialer-releases/releases/latest"
  exit 1
fi

# Find the latest arm64 .dmg URL from the GitHub releases API.
echo "▸ Finding latest release…"
URL=$(curl -fsSL https://api.github.com/repos/DialDemonRyan/vsconnect-dialer-releases/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*arm64\.dmg"' \
  | head -1 \
  | sed 's/.*"browser_download_url": *"//; s/"$//')
if [ -z "$URL" ]; then
  echo "✗ Couldn't find arm64.dmg in the latest release"
  echo "  Visit https://github.com/DialDemonRyan/vsconnect-dialer-releases/releases/latest and download manually."
  exit 1
fi
echo "  → $URL"

# Download
echo "▸ Downloading…"
TMP_DMG="/tmp/vs-connect-dialer-install.dmg"
curl -L# "$URL" -o "$TMP_DMG"

# Detach any stale mount, then mount fresh
if [ -d "/Volumes/VS Connect Dialer" ]; then
  hdiutil detach "/Volumes/VS Connect Dialer" -force >/dev/null 2>&1 || true
fi
echo "▸ Mounting…"
hdiutil attach "$TMP_DMG" -nobrowse -quiet

# Remove any existing installation, then copy in fresh
if [ -d "/Applications/VS Connect Dialer.app" ]; then
  echo "▸ Removing existing install…"
  rm -rf "/Applications/VS Connect Dialer.app"
fi
echo "▸ Installing to /Applications…"
cp -R "/Volumes/VS Connect Dialer/VS Connect Dialer.app" /Applications/

# Clean up the mount + tmp file
hdiutil detach "/Volumes/VS Connect Dialer" -quiet
rm -f "$TMP_DMG"

# Strip Gatekeeper quarantine so macOS doesn't say "this app is damaged".
echo "▸ Bypassing Gatekeeper quarantine…"
xattr -cr "/Applications/VS Connect Dialer.app"

# Launch
echo
echo "✓ Installed! Opening the app…"
sleep 0.5
open "/Applications/VS Connect Dialer.app"

cat <<'AFTER'

═══════════════════════════════════════════════════════════
✓ DONE. Next steps to get fully set up:

1. SIGN UP for the two AI services (both have free credit):
   • Deepgram (live transcription)  → https://console.deepgram.com
   • Anthropic (call analysis)      → https://console.anthropic.com

2. Paste BOTH API keys into the app:
   Settings → Transcription / Analysis tabs

3. Make sure VS Connect (VanillaSoft's softphone) is installed.
   The dialer fires tel: URLs that VS Connect picks up.

═══════════════════════════════════════════════════════════
AFTER
