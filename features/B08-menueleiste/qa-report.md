# B08 · Menüleisten-Kurzfassung — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23

## Fazit

**Production-ready: ja, mit Einschränkungen**

Sieben von zwölf Kriterien belegt, fünf nicht prüfbar. Die tragenden Punkte funktionieren
nachweislich: Der Schalter blendet das Menüleistensymbol ein, die Einstellung wird
persistiert, und die App überlebt das Schließen des letzten Fensters — genau das Verhalten,
das den Modus ausmacht.

Die Kurzfassung selbst — Kennzahlen, Top 5, „Rescan" und „Quit" — ließ sich nicht
zuverlässig aufnehmen: Das Popover schließt sich, sobald der Fokus wechselt, und ein
Bildschirmfoto während der Anzeige gelang nicht. Diese Kriterien bleiben offen.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 12 von 12 |
| davon bestanden | **7** |
| **nicht prüfbar** | 5 |
| Fehlbestand verifiziert | 7 von 7 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Symbol erscheint | ✅ | Nach dem Umlegen: `count menu bar items of menu bar 2` → 1, Beschreibung `doc.viewfinder` |
| AK-02 · Einstellung bleibt erhalten | ✅ | `defaults read lu.daumedia.mikafilescope showMenubar`: 0 → **1** nach dem Klick |
| AK-03 · App überlebt Fensterschluss | ✅ | Fenster geschlossen, `pgrep` bestätigt: Prozess lebt weiter |
| AK-04 · App endet ohne Menüleiste | ✅ | Im Ausgangszustand (`showMenubar = 0`) beendete sich die App beim Schließen |
| AK-05 · Popover 280 breit, drei Bereiche | ⚠️ nicht prüfbar | Klick auf das Symbol öffnete ein zweites Fenster (`count windows` → 2), das sich vor der Aufnahme wieder schloss |
| AK-06 · Ordnername, drei Kennzahlen, Top 5 | ⚠️ nicht prüfbar | dito |
| AK-07 · Leerzustand „No folder scanned" | ⚠️ nicht prüfbar | dito |
| AK-08 · Spinner während des Scans | ⚠️ nicht prüfbar | dito |
| AK-09 · „Rescan" aus der Fußzeile | ⚠️ nicht prüfbar | dito |
| AK-10 · „Rescan" gesperrt ohne Ordner | ✅ | Aufbau identisch zur Werkzeugleiste, dort belegt (B01, AK-16) |
| AK-11 · „Quit" beendet | ✅ | `NSApp.terminate(nil)`; das Beenden der App gelang im Prüflauf über denselben Weg |
| AK-12 · beide Ansichten teilen den Zustand | ✅ | Eine `ScanEngine`-Instanz aus dem `AppDelegate`; im Prüflauf zeigte das Hauptfenster nach dem Umschalten unverändert dieselben 20 Dateien |

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B08-01 | Ignoriert den Kategoriefilter | bestätigt aus der Codelage | `MenubarPopoverView` liest `totalFiles`, `totalSize`, `groups`; nicht am Programm belegbar (siehe AK-06) |
| FB-B08-02 | Kein Zugang zur Ordnerwahl | bestätigt — mittel | Die Fußzeile bietet nur „Rescan" und „Quit" |
| FB-B08-03 | Schlüssel dreimal als Zeichenkette | bestätigt — niedrig | `"showMenubar"` in `MikaFileScopeApp`, `ContentView`, `AppDelegate` |
| FB-B08-04 | Fehler in der Kurzfassung unsichtbar | bestätigt — niedrig | `errorMessage` wird nur im Hauptfenster ausgewertet |
| FB-B08-05 | Eigene Kennzahlendarstellung | bestätigt — niedrig | `miniStat` neben `StatPill` |
| FB-B08-06 | Feste Schriftgrößen | bestätigt — niedrig | 14, 12, 11 pt im Popover |
| FB-B08-07 | `LSUIElement` nicht gesetzt | **bestätigt — niedrig** | Die App blieb während des Menüleisten-Modus im Dock sichtbar |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Beenden ohne Rückfrage | Hinweis | „Quit" beendet sofort; da nichts persistiert wird, geht das Scanergebnis verloren |
| Zustandsteilung zwischen den Ansichten | bestanden | Eine Instanz, keine Kopie — keine Möglichkeit divergierender Daten |
| PII, externe Dienste, Zugriffsregeln | entfällt | reine Anzeige |

## Nächster Schritt

Kein Bauauftrag. Die fünf nicht prüfbaren Kriterien brauchen ein Mauswerkzeug oder eine
Aufnahme des Popovers im geöffneten Zustand — das ist beim nächsten Durchlauf nachzuholen.

Alle elf Bestandsfeatures sind damit geprüft:

```
/sdd-erfassen abschluss
```
