#!/usr/bin/env bash
# Regenerates site/og.png (the social-share card) from site/og-image.html using
# headless Chrome, so the preview matches the page (system fonts, gradients)
# 1:1. Run after editing og-image.html; commit the resulting og.png.
#
# Output is 2400x1260 (the 1200x630 OG canvas at 2x for retina previews).
# Override the browser with $CHROME if Chrome lives elsewhere.
set -euo pipefail
cd "$(dirname "$0")/.."

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
if [ ! -x "$CHROME" ]; then
  echo "error: Chrome not found at: $CHROME (override with \$CHROME)" >&2
  exit 1
fi

"$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-sandbox \
  --force-device-scale-factor=2 --window-size=1200,630 \
  --virtual-time-budget=4000 --default-background-color=ffffffff \
  --allow-file-access-from-files \
  --screenshot="site/og.png" "file://$PWD/site/og-image.html"

echo "wrote site/og.png (2400x1260)"
