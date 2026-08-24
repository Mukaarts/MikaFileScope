# B08 · Menüleisten-Kurzfassung — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Ein optionales Symbol in der Menüleiste öffnet eine schmale Übersicht mit den Kennzahlen
des letzten Scans und den fünf größten Dateitypen. Ist es aktiv, läuft die App nach dem
Schließen des Fensters weiter.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | zeigt dessen Ergebnis; ohne Scan bleibt sie leer |

## User Stories

- **US-01** · Als Nutzer möchte ich die Kennzahlen des letzten Scans abrufen, ohne das
  Hauptfenster zu öffnen.
- **US-02** · Als Nutzer möchte ich einen Neuscan aus der Menüleiste anstoßen.
- **US-03** · Als Nutzer möchte ich das Symbol abschalten können, wenn ich es nicht
  brauche.

## Nicht im Scope

- **Ordner wählen** aus der Menüleiste — das geht nur im Hauptfenster.
- **Diagramme, Zeitachse, Duplikatsuche, Export** in der Kurzfassung.
- **Hintergrundüberwachung** eines Ordners: Es wird nichts selbsttätig neu gescannt.

## Akzeptanzkriterien

- **AK-01** · Angenommen, der Schalter „Menubar" in der Werkzeugleiste wird
  eingeschaltet, wenn er wirkt, dann erscheint das Symbol `doc.viewfinder` in der
  Menüleiste des Systems.
- **AK-02** · Angenommen, die Einstellung wurde vorgenommen, wenn die App neu gestartet
  wird, dann bleibt sie erhalten — sie liegt unter dem Schlüssel `showMenubar` in den
  Benutzereinstellungen.
- **AK-03** · Angenommen, das Symbol ist aktiv und das letzte Fenster wird geschlossen,
  wenn das System nach dem Beenden fragt, dann **läuft die App weiter**.
- **AK-04** · Angenommen, das Symbol ist nicht aktiv und das letzte Fenster wird
  geschlossen, wenn das System fragt, dann beendet sich die App.
- **AK-05** · Angenommen, das Symbol wird angeklickt, wenn sich die Übersicht öffnet,
  dann ist sie 280 Punkt breit und zeigt Kopfbereich, Inhalt und Fußzeile.
- **AK-06** · Angenommen, ein Scan liegt vor, wenn die Übersicht erscheint, dann zeigt
  sie den Ordnernamen, drei Kennzahlen (Files, Total, Types) und die **fünf** größten
  Dateitypen mit Balken und Größe.
- **AK-07** · Angenommen, kein Scan liegt vor, wenn die Übersicht erscheint, dann steht
  dort „No folder scanned".
- **AK-08** · Angenommen, ein Scan läuft, wenn die Übersicht offen ist, dann dreht sich
  im Kopfbereich eine Fortschrittsanzeige.
- **AK-09** · Angenommen, ein Ordner wurde gescannt, wenn „Rescan" in der Fußzeile
  gewählt wird, dann wird derselbe Ordner erneut durchlaufen — sichtbar in beiden
  Ansichten.
- **AK-10** · Angenommen, kein Ordner liegt vor oder ein Scan läuft, wenn die Fußzeile
  gezeichnet wird, dann ist „Rescan" nicht auslösbar.
- **AK-11** · Angenommen, „Quit" wird gewählt, wenn es wirkt, dann beendet sich die App
  vollständig.
- **AK-12** · Angenommen, Hauptfenster und Übersicht sind gleichzeitig sichtbar, wenn
  ein Scan endet, dann zeigen **beide** sofort das neue Ergebnis — sie teilen sich
  dieselbe Instanz.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-13, AK-14, AK-15, AK-16** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Symbol wird abgeschaltet, während die Übersicht offen ist → sie schließt
  sich mit dem Symbol.
- **EC-02** · Fenster geschlossen, Symbol aktiv, dann Symbol abgeschaltet → die App
  bleibt ohne Fenster und ohne Symbol; erreichbar nur noch über das Dock.
- **EC-03** · Ordner wurde gescannt, dann verschoben → „Rescan" schlägt fehl, der
  Warnhinweis erscheint im Hauptfenster, nicht in der Übersicht.
- **EC-04** · Weniger als fünf Typen → es werden entsprechend weniger Zeilen gezeigt.

## Fehlbestand

- **FB-B08-01 · Die Kurzfassung ignoriert den Kategoriefilter.** Siehe AK-13 und AK-16.

- **FB-B08-02 · Kein Zugang zur Ordnerwahl.** Siehe AK-14. Folge: Der beworbene
  „menubar quick scan" kann ohne Hauptfenster nichts scannen — er zeigt nur an.

- **FB-B08-03 · Der Einstellungsschlüssel steht dreimal als Zeichenkette im Code.**
  Siehe AK-15.

- **FB-B08-04 · Fehler sind in der Kurzfassung nicht sichtbar.** `errorMessage` wird nur
  im Hauptfenster ausgewertet. Folge: Ein aus der Menüleiste angestoßener Neuscan kann
  scheitern, ohne dass es dort auffällt.

- **FB-B08-05 · Eigene Kennzahlendarstellung statt der geteilten.** `miniStat` ist eine
  zweite Fassung von `StatPill` mit abweichendem Aussehen (DS-07, FB-B02-05).

- **FB-B08-06 · Feste Schriftgrößen.** 14, 12 und 11 Punkt für Text (DS-05). Folge:
  Dynamic Type wirkt in der Kurzfassung nicht.

- **FB-B08-07 · `LSUIElement` ist nicht gesetzt.** Die App bleibt im Dock, auch wenn
  ausschließlich die Menüleiste benutzt wird. Folge: Für einen reinen Menüleisten-Modus
  wäre das die übliche Einstellung — der Zustand ist heute ein Zwitter.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-13** · Angenommen, im Hauptfenster ist ein Kategoriefilter gesetzt, wenn die
  Übersicht geöffnet wird, dann zeigt sie **ungefilterte** Zahlen — zwei verschiedene
  Werte für denselben Ordner, gleichzeitig sichtbar.
  *(`MenubarPopoverView` liest `totalFiles`, `totalSize` und `groups` statt der
  gefilterten Entsprechungen. Siehe AS-01. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-14** · Angenommen, das Symbol ist aktiv und es wurde noch nie gescannt, wenn
  der Nutzer nur die Menüleiste benutzt, dann **kommt er nicht weiter** — es gibt keinen
  Weg, von dort aus einen Ordner zu wählen.
  *(Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-15** · Angenommen, der Schlüssel `showMenubar` wird gelesen, wenn das geschieht,
  dann auf **drei verschiedenen Wegen**: zweimal über `@AppStorage` und einmal direkt
  über die Benutzereinstellungen — die Zeichenkette steht dreimal im Code.
  *(Siehe AS-02. Ein Tippfehler beim Ändern bliebe beim Übersetzen unentdeckt. Zur
  Klärung vorgelegt.)*

- **war AK-16** · Angenommen, die fünf größten Typen werden angezeigt, wenn ihre Anteile
  gezeichnet werden, dann beziehen sie sich auf `engine.totalSize` — die **ungefilterte**
  Gesamtgröße, passend zu AK-13, aber abweichend von der Tabelle im Hauptfenster.
  *(Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll die Kurzfassung eine Ordnerwahl bekommen (AK-14) oder bewusst reine Anzeige bleiben?~~
  **Ordnerwahl ergänzt** (2026-08-24). Die Fußzeile des Popovers hat einen Eintrag „Ordner…". Ein „Quick Scan", der nichts scannen kann, widersprach der eigenen Bewerbung.
- **OF-02** · ~~Soll das Dock-Symbol im Menüleisten-Modus verschwinden (FB-B08-07)?~~
  **Nein, verworfen am 2026-08-24.** `LSUIElement` bleibt ungesetzt: Die App ist kein reines Menüleistenprogramm, sondern hat ein vollwertiges Fenster. Verschwände das Dock-Symbol, wäre die App nach dem Schließen des Fensters nur noch über die Menüleiste erreichbar.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | `MenuBarExtra` mit `isInserted` | eigenes `NSStatusItem` | SwiftUI-eigen, an eine Einstellung gebunden, kein AppKit-Zustand zu verwalten |
| 2 | `.menuBarExtraStyle(.window)` | `.menu` | Erlaubt Balken und mehrspaltige Kennzahlen — mit einem Menü nicht darstellbar |
| 3 | `ScanEngine` im `AppDelegate` | `@State` in `ContentView` | Der Zustand muss den Fensterschluss überleben. Der Grund, warum AK-12 funktioniert |
| 4 | Weiterlaufen an `showMenubar` koppeln | immer weiterlaufen | Ohne Symbol wäre die App unerreichbar. Die Kopplung ist richtig gedacht |
| 5 | Nur Anzeige, keine Bedienung | vollständige Bedienung im Popover | Grund nicht erkennbar. Führt dazu, dass „Quick Scan" nichts scannen kann (FB-B08-02) |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 4 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
