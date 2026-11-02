#!/bin/bash
# Assemble a launchable Pressoir.app bundle from the SwiftPM PressoirApp
# product and ad-hoc code-sign it.
#
# Usage: Scripts/build-app.sh [debug|release] [native]
#   Defaults to a release build as a universal binary (arm64 + x86_64), so the
#   same bundle runs on Apple Silicon and Intel. Pass `native` for a
#   single-architecture build while iterating — it is noticeably faster.
set -euo pipefail

CONFIG="${1:-release}"
SLICE="${2:-universal}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "$SLICE" = "universal" ]; then
  ARCHS=(--arch arm64 --arch x86_64)
  echo "› Building PressoirApp ($CONFIG, universal arm64 + x86_64)…"
else
  # bash 3.2 (macOS default) treats an empty array as unset under `set -u`, so
  # the expansion below is guarded rather than the array left bare.
  ARCHS=()
  echo "› Building PressoirApp ($CONFIG, native only)…"
fi

# The binary must not carry the builder's home folder (it names the macOS
# account): source paths are rewritten to "." and debug symbols stripped below.
PREFIX_MAP=(-Xswiftc -file-prefix-map -Xswiftc "$ROOT=.")
swift build -c "$CONFIG" ${ARCHS[@]+"${ARCHS[@]}"} "${PREFIX_MAP[@]}" --product PressoirApp
BINDIR="$(swift build -c "$CONFIG" ${ARCHS[@]+"${ARCHS[@]}"} "${PREFIX_MAP[@]}" --product PressoirApp --show-bin-path)"

APP="$ROOT/Pressoir.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINDIR/PressoirApp" "$APP/Contents/MacOS/Pressoir"
# -S drops the debug map, whose entries hold the absolute object file paths.
strip -S "$APP/Contents/MacOS/Pressoir"
if LC_ALL=C grep -aq "$HOME" "$APP/Contents/MacOS/Pressoir"; then
  echo "✗ The binary still contains $HOME" >&2
  exit 1
fi
[ -f "$ROOT/Resources/AppIcon.icns" ] && cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Pressoir</string>
    <key>CFBundleDisplayName</key><string>Pressoir</string>
    <key>CFBundleIdentifier</key><string>io.github.toowame.Pressoir</string>
    <key>CFBundleExecutable</key><string>Pressoir</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.2.1</string>
    <key>CFBundleVersion</key><string>3</string>
    <key>CFBundleDevelopmentRegion</key><string>fr</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

echo "› Ad-hoc signing…"
# Hardened runtime: no injected libraries, no debugger attach, no unsigned code.
codesign --force --deep --options runtime --sign - "$APP"
codesign --verify --verbose=2 "$APP" 2>&1 | sed 's/^/  /'

# State the slices explicitly: a bundle that silently lost its x86_64 half
# still launches fine here and fails only on an Intel Mac.
echo "› Architectures: $(lipo -archs "$APP/Contents/MacOS/Pressoir")"
echo "✓ Built $APP"
