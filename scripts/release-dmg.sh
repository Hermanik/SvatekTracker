#!/usr/bin/env bash
# Builds a distributable DMG of SvátekTracker: Developer ID signing, hardened
# runtime, Apple notarization and stapling, an EdDSA-signed Sparkle appcast,
# then publishes it all to the update host. The result opens on any Apple
# Silicon Mac with no Gatekeeper warnings and updates itself from then on.
#
# One-time prerequisites:
#   1. A "Developer ID Application" certificate in the login keychain
#      (Xcode > Settings > Accounts > Manage Certificates > + >
#       Developer ID Application).
#   2. A stored notarytool credential profile (app-specific password):
#        xcrun notarytool store-credentials "$NOTARY_PROFILE" \
#          --apple-id <apple-id> --team-id <team-id>
#   3. The Sparkle EdDSA private key in the login keychain under the
#      "svatektracker" account (vendor/Sparkle/bin/generate_keys --account
#      svatektracker). Its public half is SUPublicEDKey in bundle.sh.
#   4. Publishing target in the environment or a gitignored .release.env —
#      this repo is public, so the host isn't committed:
#        UPDATE_HOST=user@host  UPDATE_SSH_KEY=~/.ssh/key  [UPDATE_PATH=…]
#
# Overridable via env: NOTARY_PROFILE, SIGN_ID, UPDATE_HOST, UPDATE_PATH,
# UPDATE_SSH_KEY.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .release.env ] && source .release.env

NOTARY_PROFILE="${NOTARY_PROFILE:-gittracker-notary}"
# Auto-detect the Developer ID Application identity unless one is provided.
SIGN_ID="${SIGN_ID:-$(security find-identity -v -p codesigning \
  | grep -m1 'Developer ID Application' | sed -E 's/.*"(.*)".*/\1/')}"

if [ -z "$SIGN_ID" ]; then
  echo "error: no 'Developer ID Application' identity in the login keychain." >&2
  echo "create one: Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application" >&2
  exit 1
fi

VERSION=$(cat VERSION)
APP="dist/SvátekTracker.app"
DMG="dist/SvatekTracker-${VERSION}.dmg"
# Public base URL the appcast and its DMG download links are served from.
FEED_BASE="https://updates.jsemkoder.cz/svatektracker/"

# 1. Build the .app via the shared bundler (it signs for local use; we re-sign below).
scripts/bundle.sh

# 2. Re-sign for distribution with Developer ID + hardened runtime + a secure
#    timestamp (both required for notarization). Sparkle ships its own
#    signature, so every nested Sparkle binary must be re-signed inside-out
#    first — never --deep, which corrupts the XPC service signatures.
sign() { codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$@"; }
SPV="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
# The XPC services ship sandbox/network entitlements that must survive the
# re-sign (--preserve-metadata); the other components carry none.
sign --preserve-metadata=entitlements "$SPV/XPCServices/Installer.xpc" "$SPV/XPCServices/Downloader.xpc"
sign "$SPV/Autoupdate" "$SPV/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
sign "$APP"
codesign --verify --strict --verbose=2 "$APP"

# 3. Stage a compressed DMG with an /Applications drop target.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "SvátekTracker ${VERSION}" -srcfolder "$STAGE" \
  -fs HFS+ -format UDZO -ov "$DMG"

# 4. Sign the disk image itself so the download carries a Developer ID signature.
codesign --force --timestamp --sign "$SIGN_ID" "$DMG"

# 5. Notarize and block on Apple's verdict.
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

# 6. Staple the ticket so it verifies offline.
xcrun stapler staple "$DMG"

# 7. Verify the shipped artifact: ticket stapled and Gatekeeper accepts the DMG.
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -vv "$DMG"

# 8. (Re)generate the EdDSA-signed Sparkle appcast over every DMG in dist/.
#    Signs with the private key in the login keychain's "svatektracker"
#    account (isolated per app); links get FEED_BASE.
vendor/Sparkle/bin/generate_appcast --account svatektracker \
  --download-url-prefix "$FEED_BASE" dist/

echo "built $DMG (v${VERSION}, Developer ID signed + notarized + stapled)"

# 9. Publish: rsync the appcast, every built DMG and the download page to the
#    update host (an nginx static container behind Traefik serving FEED_BASE —
#    see setup-update-host.sh), with the stable download link pointing at this
#    release. Skipped with a note when the target isn't configured.
UPDATE_PATH="${UPDATE_PATH:-/opt/svatektracker-updates}"
if [ -n "${UPDATE_HOST:-}" ] && [ -f "${UPDATE_SSH_KEY:-}" ]; then
  # Stamp the page's {{VERSION}} placeholder, then ship it with the release.
  # -p keeps mtimes so rsync skips the unchanged images.
  mkdir -p dist/site
  sed "s/{{VERSION}}/$VERSION/g" site/index.html > dist/site/index.html
  cp -p site/og.png site/icon.png site/screenshot.png dist/site/
  # The stable link travels as a symlink in the same rsync (-a keeps links).
  # It lives in dist/site/, not dist/, so generate_appcast never sees it.
  ln -sfn "SvatekTracker-${VERSION}.dmg" dist/site/SvatekTracker-latest.dmg
  # nullglob (contained in a subshell) so the delta pattern vanishes on the
  # first release, when no deltas exist yet.
  ( shopt -s nullglob
    rsync -az -e "ssh -i $UPDATE_SSH_KEY -o BatchMode=yes" \
      dist/appcast.xml dist/*.dmg dist/*.delta dist/site/ "$UPDATE_HOST:$UPDATE_PATH/" )
  echo "published release + download page to $FEED_BASE"
else
  echo "UPDATE_HOST / UPDATE_SSH_KEY not set — upload dist/appcast.xml, dist/*.dmg, dist/*.delta and dist/site/ under $FEED_BASE manually"
fi
