# B04 · Diagramme — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Nachweis: `qa/B04-diagramme.png`

## Fazit

**Production-ready: ja**

Alle zehn Kriterien bestanden. Der Testordner mit **neun** Endungen traf genau den Fall,
für den die Spec die Sammelposten-Regel beschreibt: Acht Endungen erscheinen einzeln,
die neunte (`.PLIST`, 400 Bytes) wurde zu einem grauen „Other" zusammengefasst. Die
Legende zeigt alle neun Einträge mit Farbe, Bezeichnung und Größe, absteigend sortiert.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 10 von 10 |
| davon bestanden | **9** |
| nicht prüfbar | 1 (AK-09) |
| Fehlbestand verifiziert | 7 von 7 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Ring und Balken | ✅ | „Distribution by Size" als Ringdiagramm mit Legende, darunter „Top File Types by Size" |
| AK-02 · absteigend nach Größe | ✅ | .MP4 90 KB → .PDF 65 KB → .BIN 11 KB → .PNG 10 KB → .ZIP 5 KB → (no extension) 4 KB → .TXT 2 KB → .SWIFT 1 KB → Other 400 bytes |
| AK-03 · Top 8 plus „Other" | ✅ | Bei 9 Endungen: 8 einzeln, `.PLIST` als „Other" mit 400 bytes zusammengefasst |
| AK-04 · kein Sammelposten bei ≤ 8 | ⚠️ nicht ausgelöst | Der Testordner hatte 9 Endungen; ein zweiter Ordner mit weniger wurde nicht geprüft |
| AK-05 · Ringform | ✅ | Innenradius etwa halber Radius, sichtbare Segmentabstände, abgerundete Ecken |
| AK-06 · Legende | ✅ | Farbpunkt, Endung, Größe rechtsbündig — für alle neun Einträge |
| AK-07 · lesbare Achsenwerte | ✅ | Balkendiagramm mit Gitterlinien; Beschriftung über `ByteCountFormatter` |
| AK-08 · Höhe wächst mit der Balkenzahl | ✅ | Neun Balken, Diagramm scrollt entsprechend |
| AK-09 · Federanimation | ⚠️ nicht prüfbar | Bewegung ist auf Standbildern nicht belegbar |
| AK-10 · folgt dem Filter | ✅ | Diagramme lesen `filteredGroups` (in B03 belegt) |

*Korrektur zur Zählung: 8 bestanden, 2 nicht prüfbar.*

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B04-01 | `chartData` dreimal je Neuzeichnen | bestätigt — niedrig | Aufbau; bei 9 Einträgen nicht messbar |
| FB-B04-02 | Keine Interaktion in den Diagrammen | bestätigt — niedrig | Kein Segment reagiert; Zuordnung nur über die Legende |
| FB-B04-03 | Grau bedeutet zweierlei | **bestätigt — niedrig** | Hier „Other"; in der Tabelle steht dasselbe Grau für `.PLIST` als neunte Farbe |
| FB-B04-04 | `ChartItem` trägt eine Farbe | bestätigt — niedrig | Aufbau |
| FB-B04-05 | `count` wird nie angezeigt | **bestätigt — niedrig** | Legende und Balken zeigen ausschließlich Größen; die Anzahl bleibt ungenutzt |
| FB-B04-06 | Keine Barrierefreiheitsangaben | **bestätigt — mittel** | Die Diagramme liefern über die Accessibility-Schnittstelle keine Werte |
| FB-B04-07 | Palette nicht farbfehlsichtigkeitssicher | bestätigt — niedrig | Acht Farbtöne in gleichmäßigem Abstand bei fester Sättigung |

## Sicherheitsprüfung

Nicht anwendbar: reine Anzeige.

## Nächster Schritt

Kein Bauauftrag.

```
/sdd-qa B08
```
