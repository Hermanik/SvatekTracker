#!/usr/bin/env bash
# Builds dist/SvátekTracker.app from a release build: bundle structure,
# Info.plist (menubar-only via LSUIElement), the committed icon, and a code
# signature. A real bundle is what notifications and launch-at-login need —
# `swift run` has neither.
#
# Signs with the Developer ID identity when it's in the keychain (a stable,
# cert-based requirement, so the login item survives rebuilds), else ad-hoc.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(cat VERSION)
APP="dist/SvátekTracker.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/SvatekTracker "$APP/Contents/MacOS/SvatekTracker"
cp assets/SvatekTracker.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>cs</string>
	<key>CFBundleDisplayName</key>
	<string>SvátekTracker</string>
	<key>CFBundleExecutable</key>
	<string>SvatekTracker</string>
	<key>CFBundleIconFile</key>
	<string>SvatekTracker</string>
	<key>CFBundleIdentifier</key>
	<string>com.hermanik.svatektracker</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>SvátekTracker</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.utilities</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>© $(date +%Y) Jan Herrmann</string>
</dict>
</plist>
PLIST

SIGN_ID="${SIGN_ID:-$(security find-identity -v -p codesigning \
  | grep -m1 'Developer ID Application' | sed -E 's/.*"(.*)".*/\1/' || true)}"

codesign --force --sign "${SIGN_ID:--}" "$APP"
codesign --verify "$APP"
echo "built $APP (v${VERSION}, signed: ${SIGN_ID:-ad-hoc})"
