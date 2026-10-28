#!/usr/bin/env bash
# Builds the bundle, replaces /Applications/SvátekTracker.app with it, and
# (re)launches it. Settings and tracked names live in UserDefaults, so they
# survive the swap.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/bundle.sh

TARGET="/Applications/SvátekTracker.app"
# Quit the running copy first so the new one takes over the menu bar item.
pkill -x SvatekTracker || true
while pgrep -x SvatekTracker >/dev/null; do sleep 0.2; done

rm -rf "$TARGET"
ditto "dist/SvátekTracker.app" "$TARGET"
open "$TARGET"
echo "installed and launched $TARGET"
