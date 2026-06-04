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

echo "▸ Generating branded background…"
python3 scripts/make_dmg_background.py

echo "▸ Staging app…"
rm -rf build/dmgsrc && mkdir -p build/dmgsrc
cp -R "$APP" build/dmgsrc/

echo "▸ Assembling DMG…"
hdiutil detach "/Volumes/RapidClicker" 2>/dev/null || true
rm -f RapidClicker.dmg
create-dmg \
  --volname "RapidClicker" \
  --background "build/dmgassets/background.png" \
  --window-pos 200 120 \
  --window-size 640 420 \
  --icon-size 128 \
  --icon "RapidClicker.app" 180 220 \
  --app-drop-link 460 220 \
  --hide-extension "RapidClicker.app" \
  --no-internet-enable \
  "RapidClicker.dmg" \
  "build/dmgsrc/"

echo "✓ RapidClicker.dmg ready — upload with:"
echo "    gh release upload <tag> RapidClicker.dmg --clobber"
