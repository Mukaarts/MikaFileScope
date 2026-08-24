# B09 · Automatische Updates — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> **Rekonstruktion, keine Vorgabe.** Beschrieben ist, was der Code am 2026-08-23 tut.
> Kriterien mit ⚠ beschreiben Verhalten, das fragwürdig aussieht, aber tatsächlich so
> stattfindet — sie sind absichtlich als Kriterium aufgenommen, damit `sdd-qa` sie
> reproduziert, und zur Klärung vorgelegt.

## Zweck

Die App prüft selbsttätig und auf Befehl, ob eine neuere Fassung vorliegt, lädt sie
herunter und installiert sie — ohne dass der Nutzer die Website besuchen muss. Sie ist
damit der einzige Weg, auf dem fremder Code auf den Rechner des Nutzers gelangt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B10 · Auslieferung und Signatur | `bestand` | Ohne signiertes, veröffentlichtes DMG und einen gepflegten `appcast.xml` hat der Update-Kanal nichts auszuliefern. B10 wird direkt nach B09 rückerfasst |

## User Stories

- **US-01** · Als Nutzer möchte ich benachrichtigt werden, wenn eine neuere Fassung
  vorliegt, damit ich Fehlerbehebungen bekomme, ohne die Website zu beobachten.
- **US-02** · Als Nutzer möchte ich selbst nachsehen können, ob ich aktuell bin, damit
  ich nicht auf die planmäßige Prüfung warten muss.
- **US-03** · Als Nutzer möchte ich sicher sein, dass nur Aktualisierungen des
  Herstellers installiert werden, damit der Update-Kanal kein Einfallstor ist.

## Nicht im Scope

- **Auslieferung über den Mac App Store** — Feature `01`. Dort ersetzt der Store diesen
  Mechanismus vollständig.
- **Erzeugen und Signieren des Update-Pakets** — gehört zu B10 (`build.sh`,
  `create-dmg.sh`, `sign_update`).
- **Rückstufung auf eine ältere Fassung.** Sparkle kann das nicht, und es ist nirgends
  vorgesehen.

## Akzeptanzkriterien

### Aufbau und Verfügbarkeit

- **AK-01** · Angenommen, die App wird gestartet, wenn der `AppDelegate` erzeugt wird,
  dann läuft ein Sparkle-Updater bereits (`startingUpdater: true`), ohne dass der Nutzer
  etwas tut.
- **AK-02** · Angenommen, die App läuft, wenn das Menü „Mika+FileScope" geöffnet wird,
  dann steht direkt unter „Über Mika+FileScope" der Eintrag **„Check for Updates…"**.
- **AK-03** · Angenommen, der Updater ist nicht prüfbereit, wenn das Menü geöffnet wird,
  dann ist „Check for Updates…" ausgegraut und nicht auslösbar.
- **AK-04** · Angenommen, die App wird zum allerersten Mal gestartet, wenn Sparkle
  hochfährt, dann fragt es den Nutzer, ob künftig automatisch geprüft werden soll — die
  Einwilligung wird eingeholt und nicht vorausgesetzt. *(Folgt daraus, dass
  `SUEnableAutomaticChecks` in der `Info.plist` fehlt.)*

### Prüfen und Installieren

- **AK-05** · Angenommen, der Nutzer wählt „Check for Updates…", wenn die Verbindung
  steht, dann lädt Sparkle die Datei unter `SUFeedURL` und wertet sie aus.
- **AK-06** · Angenommen, der Feed enthält einen Eintrag mit einer höheren
  `CFBundleVersion` **und** einer gültigen EdDSA-Signatur, wenn die Prüfung läuft, dann
  bietet Sparkle das Update an, lädt es und installiert es nach Bestätigung.
- **AK-07** · Angenommen, ein Eintrag im Feed trägt **keine** oder eine ungültige
  EdDSA-Signatur, wenn Sparkle ihn auswertet, dann wird er **nicht** installiert —
  `SUPublicEDKey` in der `Info.plist` erzwingt die Prüfung.
- **AK-08** · Angenommen, es besteht keine Internetverbindung, wenn der Nutzer prüfen
  lässt, dann meldet Sparkle einen Netzwerkfehler und die App läuft unverändert weiter.
- **AK-09** · Angenommen, der Nutzer hat den Kategoriefilter gesetzt oder ein Scan läuft,
  wenn eine Update-Prüfung stattfindet, dann bleibt der Anwendungszustand unberührt —
  die Prüfung hat keinerlei Wechselwirkung mit dem Scan.

### Übertragene Daten

- **AK-10** · Angenommen, eine Update-Prüfung findet statt, wenn die Anfrage an GitHub
  geht, dann werden **keine** Scandaten, Dateipfade oder Ordnernamen übertragen —
  übermittelt werden ausschließlich IP-Adresse, User-Agent und Zeitpunkt.
- **AK-11** · Angenommen, Sparkle prüft auf Updates, wenn die Anfrage gestellt wird, dann
  wird **kein Systemprofil** mitgesendet (Betriebssystem, Modell, CPU, Sprache), weil
  `SUEnableSystemProfiling` in der `Info.plist` nicht gesetzt ist.
- **AK-12** · Angenommen, der Feed wird abgerufen, wenn die Verbindung aufgebaut wird,
  dann geschieht das über **HTTPS**.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-13 bis AK-16** waren in der ersten Fassung dieser Spec als ⚠-Kriterien
aufgenommen, weil der Code sich so verhält. Am **2026-08-23** wurden alle vier als
Fehler eingestuft und in den *Fehlbestand* überführt — als FB-B09-01, -02, -03 und -11.

Die Nummern bleiben unbesetzt. Sie werden nicht neu vergeben, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** Diese vier Punkte sind keine zu bestätigenden Kriterien,
sondern eine Suchliste. Ein Bericht, der sie als „erfüllt" meldet, hat den Kanal für
funktionsfähig erklärt, obwohl er es nicht ist.

## Edge Cases

- **EC-01** · Feed nicht erreichbar (404, Netzwerkfehler) → Sparkle meldet den Fehler,
  die App läuft weiter. Kein Absturz, kein blockiertes Fenster.
- **EC-02** · Feed enthält ungültiges XML → Sparkle bricht die Prüfung mit Fehlermeldung
  ab.
- **EC-03** · Update wird während eines laufenden Scans installiert → die App wird
  beendet und neu gestartet; das Scanergebnis geht verloren, weil nichts persistiert
  wird (siehe `docs/datenmodell.md`).
- **EC-04** · Menüleisten-Modus aktiv und Fenster geschlossen → die App läuft weiter, der
  Menübefehl bleibt über die Menüleiste des Systems erreichbar.
- **EC-05** · Nutzer klickt „Check for Updates…" mehrfach schnell hintereinander →
  Sparkle verwaltet das intern; ein eigener Schutz besteht nicht.
- **EC-06** · Ad-hoc-signiertes Update wird angeboten → die Installation scheitert oder
  Gatekeeper blockiert den Neustart. Ungeprüft, weil nie ein Update ausgeliefert wurde.

## Fehlbestand

Nicht vorhanden, aus dem Code belegt. **Kein Kriterium** — `sdd-qa` prüft nichts davon
als bestanden, sondern nimmt es als Suchliste.

- **FB-B09-01 · Der Update-Feed ist leer.** *(War AK-13.)* `appcast.xml:1-9` enthält `<channel>` ohne
  ein einziges `<item>`. Folge: Der gesamte Mechanismus ist funktionslos. Kein
  installierter Client erfährt je von einer neuen Fassung — auch nicht von v2.0.0, das
  seit dem 2026-03-23 als GitHub-Release vorliegt.

- **FB-B09-02 · `CFBundleVersion` ist eingefroren.** *(War AK-14.)* `Resources/Info.plist:19` steht auf
  `1`, während `CFBundleShortVersionString` bereits `2.0.0` ist. Folge: Selbst ein
  gepflegter Feed würde nicht wirken, weil Sparkle die Build-Nummer vergleicht. Beide
  Befunde müssen zusammen behoben werden — jeder für sich reicht nicht.

- **FB-B09-03 · Ausgelieferte Kopien zeigen auf einen freigegebenen Kontonamen.** *(War AK-15.)*
  `build/Mika+FileScope.app/Contents/Info.plist` trägt `SUFeedURL` mit `Mukaarts`; das
  DMG des Releases v2.0.0 wurde vor der Umbenennung erzeugt. Der Kontoname ist über die
  GitHub-API nicht mehr auffindbar (HTTP 404) und damit **von Dritten registrierbar**.
  Folge: Wer den Namen registriert und ein Repository `MikaFileScope` mit einem Branch
  `master` anlegt, kontrolliert den Update-Feed jeder installierten Kopie.
  **Was der EdDSA-Schlüssel abfängt:** Ein fremdes Update kann nicht installiert werden
  (AK-07). **Was er nicht abfängt:** Der Angreifer erfährt die IP-Adressen aller
  prüfenden Installationen und kann über die Release Notes, die Sparkle anzeigt, eigene
  Inhalte einblenden. Der Befund verliert seine Bedeutung erst, wenn keine Kopie mit der
  alten URL mehr im Umlauf ist — und genau das lässt sich über den Update-Kanal nicht
  erreichen, weil er nicht funktioniert.

- **FB-B09-04 · Kein Weg, veraltete Installationen zu erreichen.** Aus FB-B09-01 bis
  FB-B09-03 zusammen folgt: Es gibt derzeit **keine** Möglichkeit, eine ausgelieferte
  Kopie auf eine neue Feed-URL umzustellen. Die Reparatur erfordert eine manuelle
  Neuinstallation durch den Nutzer — und einen Hinweis darauf auf der Website.

- **FB-B09-05 · `automaticallyChecksForUpdates` wird nie benutzt.**
  `SparkleUpdater.swift:17-20` definiert Lese- und Schreibzugriff, aufgerufen wird
  keiner. Folge: toter Code; es gibt keine Einstellung in der Oberfläche, mit der der
  Nutzer die automatische Prüfung nachträglich ändern könnte — nur den Erstdialog.

- **FB-B09-06 · `lastUpdateCheckDate` wird nie gelesen.**
  `SparkleUpdater.swift:30-32`. Folge: toter Code; der Nutzer erfährt nirgends, wann
  zuletzt geprüft wurde.

- **FB-B09-07 · Kein Delegate, keine Fehlerbehandlung.**
  `SparkleUpdater.swift:23-27` übergibt `updaterDelegate: nil` und
  `userDriverDelegate: nil`. Folge: Fehlschläge sind nur sichtbar, soweit Sparkles
  Standardoberfläche sie zeigt; sie werden nirgends protokolliert oder ausgewertet.

- **FB-B09-08 · Der Ablauf ist nie erprobt worden.** Es existiert kein Testfall, kein
  Testfeed und keine Notiz über einen durchgeführten Update-Durchlauf. Folge: Ob der
  Kanal funktioniert, ist unbekannt — und das PRD führt genau diesen Nachweis als
  Erfolgskriterium.

- **FB-B09-09 · Der private Signaturschlüssel hat keine dokumentierte Sicherung.**
  Vorhanden im Schlüsselbund (geprüft am 2026-08-23), aber nirgends vermerkt, wo eine
  Kopie liegt. Folge: Bei Verlust ist der Update-Kanal für alle bestehenden
  Installationen endgültig tot — siehe DZ-05 in `docs/datenschutz.md`.

- **FB-B09-11 · Der Feed liegt auf einem divergierten Branch.** `Resources/Info.plist:28`
  verweist auf `…/master/appcast.xml`, gearbeitet wird auf `main`. Beide Branches
  existieren und sind auseinandergelaufen — 4 Commits nur auf `main`, 3 nur auf
  `master`; die Fassung auf `master` nennt im `<link>` noch `Mukaarts`. Folge: Wer den
  Feed auf `main` pflegt, ändert nichts an dem, was die Clients lesen. *(War AK-16, am
  2026-08-23 als Fehler eingestuft.)*

- **FB-B09-10 · Versionsangabe in `CLAUDE.md` veraltet.** Dort steht „Sparkle 2.6+",
  `Package.resolved` und das gebaute Bundle weisen **2.9.0** aus. Folge: geringfügig,
  aber die Dokumentation nennt eine Version, die nicht im Einsatz ist.

## Sofortmaßnahme — beschlossen am 2026-08-23

**Den alten Kontonamen `Mukaarts` sichern, bevor es jemand anderes tut.**

**Zur Einordnung:** `Mukaarts` und `daumedia` sind **dasselbe Konto** — es wurde
umbenannt (Commit `c47eb63`). Der alte Name ist damit aber nicht reserviert, sondern bei
GitHub unbesetzt (`gh api users/Mukaarts` → 404). Dass die alte Adresse heute noch
antwortet, liegt allein an der Repository-Weiterleitung
`Mukaarts/MikaFileScope → daumedia/MikaFileScope`. Diese endet, sobald jemand den Namen
registriert und dort ein Repository gleichen Namens anlegt.

Das ist die einzige Maßnahme gegen FB-B09-03, die **sofort** wirkt: Alle anderen —
Feed reparieren, Version hochzählen, Website-Hinweis — erreichen die bereits
ausgelieferten Kopien nicht, denn genau deren Update-Kanal ist ja defekt.

| Schritt | Was zu tun ist |
|---|---|
| 1 | Auf github.com prüfen, ob `Mukaarts` tatsächlich frei ist (die API antwortet mit 404, das ist ein starkes, aber kein abschließendes Indiz) |
| 2 | Ist er frei: als zweites Konto registrieren und nicht weiter benutzen |
| 3 | Ein leeres Repository `MikaFileScope` anlegen, damit die Weiterleitung nicht durch ein fremdes Repository ersetzt werden kann |
| 4 | Im Betriebshandbuch vermerken, dass dieses Konto nicht gelöscht werden darf |

Diese Maßnahme ändert keinen Code und gehört deshalb **nicht** in den Fehlerauftrag an
`sdd-build`, sondern in den Betrieb (`sdd-betrieb`). Sie ist unabhängig von der QA
auszuführen — je früher, desto besser.

## Offene Fragen

- **OF-01** · ~~Läuft der Direktvertrieb nach dem App-Store-Wechsel weiter?~~
  **Entschieden am 2026-08-23: ja, beide Kanäle parallel.** Die Store-Variante läuft
  sandboxed ohne Sparkle, die Direktvariante mit. B09 bleibt damit dauerhaft in Betrieb
  und wird repariert, nicht abgekündigt.
- **OF-02** · ~~Wie werden bestehende Installationen mit der `Mukaarts`-URL erreicht? Über den Update-Kanal gar nicht~~
  **Teilweise gelöst am 2026-08-24.** Der Zweig `master` — den ausgelieferte Kopien abfragen — trägt jetzt denselben gepflegten Feed wie `main`, live nachgeprüft über die alte Adresse. Damit erreicht ein künftiges Release die Altbestände. Offen bleibt allein die Sicherung des Kontonamens, weil die Weiterleitung daran hängt.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Eigener Update-Mechanismus oder Sparkle? | Sparkle 2.9 | Auf macOS der Standard; EdDSA-Signaturprüfung und Installationslogik sind erprobt. Im Mika+-Ökosystem identisch zu MikaGrid und MikaScreenSnap |
| 2 | Wo liegt der Feed? | GitHub raw, Branch `master` | Kein eigener Server nötig, kostenlos, versioniert. Nachteil: Branch- und Kontoname sind Teil der URL — genau daraus entstanden FB-B09-03 und AK-16 |
| 3 | Signaturprüfung erzwingen? | Ja, `SUPublicEDKey` gesetzt | Ohne sie wäre ein übernommener Feed unmittelbar ausnutzbar. Diese Entscheidung ist der Grund, warum FB-B09-03 ein hoher und kein kritischer Befund ist |
| 4 | Automatische Prüfung voreinstellen? | Nein — Sparkle fragt beim ersten Start | `SUEnableAutomaticChecks` fehlt bewusst oder zufällig; das Ergebnis ist eine eingeholte Einwilligung. Grund nicht rekonstruierbar |
| 5 | Sind AK-13, -14, -16 gewolltes Verhalten? | **Nein, alle drei sind Fehler** (2026-08-23) | Jeder für sich macht den Kanal wirkungslos; zusammen erklären sie, warum seit v2.0.0 kein Nutzer ein Update gesehen hat |
| 6 | Wie mit dem freigegebenen Kontonamen umgehen (AK-15)? | **Fehler — und den Namen vorsorglich sichern** (2026-08-23) | Die Signaturprüfung verhindert die Installation fremder Updates, nicht aber die Kontrolle über den Feed. Registrieren ist billiger als jede Gegenmaßnahme danach |
| 7 | Direktvertrieb nach dem Store-Start? | **Beide Kanäle parallel** (2026-08-23) | B09 wird repariert und bleibt in Betrieb — nicht als Übergangslösung, sondern dauerhaft |
