#!/bin/bash
# Regenerates Resources/AppIcon.icns and docs/images/logo.png from Scripts/make-icon.swift.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p Resources docs/images
swift Scripts/make-icon.swift "$WORK/AppIcon.iconset" docs/images/logo.png
iconutil -c icns "$WORK/AppIcon.iconset" -o Resources/AppIcon.icns
echo "✓ Resources/AppIcon.icns  ✓ docs/images/logo.png"
