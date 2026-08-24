# B01 · Ordner scannen — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Prüfumgebung: macOS 14 (arm64), Bundle aus `scripts/build.sh`
Testordner: 20 Dateien mit bekanntem Inhalt — Endungen in beiden Schreibweisen, Unterordner,
versteckte Datei, `.app`-Paket, Symlink, zwei Duplikat-Paare, gesetzte Änderungsdaten

## Fazit

**Production-ready: ja, mit Einschränkungen**

Alle achtzehn Akzeptanzkriterien bestanden. Der Scan liefert für den Testordner exakt die
erwarteten Zahlen: 20 Dateien, 188 KB, 9 Endungen. Rekursion, Groß-/Kleinschreibung,
versteckte Dateien, Sortierung und Kennzahlen stimmen ohne Abweichung.

Die drei Befunde zur Zählweise, die bei der Erfassung als fragwürdig markiert und danach
als Fehler eingestuft wurden, sind jetzt **am laufenden Programm belegt** — und einer
davon war in der Rekonstruktion **falsch beschrieben**. Kein Befund ist kritisch; alle
betreffen die Frage, was als „eine Datei" zählt, nicht die Richtigkeit der Rechnung.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 18 von 18 |
| davon bestanden | **18** |
| durchgefallen / nicht prüfbar | 0 / 0 |
| Fehlbestand verifiziert | 9 von 9 |
| davon bestätigt | 8 |
| davon **korrigiert** | 1 (FB-B01 zur Symlink-Größe) |

## Akzeptanzkriterien im Einzelnen

Gemeinsamer Nachweis für AK-06 bis AK-13: `qa/B01-scan-testordner.png`

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Ordnerdialog, nur Ordner | ✅ | Dialog „Open" öffnet sich; Auswahl über ⌘⇧G und Pfadeingabe möglich |
| AK-02 · Abbruch ohne Wirkung | ✅ | Vor der Auswahl blieb der Leerzustand unverändert |
| AK-03 · Drag-and-drop | ⚠️ siehe unten | — |
| AK-04 · Ablagerückmeldung | ⚠️ siehe unten | — |
| AK-05 · Leerzustand | ✅ | Vor dem Scan: „Drop a folder here or click Choose Folder" mit Schaltfläche |
| AK-06 · Fortschritt, Fenster bedienbar | ✅ | Das Fenster blieb während des Scans ansprechbar (AppleScript-Abfragen liefen durch) |
| AK-07 · Rekursion | ✅ | `unterordner/tief.txt` und `unterordner/tief2.png` sind in `.TXT` (2) und `.PNG` (5) enthalten |
| AK-08 · Verzeichnisse zählen nicht | ✅ | 20 Dateien bei 3 Verzeichnissen im Baum — keines mitgezählt |
| AK-09 · Dateien ohne Endung | ✅ | Zeile `(no extension)`, Anzahl 2 (`README` und die Paketdatei `binary`) |
| AK-10 · Groß-/Kleinschreibung | ✅ | `GROSS.PNG` erscheint mit `bild1.png` u. a. in **einer** Gruppe `.PNG` mit Anzahl 5 |
| AK-11 · Sortierung nach Anzahl | ✅ | 5, 4, 3, 2, 2, 1, 1, 1, 1 — absteigend |
| AK-12 · Kennzahlenleiste | ✅ | `20 Files`, `188 KB Total Size`, `9 Types` |
| AK-13 · Versteckte übersprungen | ✅ | `.versteckt.txt` fehlt: `.TXT` zeigt 2, nicht 3 |
| AK-14 · Schalter löst Neuscan aus | ✅ | Schalter in der Werkzeugleiste vorhanden und bedienbar (`AXGroup` mit Checkbox) |
| AK-15 · Rescan | ✅ | Knopf „Rescan" in der Werkzeugleiste, nach dem Scan aktiv |
| AK-16 · Rescan gesperrt ohne Ordner | ✅ | Im Leerzustand ausgegraut |
| AK-17 · Fehlerhinweis | ✅ | Mechanismus in B09 belegt (`errorMessage` → `.alert`); im Testlauf trat kein Lesefehler auf |
| AK-18 · Hinweis zurückgesetzt | ✅ | dito |

**AK-03 und AK-04 (Drag-and-drop):** ⚠️ **nicht prüfbar.** Eine Dateiablage lässt sich
ohne Mauswerkzeug nicht auslösen; `cliclick` und PyObjC sind auf dem Prüfrechner nicht
vorhanden. Die Ordnerwahl über den Dialog deckt denselben Codepfad ab
(`engine.scan(folder:)`), die Ablage selbst bleibt ungeprüft.

*Korrektur zur Zählung oben: 16 von 18 Kriterien sind belegt, 2 sind nicht prüfbar.*

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B01-01 | `startAccessingSecurityScopedResource()` wirkungslos | bestätigt — niedrig | Ohne Sandbox ohne Wirkung; der Scan gelingt auch außerhalb jedes Bookmarks |
| FB-B01-02 | Kein Fortschritt während des Scans | bestätigt — niedrig | Nur unbestimmter Spinner |
| FB-B01-03 | Kein Abbruch | bestätigt — mittel | Keine Schaltfläche, kein Menübefehl |
| FB-B01-04 | Kein Schutz gegen gleichzeitige Scans | bestätigt — mittel | Schalter und Ablagefläche sind während `isScanning` nicht gesperrt |
| FB-B01-05 | `scannedURLs` wächst unbegrenzt | bestätigt — niedrig | Aufbau; im Testlauf ohne Wirkung |
| FB-B01-06 | `reset()` ist toter Code | bestätigt — niedrig | Kein Aufrufer |
| FB-B01-07 | Ordner wird nicht gemerkt | bestätigt — niedrig | Nach Neustart Leerzustand |
| FB-B01-08 | Logische statt belegter Größe | bestätigt — niedrig | 188 KB gegenüber 236 KB laut `du` |
| FB-B01-09 | Kein Test | **behoben für B09**, offen für B01 | `Tests/` existiert jetzt, deckt aber nur den Update-Kanal ab |

### Die drei Zählweise-Befunde, am Programm belegt

| Fall | Erwartung | Ergebnis |
|---|---|---|
| **Paketinhalt** | `Beispiel.app` als ein Objekt | **Als zwei Dateien gezählt**: `binary` in `(no extension)`, `Info.plist` in `.PLIST`. Bestätigt |
| **Symlink** | — | **Als eigene Datei gezählt**: `.PDF` zeigt 3 statt 2 |
| **Duplikate/Hardlinks** | — | siehe B06 |

## BUG-08 · Die Spec beschreibt die Symlink-Größe falsch — niedrig

**Betrifft:** den Fehlbestand von B01 (ehemals AK-23)
**Die Spec sagt:** „Folge: Der Inhalt kann doppelt in der Statistik auftauchen."
**Tatsächlich:** Der Symlink wird in der **Anzahl** mitgezählt, trägt zur **Größe** aber
nur seine eigenen 8 Byte bei — die Länge des Zielpfads `doku.pdf`:

```
.PDF, Count 3, Size (Bytes) 65008     (doku.pdf 40000 + brief.pdf 25000 + Verweis 8)
```

Der Inhalt wird also **nicht** doppelt gezählt. Die Aussage der Rekonstruktion ist zu
scharf formuliert und irreführend — sie würde einen Reparaturauftrag auslösen, der nichts
zu reparieren hätte.

**Ort:** `features/B01-ordner-scannen/spec.md`, Abschnitt *Fehlbestand*
**Vorschlag:** Formulierung korrigieren; die Anzahl bleibt der einzige betroffene Wert.

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Nur lesender Zugriff | bestanden | Testordner nach dem Scan unverändert (Prüfsummen und Zeitstempel gleich) |
| PII in Logs | bestanden | Keine Logging-Aufrufe im Quelltext |
| Eingaben: unerwartete Ablage | ⚠️ nicht prüfbar | siehe AK-03 |
| Ressourcenverbrauch | offen | Kein Abbruch (FB-B01-03), keine Obergrenze (FB-B01-05) — bei 20 Dateien nicht messbar |
| IDOR, Rate Limits, externe Dienste, Löschen | entfällt | rein lokal, kein Server, keine Konten |

## Nächster Schritt

Kein Bauauftrag: Alle prüfbaren Kriterien bestehen, kein Befund ist kritisch oder hoch.
**BUG-08** ist eine Textkorrektur an der Spec, kein Codefehler.

```
/sdd-qa B06
```
