#!/bin/bash
# notarize.sh — DMG bei Apple notarisieren und das Ticket anheften.
#
# Voraussetzung ist ein einmalig hinterlegtes Zugangsprofil:
#
#   xcrun notarytool store-credentials "notarytool" \
#     --apple-id "<deine Apple-ID>" \
#     --team-id "CWJM4J4HFN" \
#     --password "<app-spezifisches Passwort von appleid.apple.com>"
#
# Das Passwort landet im Schlüsselbund, nicht in diesem Repository.
#
# Warum das nötig ist: Ohne Notarisierung weist Gatekeeper die App auf fremden
# Rechnern ab (BF-11) — und Sparkles Installer verweigert den Dienst bei ad-hoc
# signierten Bundles, was den Update-Kanal unbrauchbar machte (BF-06).
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-notarytool}"
DMG="${1:-}"

if [ -z "$DMG" ]; then
    DMG=$(ls -t "$(cd "$(dirname "$0")/.." && pwd)"/installer/*.dmg 2>/dev/null | head -1 || true)
fi
[ -f "$DMG" ] || { echo "FEHLER: Kein DMG gefunden. Aufruf: notarize.sh <pfad.dmg>" >&2; exit 1; }

echo "==> Paket: $DMG"

# Vorprüfung: Ad-hoc signierte Pakete lehnt Apple ab — das früh zu melden spart
# den Weg zum Server.
APP_IN_DMG=$(mktemp -d)
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$APP_IN_DMG" >/dev/null
SIG=$(codesign -dvv "$APP_IN_DMG"/*.app 2>&1 | grep -E "^Authority" | head -1 || echo "")
hdiutil detach "$APP_IN_DMG" -quiet
rmdir "$APP_IN_DMG" 2>/dev/null || true
if [ -z "$SIG" ] || echo "$SIG" | grep -qi "adhoc"; then
    echo "FEHLER: Die App im Paket ist nicht mit einer Developer ID signiert." >&2
    echo "        Baue mit: bash scripts/build.sh --release" >&2
    exit 1
fi
echo "==> Signatur: ${SIG#Authority=}"

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "FEHLER: Kein Zugangsprofil '$PROFILE' im Schlüsselbund." >&2
    echo "        Einmalig anlegen mit 'xcrun notarytool store-credentials' — siehe Kopf dieser Datei." >&2
    exit 1
fi

echo "==> Einreichen und auf das Ergebnis warten (dauert meist wenige Minuten)…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait

echo "==> Ticket anheften…"
# Ohne Stapling braucht jeder erste Start eine Internetverbindung.
xcrun stapler staple "$DMG"

echo "==> Gegenprobe:"
xcrun stapler validate "$DMG"
spctl -a -vv -t install "$DMG" 2>&1 | sed 's/^/    /'

echo ""
echo "==> Fertig. Danach:"
echo "    1. DMG als GitHub-Release anhängen"
echo "    2. sign_update auf das DMG anwenden"
echo "    3. appcast.xml auf main UND master ergänzen (Altbestände lesen master)"
