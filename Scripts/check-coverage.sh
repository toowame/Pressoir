#!/bin/bash
# Fails when line coverage of the PressoirCore domain drops below the threshold.
# The app target (AppKit glue) is exercised by hand, see docs/TESTING.md.
set -euo pipefail

THRESHOLD="${1:-80}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift test --enable-code-coverage >/dev/null
PROFILE="$(swift test --show-codecov-path | sed 's/\.json$/.profdata/;s#/codecov/[^/]*$#/codecov/default.profdata#')"
BIN_DIR="$(swift build --show-bin-path)"
TEST_BIN="$(find "$BIN_DIR" -path '*Tests.xctest/Contents/MacOS/*' -type f | head -1)"

REPORT="$(xcrun llvm-cov report "$TEST_BIN" -instr-profile "$PROFILE" Sources/PressoirCore)"
echo "$REPORT"
PERCENT="$(echo "$REPORT" | awk '/^TOTAL/ {gsub("%","",$10); print $10}')"
awk -v p="$PERCENT" -v t="$THRESHOLD" 'BEGIN { exit (p + 0 >= t + 0) ? 0 : 1 }' \
  || { echo "✗ Couverture PressoirCore ${PERCENT}% < ${THRESHOLD}%"; exit 1; }
echo "✓ Couverture PressoirCore ${PERCENT}% (seuil ${THRESHOLD}%)"
