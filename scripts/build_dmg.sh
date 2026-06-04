#!/usr/bin/env bash
#
# Build a distributable, ad-hoc-signed RapidClicker.dmg with a branded
# background and drag-to-Applications layout.
#
# Requirements:
#   - Xcode
#   - create-dmg        (brew install create-dmg)
#   - python3 + Pillow  (python3 -m pip install Pillow)
#
# Usage: ./scripts/build_dmg.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="build/release"
APP="$DERIVED/Build/Products/Release/RapidClicker.app"

echo "▸ Building Release (ad-hoc signed so it runs on any Mac)…"
xcodebuild -project RapidClicker.xcodeproj -scheme RapidClicker -configuration Release \
  -destination 'platform=macOS' -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual PROVISIONING_PROFILE_SPECIFIER="" \
  DEVELOPMENT_TEAM="" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES build >/dev/null

echo "▸ Generating branded background (1x + 2x)…"
python3 scripts/make_dmg_background.py

echo "▸ Combining into a HiDPI .tiff (crisp on Retina)…"
tiffutil -cathidpicheck build/dmgassets/background.png build/dmgassets/background@2x.png \
  -out build/dmgassets/background.tiff

echo "▸ Staging app…"
rm -rf build/dmgsrc && mkdir -p build/dmgsrc
cp -R "$APP" build/dmgsrc/

echo "▸ Assembling DMG…"
hdiutil detach "/Volumes/RapidClicker" 2>/dev/null || true
rm -f RapidClicker.dmg
create-dmg \
  --volname "RapidClicker" \
  --background "build/dmgassets/background.tiff" \
  --window-pos 200 120 \
  --window-size 680 446 \
  --icon-size 120 \
  --icon "RapidClicker.app" 192 252 \
  --app-drop-link 488 252 \
  --hide-extension "RapidClicker.app" \
  --no-internet-enable \
  "RapidClicker.dmg" \
  "build/dmgsrc/"

echo "✓ RapidClicker.dmg ready — upload with:"
echo "    gh release upload <tag> RapidClicker.dmg --clobber"
