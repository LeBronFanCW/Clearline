#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
ARCHIVE="$ROOT/outputs/Clearline-macOS.zip"
VERIFY_DIR="$ROOT/work/release-verification"
APP="$VERIFY_DIR/Clearline.app"

rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
ditto -x -k "$ARCHIVE" "$VERIFY_DIR"

test -x "$APP/Contents/MacOS/Clearline"
test -f "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
otool -l "$APP/Contents/MacOS/Clearline" | grep -q '@executable_path/../Frameworks'
codesign --verify --deep "$APP"

"$APP/Contents/MacOS/Clearline" >/tmp/clearline-release-verify.log 2>&1 &
PID=$!
sleep 2
if ! kill -0 "$PID" 2>/dev/null; then
    cat /tmp/clearline-release-verify.log >&2
    exit 1
fi
kill "$PID"
wait "$PID" 2>/dev/null || true

echo "Verified Clearline: embedded Sparkle, runtime path, signature, and extracted launch."
