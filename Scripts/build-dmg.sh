#!/bin/zsh
# Package Pressoir.app into a drag-to-install .dmg (app + Applications symlink).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="Pressoir.app"
[ -d "$APP" ] || { echo "✗ $APP not found — run Scripts/build-app.sh first"; exit 1; }

VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist" 2>/dev/null || echo "0.1.0")
DMG="Pressoir-$VER.dmg"
STAGE=$(mktemp -d)/Pressoir

echo "› Staging…"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "› Creating $DMG…"
rm -f "$DMG"
hdiutil create -volname "Pressoir $VER" -srcfolder "$STAGE" -fs HFS+ \
  -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null
rm -rf "$(dirname "$STAGE")"

echo "✓ Built $(pwd)/$DMG  ($(du -sh "$DMG" | cut -f1))"
