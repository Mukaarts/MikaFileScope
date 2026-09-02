# App Store Connect — Feld für Feld

Version 2.1.0 · Bundle-ID `lu.daumedia.mikafilescope` · Stand 2026-08-24

Die Texte stehen in `metadata/en-US/` und sind zum Kopieren gedacht. Hier steht alles,
was **nicht** in einer Textdatei liegt: Grunddaten, Kategorien und die Antworten der
Fragebögen.

## Grunddaten

| Feld | Wert |
|---|---|
| Name | Mika+FileScope |
| Bundle-ID | `lu.daumedia.mikafilescope` |
| SKU | `mikafilescope-mac` |
| Primäre Kategorie | Dienstprogramme / Utilities |
| Sekundäre Kategorie | *(leer lassen)* |
| Preis | Kostenlos |
| Altersfreigabe | 4+ (siehe [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md)) |
| Copyright | 2025 dauMedia / Mika |
| Plattform | macOS 14 Sonoma oder neuer, Apple silicon und Intel |

## App Privacy — das „Nutrition Label"

Die Antwort ist durchgehend dieselbe, und das ist ein Verkaufsargument:

> **Data Not Collected** — für jede einzelne Kategorie.

Begründung, falls die Prüfung nachfragt: Die App führt keine Konten, sendet nichts und
speichert nur eine Einstellung (Menüleistensymbol ja/nein) sowie ein Lesezeichen des
zuletzt gewählten Ordners. Beides bleibt lokal. Belegbar über den öffentlichen
Quelltext — `grep -rn "URLSession" Sources/` liefert nichts.

Die Store-Variante wird ohne Sparkle gebaut (`APPSTORE=1`), enthält also auch keinen
Update-Kanal, der eine Verbindung aufbauen könnte.

## Altersfreigaben

Der Fragebogen hat 24 Kategorien; jede einzelne wird mit „Nein" bzw. „Nie" beantwortet.
Das Ergebnis ist **4+**. Die Antworten stehen samt Beleg in
[ALTERSFREIGABEN.md](ALTERSFREIGABEN.md) — inklusive der einen Frage, die bei einer
Prüfung aufkommen kann: warum die angezeigten Dateinamen keine „benutzergenerierten
Inhalte" sind.

## Prüfungshinweise für Apple (App Review Information)

```
The app requires no sign-in of any kind.

To review: drag any folder onto the window, or pick one via "Choose Folder". A small
folder with mixed file types shows every feature in a few seconds. Scanning the whole
home folder also works, but takes considerably longer on a full machine.

Expected system prompts: if you scan a folder that contains Desktop, Documents or
Downloads, macOS asks for consent to each of them separately. Those dialogs come from
the system, not from the app. On first launch the app announces them beforehand and
explains what it reads. Each prompt carries a purpose string describing what is read
and what for.

The app reads metadata only (name, size, modification date). Only duplicate detection
reads file contents, block by block, to build a checksum; the contents are neither
stored nor transmitted.

Export: after a scan, use the Export button in the toolbar or File > Export as CSV
(Cmd-E) / Export as JSON (Shift-Cmd-E). Both open a save dialog and write the file
where you point it. The export stays disabled while no scan result is present.

The app makes no network connections.
```

## Berechtigungen

Die Store-Variante läuft in der Sandbox
(`Resources/MikaFileScope-AppStore.entitlements`):

| Entitlement | Wofür |
|---|---|
| `com.apple.security.app-sandbox` | Pflicht im Store |
| `com.apple.security.files.user-selected.read-write` | der Ordner, den der Nutzer wählt — und die Exportdatei, die er im Speichern-Dialog benennt. Mit `read-only` öffnet die Powerbox diesen Dialog nicht |
| `com.apple.security.files.bookmarks.app-scope` | den zuletzt gewählten Ordner nach einem Neustart wiederfinden |

Kein `com.apple.security.network.client` — die App stellt keine Verbindungen her.

## Screenshots

Fünf Bilder aus `screenshots/en-US/mac-2880x1800/`, in der Nummernreihenfolge
hochladen. Die ersten drei sind ohne Scrollen sichtbar; die Reihenfolge ist bewusst
gewählt und sollte so bleiben.
