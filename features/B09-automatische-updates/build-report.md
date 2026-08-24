# B09 · Automatische Updates — Abschlussbericht der Reparatur

Stand: 2026-08-24 · Eingang: **Fehlerauftrag** aus `qa-report.md` vom 2026-08-23
Zweig: `fix/b09-update-kanal` · Status: `building` → Übergabe an `/sdd-qa B09`

## 1 · Umgesetzt

**Alle fünf Fehler bearbeitet, vier davon vollständig behoben und einzeln erneut
reproduziert.** Der Update-Kanal trägt wieder: Ein Bundle mit Build 2 fragt den
reparierten Feed ab und bekommt korrekt **kein** Update angeboten; derselbe Feed mit
einem Nachfolger-Eintrag (Build 3) löst den Dialog „Mika+FileScope 2.0.1 is now
available—you have 2.0.0" aus. Die vier zuvor roten Tests sind grün, alle acht laufen
in 0,002 Sekunden durch.

| Fehler | Grad | Ergebnis |
|---|---|---|
| BUG-01 · Kanal erreicht keinen Nutzer | hoch | **behoben** — Feed, Build-Nummer und Zweig gemeinsam |
| BUG-02 · Ausgelieferte Kopien fragen `Mukaarts` ab | hoch | **teilweise** — der Code ist korrigiert, die Altbestände erreicht nur ein Release |
| BUG-03 · Feed-Adresse lokal umbiegbar | mittel | **behoben** — Angriff aus dem Bericht greift nicht mehr |
| BUG-04 · Systemsprache nicht dokumentiert | niedrig | **behoben** |
| BUG-05 · Build scheitert nach Ortswechsel | niedrig | **behoben** |

**Geänderte Dateien:** `appcast.xml`, `Resources/Info.plist`,
`Sources/SparkleUpdater.swift`, `scripts/build.sh`, `docs/datenschutz.md`,
`Tests/UpdateChannelTests/UpdateChannelTests.swift`.

**Abgedeckte Kriterien:** AK-01 bis AK-12 wurden nach der Reparatur erneut durchgegangen
(Selbsttest); keines hat sich verschlechtert. AK-06 und AK-07 sind durch die beiden
Feed-Durchläufe belegt, AK-12 zusätzlich durch einen Test.

## 2 · Offene Akzeptanzkriterien

Kein Akzeptanzkriterium ist offen — sie waren schon in der QA alle bestanden. Offen ist
etwas anderes, und zwar der schwerere Teil von BUG-02:

> **BUG-02 (ausgelieferte Kopien fragen `Mukaarts` ab) — nicht durch Code lösbar.**
> Die Quelle ist korrekt, aber jede installierte Kopie von v2.0.0 trägt die alte Adresse
> in ihrer eigenen `Info.plist`. Erreichbar sind diese Kopien nur über die noch
> bestehende GitHub-Weiterleitung von `Mukaarts` nach `daumedia` — und nur, solange
> niemand den freigegebenen Kontonamen registriert.
> **Nachweis, dass es nicht am Code liegt:** Das frisch gebaute Bundle trägt
> `https://raw.githubusercontent.com/daumedia/MikaFileScope/main/appcast.xml`
> (`PlistBuddy -c "Print :SUFeedURL"`); das ausgelieferte DMG trägt `Mukaarts`
> (dasselbe Kommando auf dem gemounteten Abbild).
> **Nötig sind drei Schritte, alle außerhalb dieses Skills:**
> 1. Kontonamen `Mukaarts` sichern (Betrieb — siehe *Sofortmaßnahme* in `spec.md`)
> 2. Ein Übergangs-Release veröffentlichen, dessen Bundle die korrigierte Adresse trägt
> 3. Die neue `appcast.xml` **auch auf `master`** ablegen, weil Altbestände diesen Zweig
>    abfragen — sonst sehen sie das Übergangs-Release nie

> **Der reparierte Feed wirkt noch nicht.** `appcast.xml` liegt auf dem Feature-Zweig.
> Erst wenn er auf `main` liegt, sehen echte Clients ihn. Belegt: Der Selbsttest gegen
> den produktiven Feed meldet weiterhin „You're up to date" — der leere Feed ist dort
> noch in Kraft.

## 3 · Getroffene Annahmen

**Der appcast-Eintrag beschreibt das ausgelieferte v2.0.0 mit `sparkle:version=1`, nicht
eine künftige Version.** Der Testbericht ließ offen, welchen Stand der erste Eintrag
tragen soll. Ein Eintrag mit einer höheren Nummer hätte allen bestehenden Installationen
ein „Update" auf dieselbe Version angeboten, die sie bereits haben — und weil das
gelieferte Bundle wieder Build 1 gewesen wäre, endlos erneut. Der Eintrag bildet deshalb
ab, was tatsächlich veröffentlicht ist. Test 1 belegt, dass daraus kein Update entsteht.

**`CFBundleVersion` wurde auf `2` gesetzt, die Kurzversion blieb `2.0.0`.** Eine
fortlaufende Build-Nummer, die mit jedem Release um eins steigt, ist die einfachste Form,
die Sparkles Vergleich verlangt. Welche Kurzversion das nächste Release trägt (2.0.1?
2.1.0?), ist eine Release-Entscheidung und gehört zu `sdd-deploy`.

**Der Feed-Zweig wurde auf `main` umgestellt statt `master` weiterzupflegen.** Die Spec
nennt `master` als „ungepflegt"; `main` ist laut `CLAUDE.md` der Hauptzweig. Die
Konsequenz für Altbestände steht oben unter *Offene Punkte* — sie war beim Umstellen
nicht vermeidbar, nur benennbar.

**Ein Test wurde korrigiert, nicht der Code.** `test_FB0911_feedZeigtAufDenGepflegtenZweig`
verglich gegen den ausgecheckten Zweig und wurde auf jedem Feature-Zweig rot. Er
vergleicht jetzt gegen `main`. Das war ein Mangel meiner eigenen Prüfung aus der QA, kein
Befund am Projekt.

## 4 · Systemweite Änderungen

Alles, was über B09 hinaus wirkt:

| Änderung | Wirkt auf | Anmerkung |
|---|---|---|
| `scripts/build.sh` prüft den Cache-Pfad und bereinigt selbsttätig | **B10** und jeden künftigen Bau | Gehört fachlich zu B10; hier behandelt, weil BUG-05 den Bau der Prüfumgebung blockierte |
| `docs/datenschutz.md` nennt `Accept-Language` und führt den Abruf im Wortlaut | **projektweit** | Grundlagendokument, betrifft jede künftige Aussage über Datenübertragung |
| `Resources/Info.plist`: `CFBundleVersion` 1 → 2 | **B10**, jedes künftige Release | Ab jetzt muss die Nummer bei jedem Release steigen — sonst kehrt BUG-01 zurück |
| `Tests/UpdateChannelTests/` + Testziel in `Package.swift` | **projektweit** | Entstand in der QA; `swift test` ist ab jetzt Teil der Verifikation und läuft in 0,002 s |

### Zwei Funde beim Bauen, die nicht im Auftrag standen

Nach Regel 1 nicht mitgebaut, sondern hier gemeldet:

**Das Nachsignieren eines ad-hoc signierten Bundles mit `codesign --deep` allein macht es
startunfähig.** Beim Bau der Prüfumgebung scheiterte die Testkopie mit
`dyld: Library not loaded … different Team IDs`, weil das eingebettete Sparkle-Framework
seine frühere Signatur behielt. Erst das vollständige Inside-out-Signieren — wie
`scripts/build.sh` es tut — machte sie lauffähig. Das bestätigt **FB-B10-07** aus einer
neuen Richtung und ist als offene Frage in `features/B10-auslieferung-signatur/spec.md`
vermerkt.

**Die Reparatur von BUG-03 macht den Prüfaufbau der QA unbrauchbar.** Der Weg, den Feed
über `defaults write` umzubiegen, war das Werkzeug, mit dem AK-06 und AK-07 belegt
wurden — und genau den schließt `FeedURLProvider` jetzt. Künftige Prüfungen brauchen
stattdessen eine Bundle-Kopie mit geänderter `Info.plist`, vollständig inside-out
signiert. Der Weg ist im Testbericht dokumentiert.

## Nächster Schritt

```
/sdd-qa B09
```

Zu prüfen sind vorrangig: die beiden Feed-Durchläufe (kein Update bei Build 1, Update bei
Build 3), der abgewehrte Umbiegungsversuch aus BUG-03, und ob AK-01 bis AK-12 nach der
Änderung an `SparkleUpdater` unverändert bestehen.

**`approved` setzt dieser Skill nicht.** Der Status bleibt `building`.
