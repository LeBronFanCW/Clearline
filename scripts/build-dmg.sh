#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
VERSION="${CLEARLINE_VERSION:-1.0.4}"
VOLUME_NAME="Clearline Installer"
STAGE="$ROOT/work/dmg-stage"
MOUNT="/Volumes/$VOLUME_NAME"
RW_DMG="$ROOT/work/Clearline-rw.dmg"
FINAL_DMG="$ROOT/outputs/Clearline-${VERSION}.dmg"

cd "$ROOT"
"$ROOT/scripts/build-app.sh"

if mount | grep -q "on $MOUNT "; then
    hdiutil detach "$MOUNT" >/dev/null
fi
rm -rf "$STAGE" "$RW_DMG" "$FINAL_DMG"
mkdir -p "$STAGE"
ditto "$ROOT/outputs/Clearline.app" "$STAGE/Clearline.app"
ln -s /Applications "$STAGE/Applications"
cp "$ROOT/Support/Clearline.icns" "$STAGE/.VolumeIcon.icns"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$RW_DMG" >/dev/null

hdiutil attach "$RW_DMG" -nobrowse -noverify >/dev/null

if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "$MOUNT"
fi

if [[ "${CLEARLINE_SKIP_DMG_STYLING:-0}" != "1" ]]; then
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set bounds of container window to {180, 180, 780, 560}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set text size of theViewOptions to 14
        set background color of theViewOptions to {62720, 63736, 65535}
        set position of item "Clearline.app" of container window to {165, 185}
        set position of item "Applications" of container window to {435, 185}
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT
fi

sync
hdiutil detach "$MOUNT" >/dev/null
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null
rm -rf "$STAGE" "$RW_DMG"

hdiutil verify "$FINAL_DMG" >/dev/null
echo "$FINAL_DMG"
