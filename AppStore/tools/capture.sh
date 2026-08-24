#!/bin/bash
# capture.sh — nimmt die fünf Rohaufnahmen für die App-Store-Bilder auf.
#
#     AppStore/tools/capture.sh            # nur aufnehmen
#     AppStore/tools/capture.sh --build    # vorher das Bundle neu bauen
#
# Ergebnis: AppStore/screenshots/raw/en/01_list.png … 05_videos.png.
# Danach `swift AppStore/tools/compose.swift` für die fertigen Bilder.
#
# Warum Koordinatenklicks und nicht die Bedienungshilfen-API: Die Steuerelemente
# der App liegen als SwiftUI-Elemente unter `UI element 1 of window 1` und sind
# über System Events nur umständlich erreichbar. Die Koordinaten unten sind aus
# dem festen Fensterformat (1300×820 Punkte an Position 80,80) abgeleitet — wer
# das Format ändert, muss sie neu ausmessen.
#
# Zwei Fallen, die hier bewusst behandelt werden:
#
#   - Die Bedienungshilfen-Tastatur ("Assistive Control") öffnet sich beim ersten
#     `keystroke` und legt sich über das Fenster. Sie wird deshalb vor jeder
#     Aufnahme beendet; die Systemeinstellung bleibt davon unberührt.
#   - Derselbe Dienst zeichnet nach einem Klick einen grünen Ring an die
#     Mausposition. Zwischen letztem Klick und Aufnahme liegt deshalb ein
#     Neustart des Dienstes, sonst steht der Ring im Bild.
set -euo pipefail

PROJEKT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZIEL="$PROJEKT/AppStore/screenshots/raw/en"
APP="$PROJEKT/build/Mika+FileScope.app"
DEMO="$HOME/Downloads/FileScope Demo"

# Fensterrahmen in Punkten. Die Aufnahme wird dadurch 2600×1640 Pixel groß.
X=80; Y=80; B=1300; H=820

if [[ "${1:-}" == "--build" ]]; then
    echo "==> Bundle bauen"
    bash "$PROJEKT/scripts/build.sh" >/dev/null
fi

[[ -d "$APP" ]] || { echo "✘ $APP fehlt — mit --build starten"; exit 1; }

echo "==> Demo-Ordner"
bash "$PROJEKT/scripts/make-demo-folder.sh" "$DEMO" | tail -2

mkdir -p "$ZIEL"

ruhe () { pkill -f "Assistive Control" 2>/dev/null || true; sleep 2; }
klick () { osascript -e "tell application \"System Events\" to tell process \"MikaFileScope\" to click at {$1, $2}" >/dev/null; sleep 1.5; }

aufnehmen () {
    ruhe
    osascript -e 'tell application "System Events" to tell process "MikaFileScope" to set frontmost to true' >/dev/null
    sleep 0.8
    screencapture -o -x -R$X,$Y,$B,$H "$ZIEL/$1.png"
    echo "    $1.png"
}

echo "==> App starten"
pkill -f "Mika+FileScope" 2>/dev/null || true
sleep 1
open "$APP"
sleep 4
osascript <<AS >/dev/null
tell application "System Events" to tell process "MikaFileScope"
    set frontmost to true
    tell window 1
        set position to {$X, $Y}
        set size to {$B, $H}
    end tell
end tell
AS
sleep 1

echo "==> Ordner wählen"
# Der leere Zustand zeigt "Choose Folder" mittig; nach einem früheren Lauf kann
# das Lesezeichen den Ordner schon wiederhergestellt haben.
if osascript -e 'tell application "System Events" to tell process "MikaFileScope" to return (count of buttons of group 1 of window 1)' 2>/dev/null | grep -q "^1$"; then
    klick 729 572
    osascript <<'AS' >/dev/null
tell application "System Events"
    keystroke "g" using {command down, shift down}
    delay 1
    keystroke "~/Downloads/FileScope Demo"
    delay 0.8
    key code 36
    delay 1.2
    key code 36
end tell
AS
    sleep 6
fi

echo "==> Aufnehmen"
aufnehmen 01_list

klick 749 266            # Reiter Charts
aufnehmen 02_charts

klick 821 266            # Reiter Timeline
aufnehmen 03_timeline

klick 676 266            # zurück auf List
klick 1308 106           # Duplikatsuche starten
sleep 6                  # SHA-256 über den Demo-Ordner
aufnehmen 04_duplicates

osascript -e 'tell application "System Events" to key code 53' >/dev/null   # Sheet schließen
sleep 1.5
klick 383 223            # Kategorie Videos
aufnehmen 05_videos

klick 125 223            # zurück auf All
osascript -e 'tell application "Mika+FileScope" to quit' >/dev/null 2>&1 || true

echo ""
echo "==> $(ls "$ZIEL"/*.png | wc -l | tr -d ' ') Rohaufnahmen in AppStore/screenshots/raw/en/"
echo "    Weiter mit: swift AppStore/tools/compose.swift"
