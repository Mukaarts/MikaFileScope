# App-Store-Paket — Mika+FileScope

Alles, was App Store Connect für die Erstveröffentlichung braucht: Texte, Screenshots
und die Skripte, um beides jederzeit reproduzierbar neu zu erzeugen.

> **Vor der Einreichung:** [CHECKLISTE.md](CHECKLISTE.md) durchgehen — dort stehen die
> Pflichtangaben, die nur im Apple-Konto zu erledigen sind.

---

## Was wohin gehört

| In App Store Connect | Datei |
|---|---|
| App-Name | `metadata/<locale>/name.txt` |
| Untertitel | `metadata/<locale>/subtitle.txt` |
| Werbetext (jederzeit ohne Review änderbar) | `metadata/<locale>/promotional_text.txt` |
| Beschreibung | `metadata/<locale>/description.txt` |
| Keywords | `metadata/<locale>/keywords.txt` |
| Neue Funktionen | `metadata/<locale>/release_notes.txt` |
| Support-URL / Marketing-URL | `metadata/<locale>/support_url.txt`, `marketing_url.txt` |
| Datenschutz-URL | `metadata/<locale>/privacy_url.txt` |
| Screenshots (2880 × 1800) | `screenshots/<locale>/mac-2880x1800/NN_name.jpg` |

Die Dateinamen folgen der Fastlane-Konvention — ein späterer Wechsel auf
`fastlane deliver` funktioniert ohne Umbau.

Grunddaten, Kategorien und die Antworten des Datenschutz-Fragebogens stehen in
[APP_STORE_CONNECT.md](APP_STORE_CONNECT.md), die des Altersfreigabe-Fragebogens in
[ALTERSFREIGABEN.md](ALTERSFREIGABEN.md) — dort mit Beleg aus dem Code, damit sie nach
einem Feature-Umbau nachprüfbar bleiben.

## Sprachen

**`en-US` ist die einzige Lokalisierung und die Primärsprache.** Das ist keine
Sparsamkeit, sondern Konsequenz: Die Oberfläche der App ist englisch, und eine
deutsche Headline über einer englischen Tabelle liest sich wie ein Fehler.

Die Struktur ist trotzdem mehrsprachig angelegt. Eine weitere Sprache kostet einen
Ordner unter `metadata/`, einen Block in `tools/shots.json`, einen Eintrag in `SPRACHE`
(`tools/compose.swift`) und eine Zeile in `locales` (`Tests/StoreAssetTests/`) — plus
eigene Rohaufnahmen, sobald die App selbst übersetzt ist.

## Screenshots

Fünf Motive in dieser Reihenfolge — die ersten drei sind im Store ohne Scrollen
sichtbar:

| # | Motiv | Aussage | Layout | Thema |
|---|---|---|---|---|
| 01 | Tabelle nach Dateityp | der Hook | `highlight` | hell |
| 02 | Ring- und Balkendiagramm | das stärkste Bild | `hero` | dunkel |
| 03 | Altersverteilung | der Aufräumgrund | `frame-top` | hell |
| 04 | Duplikatsuche | das Kaufargument | `highlight` | dunkel |
| 05 | Kategoriefilter | Bedienung | `text-top` | hell |

Vier Layouts statt einem: Fünf identisch aufgebaute Kacheln nebeneinander lesen sich
in der Store-Galerie wie ein Bild. `compose.swift` kennt deshalb

- `hero` — Fenster fast formatfüllend, Headline im abgedunkelten Fuß,
- `text-top` — Headline oben, Fenster darunter, unten angeschnitten,
- `frame-top` — Fenster läuft **oben** aus dem Bild, Text steht unten,
- `highlight` — wie `text-top`, davor ein vergrößerter Ausschnitt als schwebende
  Karte. Die Karte liegt in beiden Achsen genau über ihrer eigenen Herkunft und
  verdeckt sie; stünde sie woanders, sähe man denselben Inhalt zweimal.

Welches Motiv welches Layout bekommt — samt Ausschnitt — steht in `tools/shots.json`.

`frame-top` und `text-top` sind nicht beliebig austauschbar: `frame-top` schneidet
**oben** ab und eignet sich für Ansichten, deren Inhalt im unteren Fensterdrittel liegt
(die Zeitachse zeigt so beide Diagramme). Für den Kategoriefilter, dessen Aussage direkt
unter der Titelleiste steht, wäre es genau falsch herum.

Format: **2880 × 1800 px**, JPEG ohne Alphakanal — eine der von Apple für den Mac
akzeptierten Größen. `2560x1600` ist in `FORMATE` bereits hinterlegt; alle Layoutmaße
leiten sich aus der Leinwandgröße ab, ein weiteres Format kostet deshalb nur einen
Eintrag und einen Lauf mit `--format`.

JPEG und nicht PNG: Bei dieser Größe wiegt ein PNG rund 3 MB. App Store Connect nimmt
beides, solange kein Alphakanal drin ist.

---

## Neu erzeugen

```bash
AppStore/tools/capture.sh --build      # Bundle bauen, Demo-Ordner, Rohaufnahmen
swift AppStore/tools/compose.swift     # Layouts + Texte → fertige Screenshots
swift test --filter StoreAssetTests    # Limits, Bildmaße, Vollständigkeit
```

`capture.sh` ohne `--build` überspringt den Build und nimmt nur neu auf.
`compose.swift en-US` beschränkt die Komposition auf eine Sprache,
`compose.swift --format 2560x1600` schreibt ein zweites Format.

### Wie das funktioniert

Der Ordner auf den Aufnahmen entsteht über `scripts/make-demo-folder.sh` — immer
identisch, damit die Bilder bei der nächsten Version zusammenpassen und kein privater
Pfad im Screenshot landet. Die großen Dateien darin sind sparse: 4,17 GB angezeigt,
rund 34 MB tatsächlich belegt.

`capture.sh` steuert die App über Klicks an festen Bildschirmkoordinaten. Die sind aus
dem Fensterformat (1300 × 820 Punkte an Position 80,80) abgeleitet — wer das Format
ändert, muss sie neu ausmessen. Ein Weg über die Bedienungshilfen-API wäre robuster,
scheitert aber daran, dass die SwiftUI-Steuerelemente unter `UI element 1 of window 1`
verschachtelt liegen und sich nur umständlich adressieren lassen.

Zwei Fallen, die das Skript bewusst behandelt:

- Die Bedienungshilfen-Tastatur („Assistive Control") öffnet sich beim ersten
  `keystroke` und legt sich über das Fenster. Sie wird vor jeder Aufnahme beendet; die
  Systemeinstellung bleibt davon unberührt.
- Derselbe Dienst zeichnet nach einem Klick einen grünen Ring an die Mausposition.
  Zwischen letztem Klick und Aufnahme liegt deshalb ein Neustart des Dienstes.

Beides ist keine Feinheit: Die erste Fassung dieser Bilder trug eine eingeblendete
Bildschirmtastatur, und die fünfte Rohaufnahme war eine byteweise Kopie der vierten,
weil der Kategoriefilter nie geklickt worden war. `swift test --filter StoreAssetTests`
prüft seitdem, dass jedes Motiv eine eigene Rohaufnahme hat.

### Texte ändern

Headlines und Sublines stehen in `tools/shots.json`, nach Sprache getrennt.
`compose.swift` verkleinert die Headline automatisch, bis der Textblock in die
vorgesehene Höhe passt — längere Übersetzungen brechen das Layout also nicht.

Farben stammen aus `Sources/MikaPlusColors.swift`, die Schrift ist SF Pro vom System;
Store-Assets und App haben dadurch dieselbe Handschrift. Wer die Markenfarbe ändert,
ändert sie dort und spiegelt sie in `compose.swift` und `website/`.
