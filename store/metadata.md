# App Store Connect — Eintrag für Mika+FileScope

Stand: 2026-08-24 · Version 2.1.0 · Bundle-ID `lu.daumedia.mikafilescope`

Alles hier ist zum Kopieren gedacht. Die Zeichenzahlen stehen dabei, weil App Store
Connect hart abschneidet.

---

## Grunddaten

| Feld | Wert |
|---|---|
| Name | `Mika+FileScope` |
| Bundle-ID | `lu.daumedia.mikafilescope` |
| SKU | `mikafilescope-mac` |
| Primäre Kategorie | Dienstprogramme |
| Sekundäre Kategorie | *(leer lassen)* |
| Preis | Kostenlos |
| Altersfreigabe | 4+ |
| Copyright | `2025 dauMedia / Mika` |

## Untertitel (max. 30)

```
Wo ist der Platz geblieben?
```

Alternativen, falls dir eine andere besser gefällt — alle innerhalb des Limits:
`Wohin ist der Platz hin?` (24) · `Was frisst Ihren Speicher?` (26) ·
`Sehen, wo der Platz bleibt` (26)

## Werbetext / Promotional Text (max. 170)

Lässt sich jederzeit ohne neue Version ändern — gut für Hinweise auf Neuerungen.

```
Ordner draufziehen, einmal scannen: Tabelle, Diagramme, Altersverteilung und
Duplikatsuche. Alles bleibt auf dem Mac, gelöscht wird nichts.
```

## Beschreibung (max. 4000)

```
Mika+FileScope beantwortet eine Frage, für die macOS kein gutes Werkzeug mitbringt:
Was liegt eigentlich in diesem Ordner, und was davon frisst den Platz?

Ordner draufziehen, einmal scannen — und aus diesem einen Durchlauf entstehen fünf
Sichten auf denselben Bestand.

SORTIERBARE TABELLE
Jede vorkommende Dateiendung mit Anzahl, Gesamtgröße und Anteil am Ganzen. Der eine
Typ, der 98 % des Ordners ausmacht, ist nicht zu übersehen.

DIAGRAMME
Ein Ringdiagramm für die Größenverteilung und ein Balkendiagramm der größten Typen.
Die acht größten einzeln, alles Weitere als ein Sammelposten.

ALTERSVERTEILUNG
Wie viel des Ordners ist von heute, aus der letzten Woche, aus dem letzten Jahr — und
wie viel liegt einfach nur da. Nach Anzahl und nach Volumen getrennt.

DUPLIKATSUCHE
Findet Dateien mit identischem Inhalt über ihre SHA-256-Prüfsumme, nicht über den
Namen. Zeigt, wie viel Platz frei würde, und öffnet jede Fundstelle im Finder.

KATEGORIEFILTER
Bilder, Dokumente, Videos, Audio, Code, Archive — Tabelle, Diagramme, Kennzahlen,
Export und Duplikatsuche folgen der Auswahl.

MENÜLEISTE
Ein optionales Symbol hält die Kennzahlen und die fünf größten Typen einen Klick
entfernt, ohne dass das Fenster offen sein muss.

EXPORT
Die Aufschlüsselung als CSV für die Tabellenkalkulation oder als JSON fürs Skript.


ZWEI DINGE, DIE ANDERS SIND

Es verlässt nichts Ihren Mac. Kein Konto, keine Analyse, keine Telemetrie, keine
Werbung. Die App stellt keine einzige Netzwerkanfrage — das lässt sich im
öffentlichen Quelltext nachlesen.

Es löscht nichts. Die Duplikatsuche zeigt Ihnen, was doppelt liegt, und öffnet es im
Finder. Was damit geschieht, entscheiden Sie.


Läuft auf Apple silicon und Intel. Benötigt macOS 14 Sonoma oder neuer.
```

## Neu in dieser Version / What's New (max. 4000)

```
• Scan und Duplikatsuche lassen sich jetzt abbrechen
• Die Duplikatsuche zeigt einen echten Fortschritt und benennt, wie viele Dateien
  wegen der Größenschwelle nicht verglichen wurden
• Hardlinks werden erkannt und nicht länger als rückgewinnbarer Platz gezählt
• Programme und andere Pakete zählen als ein Objekt statt als hunderte Einzeldateien
• Ordnerwahl direkt aus der Menüleiste
• Duplikatsuche und Menüleiste folgen jetzt ebenfalls dem Kategoriefilter
• Beschriftungen für Tabelle, Diagramme und Zeitachse — die App ist mit VoiceOver
  bedienbar
• Der zuletzt gescannte Ordner bleibt nach einem Neustart erhalten
• Läuft nun auch auf Intel-Macs
```

## Keywords (max. 100 Zeichen, kommagetrennt, ohne Leerzeichen nach dem Komma)

```
speicherplatz,festplatte,duplikate,ordner,analyse,aufräumen,dateien,größe,scanner,disk
```

## URLs

| Feld | Wert |
|---|---|
| Support-URL | `https://filescope.daumedia.lu` |
| Marketing-URL | `https://filescope.daumedia.lu` |
| Datenschutz-URL | `https://filescope.daumedia.lu/privacy` |

## App Privacy — das „Nutrition Label"

Die Antwort ist durchgehend dieselbe, und das ist ein Verkaufsargument:

> **Data Not Collected** — für jede einzelne Kategorie.

Begründung, falls die Prüfung nachfragt: Die App führt keine Konten, sendet nichts und
speichert nur eine Einstellung (Menüleistensymbol ja/nein) sowie ein Lesezeichen des
zuletzt gewählten Ordners. Beides bleibt lokal. Belegbar über den öffentlichen
Quelltext — `grep -rn "URLSession" Sources/` liefert nichts.

## Screenshots

In `store/screenshots/`, alle 2880×1800, JPEG ohne Alpha-Kanal:

| Datei | Zeigt |
|---|---|
| `1-liste.jpg` | Aufschlüsselung nach Dateityp mit Anteilen |
| `2-diagramme.jpg` | Ring- und Balkendiagramm |
| `3-zeitachse.jpg` | Altersverteilung nach Anzahl und Volumen |
| `4-duplikate.jpg` | Duplikatsuche mit rückgewinnbarem Platz |
| `5-videos.jpg` | Kategoriefilter am Beispiel Videos |

Neu erzeugen lassen sie sich mit `bash scripts/make-demo-folder.sh` — der Ordner, der
darauf zu sehen ist, entsteht dabei identisch. Wichtig, damit die Aufnahmen bei der
nächsten Version zusammenpassen und kein interner Pfad im Bild landet.

Reihenfolge in App Store Connect am besten so belassen: Die Tabelle erklärt sich von
selbst, die Diagramme wirken am stärksten, die Duplikatsuche ist das Kaufargument.

## Prüfungshinweise für Apple (App Review Information)

```
Die App benötigt keinerlei Anmeldung.

Zum Prüfen: Einen beliebigen Ordner per Drag-and-drop auf das Fenster ziehen oder
über "Choose Folder" auswählen. Der Downloads-Ordner eignet sich gut, weil dort meist
gemischte Dateitypen liegen.

Die App liest ausschließlich Metadaten (Name, Größe, Änderungsdatum). Nur die
Duplikatsuche liest Dateiinhalte, und zwar blockweise zum Bilden einer Prüfsumme; die
Inhalte werden nicht gespeichert und nicht übertragen.

Die App stellt keine Netzwerkverbindungen her.
```
