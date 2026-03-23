#!/bin/bash
# create-dmg-simple.sh — Create DMG using hdiutil (no dependencies)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/Mika+FileScope.app"
INSTALLER_DIR="$PROJECT_DIR/installer"
APP_NAME="Mika+FileScope"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: App bundle not found at $APP_BUNDLE"
    echo "Run 'bash scripts/build.sh' first."
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="$INSTALLER_DIR/$DMG_NAME"

mkdir -p "$INSTALLER_DIR"
rm -f "$DMG_PATH"

echo "==> Creating DMG: $DMG_NAME"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov -format UDZO \
    "$DMG_PATH"

echo ""
echo "==> DMG created: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
