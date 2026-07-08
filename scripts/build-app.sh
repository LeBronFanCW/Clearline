#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
FINAL_APP="$ROOT/outputs/Clearline.app"
BUILD_ROOT="$(mktemp -d /tmp/clearline-build.XXXXXX)"
APP="$BUILD_ROOT/Clearline.app"
ICON="$ROOT/Support/Clearline.icns"
trap 'rm -rf "$BUILD_ROOT"' EXIT

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/Clearline" "$APP/Contents/MacOS/Clearline"
/usr/bin/install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/Clearline"
cp "Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ICON" "$APP/Contents/Resources/Clearline.icns"

if [[ -n "${CLEARLINE_VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $CLEARLINE_VERSION" "$APP/Contents/Info.plist"
fi
if [[ -n "${CLEARLINE_BUILD_NUMBER:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CLEARLINE_BUILD_NUMBER" "$APP/Contents/Info.plist"
fi

SPARKLE_FRAMEWORK="$(find .build -path '*/release/Sparkle.framework' -type d -print -quit)"
if [[ -z "$SPARKLE_FRAMEWORK" ]]; then
    echo "Sparkle.framework was not produced by SwiftPM" >&2
    exit 1
fi
mkdir -p "$APP/Contents/Frameworks"
ditto "$SPARKLE_FRAMEWORK" "$APP/Contents/Frameworks/Sparkle.framework"
xattr -cr "$APP"

if [[ -n "${CLEARLINE_UPDATE_FEED_URL:-}" && -n "${CLEARLINE_UPDATE_PUBLIC_KEY:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $CLEARLINE_UPDATE_FEED_URL" "$APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $CLEARLINE_UPDATE_PUBLIC_KEY" "$APP/Contents/Info.plist"
fi

SIGN_IDENTITY="${CLEARLINE_SIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$APP"
else
    codesign --force --options runtime --timestamp --deep --sign "$SIGN_IDENTITY" "$APP"
fi
xattr -cr "$APP"
rm -rf "$FINAL_APP"
ditto "$APP" "$FINAL_APP"
xattr -cr "$FINAL_APP" 2>/dev/null || true
echo "$FINAL_APP"
