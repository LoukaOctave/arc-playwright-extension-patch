#!/bin/sh
# Download the Playwright Extension from the Chrome Web Store, patch it for Arc,
# and install the browser launcher.
set -eu

EXT_ID=mmlmfjhmonkocbjadbfplnigmagldckm
EXT_DIR="$HOME/.local/share/playwright-extension-arc"
BIN_DIR="$HOME/.local/bin"
REPO_DIR=$(cd "$(dirname "$0")" && pwd)
CRX_URL="https://clients2.google.com/service/update2/crx?response=redirect&prodversion=140.0&acceptformat=crx2,crx3&x=id%3D${EXT_ID}%26uc"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/ext.crx" "$CRX_URL"
# A CRX is a zip with a signed header in front; unzip warns about the header and exits 1.
unzip -qo "$work/ext.crx" -d "$work/ext" || [ -f "$work/ext/manifest.json" ]
[ -f "$work/ext/lib/background.mjs" ] || { echo "Unexpected extension layout: lib/background.mjs missing" >&2; exit 1; }

# Arc refuses to load an unpacked extension that contains _metadata.
rm -rf "$work/ext/_metadata"
cat "$REPO_DIR/arc-shim.js" "$work/ext/lib/background.mjs" > "$work/background.mjs"
mv "$work/background.mjs" "$work/ext/lib/background.mjs"

rm -rf "$EXT_DIR"
mkdir -p "$(dirname "$EXT_DIR")" "$BIN_DIR"
mv "$work/ext" "$EXT_DIR"
ln -sf "$REPO_DIR/arc-open-url" "$BIN_DIR/arc-open-url"

echo "Installed Playwright Extension $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$EXT_DIR/manifest.json") to $EXT_DIR"
echo "Reload it in arc://extensions, then reconnect the playwright MCP server."
