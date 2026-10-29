#!/usr/bin/env bash
# Downloads the pinned Sparkle release into vendor/Sparkle (gitignored).
# bundle.sh embeds Sparkle.framework into the .app; release-dmg.sh uses the
# bin/ tools (generate_appcast, generate_keys). SvátekTracker dlopen's Sparkle at
# runtime, so a plain `swift build`/CI does NOT need this — only bundling does.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=2.9.3
SHA256=74a07da821f92b79310009954c0e15f350173374a3abe39095b4fc5096916be6
URL="https://github.com/sparkle-project/Sparkle/releases/download/${VERSION}/Sparkle-${VERSION}.tar.xz"
DEST=vendor/Sparkle

# Re-fetch when the pinned version changes, not just when vendor/ is empty.
if [ "$(cat "$DEST/VERSION.txt" 2>/dev/null)" = "$VERSION" ] && [ -d "$DEST/Sparkle.framework" ]; then
  echo "Sparkle ${VERSION} already present in $DEST"
  exit 0
fi

mkdir -p vendor
TARBALL="vendor/Sparkle-${VERSION}.tar.xz"
echo "downloading Sparkle ${VERSION}…"
curl -fsSL -o "$TARBALL" "$URL"
echo "${SHA256}  ${TARBALL}" | shasum -a 256 -c -
rm -rf "$DEST"
mkdir -p "$DEST"
tar xf "$TARBALL" -C "$DEST"
echo "$VERSION" > "$DEST/VERSION.txt"
echo "Sparkle ${VERSION} extracted to $DEST"
