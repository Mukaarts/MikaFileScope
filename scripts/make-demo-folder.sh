#!/bin/bash
# make-demo-folder.sh — legt den Ordner an, der auf den App-Store-Screenshots zu sehen ist.
#
# Warum reproduzierbar: Die Aufnahmen müssen bei jeder Version gleich aussehen, sonst
# wirkt der Store-Eintrag zusammengewürfelt. Und der Pfad gehört an eine Stelle, die
# man vorzeigen kann — ein Scratchpad-Pfad im Screenshot sieht unseriös aus.
#
# Die großen Dateien sind "sparse": Sie melden ihre volle Größe, belegen aber kaum
# Platz. 3,9 GB Anzeige, rund 34 MB tatsächlich.
set -euo pipefail

D="${1:-$HOME/Downloads/FileScope Demo}"
rm -rf "$D"
mkdir -p "$D/Fotos 2026" "$D/Rechnungen" "$D/Projektdateien"

sparse () { dd if=/dev/zero of="$1" bs=1 count=0 seek="$2" 2>/dev/null; }
# Alle unterschiedlich groß — gleich große Nulldateien gälten sonst als Duplikate.
sparse "$D/Urlaub Sardinien.mov"            1840000000
sparse "$D/Drohnenflug Küste.mp4"            920000000
sparse "$D/Interview Rohschnitt.mov"         641000000
sparse "$D/Archiv 2025.zip"                  480000000
sparse "$D/Fotos 2026/Panorama Küste.tiff"    96000000
sparse "$D/Projektdateien/Präsentation.key"   78000000
sparse "$D/Fotos 2026/IMG_4823.raw"           42000000
sparse "$D/Projektdateien/Entwurf.sketch"     34000000

# Kleine Dateien mit echtem Inhalt, damit die Duplikatsuche etwas zu vergleichen hat.
mk () { head -c "$2" /dev/urandom > "$1"; }
mk "$D/Fotos 2026/IMG_4821.heic"        8400000
mk "$D/Fotos 2026/IMG_4822.heic"        7900000
mk "$D/Fotos 2026/IMG_4824.heic"        8100000
mk "$D/Rechnungen/Rechnung 2026-03.pdf"  240000
mk "$D/Rechnungen/Rechnung 2026-04.pdf"  260000
mk "$D/Rechnungen/Steuerbescheid.pdf"   1800000
mk "$D/Projektdateien/main.swift"          24000
mk "$D/Projektdateien/README.md"            8000

# Zwei echte Duplikat-Paare — der eigentliche Vorführeffekt.
cp "$D/Fotos 2026/IMG_4821.heic" "$D/Fotos 2026/IMG_4821 Kopie.heic"
cp "$D/Rechnungen/Rechnung 2026-03.pdf" "$D/Rechnung 2026-03 (1).pdf"

# Änderungsdaten über alle Zeitfenster verteilen, damit die Zeitachse etwas zeigt.
touch -t 202608240900 "$D/Urlaub Sardinien.mov" "$D/Fotos 2026/"*.heic
touch -t 202608100900 "$D/Drohnenflug Küste.mp4"
touch -t 202607150900 "$D/Rechnungen/"*.pdf
touch -t 202604200900 "$D/Projektdateien/"*
touch -t 202511100900 "$D/Archiv 2025.zip" "$D/Interview Rohschnitt.mov"

echo "==> $D"
echo "    $(find "$D" -type f | wc -l | tr -d ' ') Dateien · $(du -shA "$D" 2>/dev/null | cut -f1) gemeldet · $(du -sh "$D" | cut -f1) belegt"
echo ""
echo "    Danach: App starten, diesen Ordner scannen, Fenster auf 1300×820,"
echo "    Aufnahmen mit screencapture, dann auf 2880×1800 padden:"
echo "      sips --padToHeightWidth 1800 2880 --padColor 0F0F1A in.png --out pad.png"
echo "      sips -s format jpeg -s formatOptions 95 pad.png --out store/screenshots/x.jpg"
