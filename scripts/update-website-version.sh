#!/bin/bash
# update-website-version.sh — trägt Version, Download-URL und Dateigröße in die
# Website ein, statt sie an vier Stellen von Hand zu pflegen (BF-20).
#
# Quelle ist die Info.plist des Projekts; die Dateigröße kommt aus dem erzeugten DMG,
# hilfsweise aus dem veröffentlichten Release.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HTML="$PROJECT_DIR/website/index.html"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/Resources/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PROJECT_DIR/Resources/Info.plist")
DMG="$PROJECT_DIR/installer/Mika+FileScope-v${VERSION}-${BUILD}.dmg"

if [ -f "$DMG" ]; then
    BYTES=$(stat -f%z "$DMG")
else
    echo "HINWEIS: $DMG nicht gefunden — Größe wird aus dem GitHub-Release gelesen." >&2
    BYTES=$(gh release view "v$VERSION" -R daumedia/MikaFileScope \
            --json assets --jq '.assets[0].size' 2>/dev/null || echo "")
fi
[ -z "$BYTES" ] && { echo "FEHLER: Dateigröße nicht ermittelbar." >&2; exit 1; }
MB=$(python3 -c "print(f'{$BYTES/1000/1000:.1f}')")

echo "==> Version $VERSION (Build $BUILD), ${MB} MB"

python3 - "$HTML" "$VERSION" "$MB" <<'PY'
import re, sys
path, version, mb = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path, encoding="utf-8").read()
s = re.sub(r"Version \d+\.\d+\.\d+", f"Version {version}", s)
s = re.sub(r"\d+\.\d+&nbsp;MB", f"{mb}&nbsp;MB", s)
s = re.sub(r"Mika%2BFileScope-v[\d.]+(-\d+)?\.dmg",
           f"Mika%2BFileScope-v{version}.dmg", s)
s = re.sub(r'"softwareVersion": "[^"]*"', f'"softwareVersion": "{version}"', s)
open(path, "w", encoding="utf-8").write(s)
print("    index.html aktualisiert")
PY

echo "==> Fertig. Bitte 'git diff website/index.html' prüfen."
