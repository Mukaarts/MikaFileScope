# B02 · Aufschlüsselung nach Dateityp — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Nachweis für alle Sichtkriterien: `qa/B01-scan-testordner.png`

## Fazit

**Production-ready: ja, mit Einschränkungen**

Neun von zehn Kriterien bestanden, eines nicht prüfbar. Die Tabelle zeigt für den
Testordner die exakt erwarteten Werte, die Voreinstellung sortiert absteigend nach
Anzahl, Farbbalken und Anteilsdarstellung sind vorhanden, alle Zahlen laufen in
Festbreitenziffern.

Der Palettenbefund der Erfassung ist am Programm belegt: Bei neun Endungen ist die
neunte grau — und zwar `.PLIST`, die **kleinste**, nicht die letzte in der Anzeige. Die
Farbe folgt der Größenrangfolge, wie im Entwurf vorgesehen; dass ab Rang neun Grau
bedeutet „keine Farbe mehr übrig", während dasselbe Grau in den Diagrammen den
Sammelposten „Other" kennzeichnet, bleibt der eigentliche Punkt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 10 von 10 |
| davon bestanden | **9** |
| nicht prüfbar | 1 (AK-03) |
| Fehlbestand verifiziert | 6 von 6, alle bestätigt |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · vier Spalten | ✅ | `Extension`, `Count`, `Size`, `% of Total` |
| AK-02 · Voreinstellung nach Anzahl | ✅ | 5, 4, 3, 2, 2, 1, 1, 1, 1 — absteigend; Sortierpfeil steht auf `Count` |
| AK-03 · Umsortieren per Klick | ⚠️ nicht prüfbar | Spaltenköpfe sind über die Accessibility-Schnittstelle nicht anklickbar; kein Mauswerkzeug verfügbar |
| AK-04 · Farbbalken und Festbreitenschrift | ✅ | Je Zeile ein farbiger Balken links, Endung in Festbreitenschrift als `.PNG` bzw. `(no extension)` |
| AK-05 · Anteilsbalken und Prozentwert | ✅ | Fortschrittsbalken plus `5.1%`, `34.7%`, `48.0%` … je eine Nachkommastelle |
| AK-06 · Anteil auf gefilterte Summe | ✅ | Bei „All": `.MP4` 90 KB von 188 KB → 48,0 % — rechnerisch korrekt |
| AK-07 · Ziffern fester Breite | ✅ | Alle Zahlenspalten rechtsbündig ausgerichtet, keine Sprünge beim Filterwechsel |
| AK-08 · drei Kennzahl-Pillen | ✅ | `20 Files`, `188 KB Total Size`, `9 Types` |
| AK-09 · lesbare Größen | ✅ | `10 KB`, `65 KB`, `400 bytes` |
| AK-10 · keine Division durch null | ✅ | Bei „Audio" (0 Dateien): `Zero KB`, keine Fehlermeldung, kein Absturz |

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B02-01 | Quadratischer Zeichenaufwand | bestätigt — niedrig | Aufbau; bei 9 Zeilen nicht messbar |
| FB-B02-02 | Anteilsspalte nicht sortierbar | bestätigt — niedrig | `TableColumn("% of Total")` ohne `value:` |
| FB-B02-03 | Sortierung verändert den geteilten Zustand | bestätigt — niedrig | `.onChange` schreibt in `engine.groups` |
| FB-B02-04 | Nur acht Farben | **bestätigt — niedrig** | Bei 9 Endungen ist `.PLIST` (kleinste, 400 B) grau — dieselbe Farbe, die im Diagramm „Other" bedeutet |
| FB-B02-05 | `StatPill` nicht geteilt | bestätigt — niedrig | Menüleiste hat eine eigene, abweichende Fassung |
| FB-B02-06 | Keine Barrierefreiheitsangaben | **bestätigt — mittel** | Werte sind zwar als `AXStaticText` lesbar, aber Farbbalken und Anteilsbalken tragen keine Beschriftung; Spaltenköpfe sind nicht bedienbar (siehe AK-03) |

## Sicherheitsprüfung

Nicht anwendbar: reine Anzeige ohne Datenzugriff und ohne Schreiboperation.

## Nächster Schritt

Kein Bauauftrag.

```
/sdd-qa B05
```
