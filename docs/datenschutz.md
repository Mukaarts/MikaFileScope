# Mika+FileScope — Datenschutz

Stand: 2026-08-23 · Stufe: **A — kein Personenbezug im Sinne einer Verarbeitung**
Ergänzt in Phase 1 der Erfassung. Grundlage: `~/.claude/sdd/sicherheit.md`.

Bei Stufe A verkürzt sich der Katalog auf die Abschnitte *Missbrauch und Kosten* und
*Geheimnisse*. Die übrigen werden hier trotzdem beantwortet — mit „trifft nicht zu,
weil …", nicht durch Weglassen. Eine Frage, die niemand gestellt hat, wird auch von
niemandem geprüft.

## Nachweis statt Behauptung

Die Aussage „die App sendet nichts" ist nachprüfbar und wurde geprüft:

```bash
grep -rnE 'URLSession|NSURLConnection|Network\.|CFStream|dataTask|https?://' Sources/*.swift
# → keine Treffer (2026-08-23)
```

**Der eigene Code enthält keinen einzigen Netzwerkaufruf.** Kein `URLSession`, keine
URL-Konstante, keine Analytics-Bibliothek. Die einzige Verbindung baut Sparkle auf —
eine eingebundene Fremdbibliothek, nicht dieser Code.

Das deckt sich mit der Zusage auf der Website („No account, no analytics, no telemetry.
The app itself makes no network requests") und ist damit eine der wenigen Marketing-
Aussagen des Projekts, die der Code vollständig einlöst.

## 1 · Personenbezogene Daten

**Welche personenbezogenen Daten berührt die App?**

Keine im üblichen Sinn — kein Name, keine E-Mail, keine Adresse, kein Konto. Berührt
werden aber Daten, die *dem Nutzer selbst* gehören und die auf einem fremden Rechner
sehr wohl personenbeziehbar wären:

| Datenart | Woher | Wohin | Verbleib |
|---|---|---|---|
| Dateipfade des gewählten Ordners | `FileManager.enumerator` | Arbeitsspeicher | bis Neuscan oder Beenden |
| Dateinamen und Endungen | ebenda | Arbeitsspeicher, Anzeige | ebenda |
| Dateigrößen und Änderungsdaten | `URLResourceValues` | Arbeitsspeicher, Diagramme | ebenda |
| **Dateiinhalte** | `FileHandle`, nur bei der Duplikatsuche | SHA-256-Hash, blockweise | jeder 1-MB-Block wird nach dem Hashen verworfen |
| macOS-Benutzername | implizit im Ordnerpfad | Anzeige und **JSON-Export** | im Export dauerhaft |

**Besondere Kategorien?** Nicht als Verarbeitung. Zu bedenken ist trotzdem: Der Scanner
läuft über beliebige Ordner. Wer `~/Documents/Arztberichte` scannt, sieht die Dateinamen
in der Oberfläche — sie werden weder gespeichert noch übertragen, stehen aber auf dem
Bildschirm und potenziell in einem Export.

**Landen Daten in Logs?** Nein. Es gibt keine Logging-Aufrufe, kein `print`, kein
`os_log` im gesamten Quelltext. Der einzige Text, der einen Pfad enthalten kann, ist die
Fehlermeldung `"Cannot access folder: \(url.path)"` — sie erscheint im Warnhinweis und
wird nirgends geschrieben.

## 2 · Weitergabe an externe Dienste

Drei Dienste sind beteiligt, keiner davon bekommt Nutzerdaten aus dem Scan.

| Dienst | Wofür | Was tatsächlich übertragen wird | Ort |
|---|---|---|---|
| **GitHub** (raw.githubusercontent.com, ausgeliefert über Fastly) | Sparkle holt `appcast.xml` und lädt das DMG | HTTP-Anfrage mit **IP-Adresse**, User-Agent (`Mika+FileScope/2.0.0 Sparkle/2.9.0`), **Systemsprache** (`Accept-Language`) und Zeitpunkt. **Keine** Scandaten, keine Dateipfade, kein Anfragerumpf | USA |
| **Vercel** | Hosting von filescope.daumedia.lu | Beim Seitenbesuch: IP-Adresse, User-Agent, Referrer — normale Server-Zugriffsdaten. Betrifft die Website, nicht die App | global/USA |
| **Apple** (künftig, Feature `01`) | App Store, Auslieferung und Aktualisierung | Kaufvorgang und Gerätedaten laufen dann über Apple, nicht über uns | — |

**Das ist die Präzisierung, die auf der Website fehlt:** „Everything stays local" stimmt
für die Scandaten uneingeschränkt. Beim Update-Check erfährt GitHub jedoch die
IP-Adresse und die installierte Version — technisch unvermeidbar für jeden Abruf über
das Netz, aber es ist eine Übermittlung an einen Dritten in den USA und sollte so
benannt werden.

Der vollständige Abruf wurde am 2026-08-23 mit einem mitschreibenden Server abgefangen
und besteht aus einer einzigen Zeile plus Kopfzeilen — ohne Rumpf, ohne Parameter:

```
GET /appcast.xml
Accept: application/rss+xml,*/*;q=0.1
Accept-Language: de-DE,de;q=0.9
Accept-Encoding: gzip, deflate
User-Agent: Mika+FileScope/2.0.0 Sparkle/2.9.0
```

**Systemprofil-Daten:** Sparkle kann Betriebssystemversion, Modell, CPU und Sprache
mitsenden. Das steuert `SUEnableSystemProfiling`. Der Schlüssel steht **nicht** in der
`Info.plist`; die Voreinstellung ist *aus*. Es wird also kein Systemprofil übertragen —
festgehalten, damit es beim nächsten Anfassen der Plist nicht versehentlich angeschaltet
wird.

**Automatische Prüfung:** `automaticallyChecksForUpdates` wird im Code nie gesetzt.
Sparkle fragt den Nutzer daher beim ersten Start, ob automatisch geprüft werden soll —
die Einwilligung wird eingeholt, nicht vorausgesetzt.

**AV-Verträge:** Nicht erforderlich. Keiner der Dienste verarbeitet Daten in unserem
Auftrag; GitHub und Vercel sind Hoster für öffentlich abrufbare Dateien.

## 3 · Zugriff

Trifft nicht zu, weil es keine Mehrbenutzerumgebung gibt. Es existieren keine Konten,
keine Rollen, keine Datensätze mit Eigentümern und damit auch kein IDOR-Risiko.

Der Zugriff auf das Dateisystem ist die einzige Zugriffsfrage — und die beantwortet
heute das Betriebssystem:

| Heute | Nach Feature `01` (Sandbox) |
|---|---|
| Sandbox **aus**. Die App darf lesen, was der angemeldete Nutzer lesen darf. macOS fragt bei geschützten Orten (Schreibtisch, Dokumente, Downloads) selbst nach Erlaubnis | `com.apple.security.files.user-selected.read-only` — Zugriff nur auf den ausdrücklich gewählten Ordner, erteilt über Powerbox |
| `startAccessingSecurityScopedResource()` ist wirkungslos (FB-12) | derselbe Aufruf wird zur Notwendigkeit, dazu Security-Scoped Bookmarks für „Rescan" nach Neustart (DM-03) |

**Nur Lesezugriff:** Die App öffnet Dateien ausschließlich lesend (`FileHandle(forReadingFrom:)`).
Geschrieben wird an genau einer Stelle — die Exportdatei, an einen vom Nutzer im
Systemdialog gewählten Ort. Es gibt keinen Code-Pfad, der eine fremde Datei verändert
oder löscht.

## 4 · Missbrauch und Kosten

Für Stufe A einer der beiden Pflichtabschnitte.

**Kosten pro Aufruf:** keine. Es gibt kein KI-Modell, keinen E-Mail-Versand, keine
kostenpflichtige API. Der Betreiber kann durch Nutzung der App keine Rechnung erzeugen —
Rate Limits sind aus Kostengründen gegenstandslos.

**Ressourcenverbrauch auf dem Gerät des Nutzers** ist dagegen sehr wohl unbegrenzt:

| Vorgang | Grenze | Bewertung |
|---|---|---|
| Ordnerscan | keine — Tiefe und Dateizahl unbeschränkt | `scannedURLs` wächst linear mit der Dateizahl (DM-02) |
| Duplikatsuche | keine Obergrenze, kein Abbruch | liest jede Kandidatendatei **vollständig**; bei 50 GB Kandidaten werden 50 GB gelesen |
| Abbruch eines laufenden Vorgangs | **nicht vorgesehen** | Weder Scan noch Hashlauf lassen sich stoppen; das Blatt zeigt einen Fortschritt, der nicht berechnet wird (FB-07) |

Das ist kein Datenschutz-, sondern ein Verfügbarkeitsthema — es gehört hierher, weil der
Katalog danach fragt und die Antwort „keine Grenze" lautet.

**Uploads:** trifft nicht zu, es gibt keine.

**Eingabeprüfung:** Der einzige externe Eingang ist der abgelegte Ordner. `handleDrop`
prüft, ob es sich um ein Verzeichnis handelt, und verwirft alles andere still (AS-03).
Symbolische Verknüpfungen werden vom Enumerator standardmäßig nicht verfolgt.

## 5 · Löschen und Auskunft

Trifft nicht zu — es gibt kein Konto und keine serverseitigen Daten. Der Vollständigkeit
halber, weil der Katalog es verlangt:

| Frage | Antwort |
|---|---|
| Kann der Nutzer sein Konto löschen? | Es gibt keins |
| Was bleibt nach der Deinstallation? | Der `UserDefaults`-Eintrag `showMenubar` und Sparkles eigene Schlüssel in der App-Domain. Selbst exportierte CSV/JSON-Dateien bleiben, wo der Nutzer sie abgelegt hat |
| Kann der Nutzer seine Daten exportieren? | Ja — CSV und JSON sind genau das, und sie sind das einzige, was es zu exportieren gibt |
| Aufbewahrungspflichten? | Keine |

## 6 · Geheimnisse

Der zweite Pflichtabschnitt für Stufe A.

| Schlüssel | Wo | Art | Bewertung |
|---|---|---|---|
| `SUPublicEDKey` | `Resources/Info.plist` | **öffentlicher** EdDSA-Schlüssel | Gehört dorthin. Sparkle prüft damit die Signatur eines Updates |
| EdDSA-**privater** Schlüssel | macOS-Schlüsselbund des Entwicklers | privat | Nicht im Repository. Ohne ihn kann kein gültiges Update signiert werden — geht er verloren, ist der Update-Kanal für alle bestehenden Installationen unwiederbringlich tot |
| Signaturzertifikate | heute keine (Ad-hoc-Signatur) | — | Mit Feature `01` kommen Developer-ID- und Store-Zertifikate hinzu |

**Steht etwas Echtes im Repository?** Es gibt keine `.env`, keine
`Secrets.xcconfig`, keine API-Schlüssel. Der einzige Schlüsselwert im Repo ist der
öffentliche Sparkle-Schlüssel, und der ist zur Veröffentlichung bestimmt.

**Ein Hinweis zur Sicherung:** Der private EdDSA-Schlüssel ist der einzige unersetzliche
Wert des Projekts. Ein verlorener Signaturschlüssel bedeutet, dass jeder Nutzer die App
manuell neu installieren muss — es gibt keinen Weg, ihn über den bestehenden Kanal zu
ersetzen.

## Was für den App Store noch fehlt

Feature `01` macht aus diesem Dokument eine Pflicht, nicht eine Fleißarbeit:

| Anforderung | Stand |
|---|---|
| Öffentlich erreichbare Datenschutzerklärung unter einer festen URL | **fehlt** — die Website hat eine Überschrift „Privacy & Security", aber keine eigene Seite |
| App Privacy Details („Nutrition Label") im App Store Connect | noch nicht ausgefüllt. Bei Stufe A wäre die Antwort durchgehend *Data Not Collected* — ein starkes Verkaufsargument, das derzeit ungenutzt bleibt |
| Erklärung zum Zugriff auf Nutzerordner | ergibt sich aus der Sandbox-Konfiguration |

## Fehlbestand

| # | Beobachtung | Folge |
|---|---|---|
| DZ-01 | Keine Datenschutzerklärung auf filescope.daumedia.lu | Für den App Store zwingend; auch für den Direktvertrieb üblich |
| DZ-02 | Die Website sagt „Everything stays local", ohne die IP-Übermittlung an GitHub beim Update-Check zu erwähnen | Die Aussage ist im Kern richtig, aber unvollständig — ein Satz genügt zur Richtigstellung. Gehört zu B11 |
| DZ-06 | ~~`Accept-Language` fehlte in der Aufstellung~~ | **behoben am 2026-08-24** (BUG-04), belegt durch den abgefangenen Abruf oben |
| DZ-03 | Weder Scan noch Duplikatsuche lassen sich abbrechen, und beide sind unbegrenzt | Verfügbarkeitsrisiko auf dem Gerät des Nutzers, kein Datenschutzrisiko |
| DZ-04 | Der JSON-Export enthält den vollständigen Ordnerpfad samt Benutzername, ohne Hinweis in der Oberfläche | Wer die Datei weitergibt, gibt den Benutzernamen mit |
| DZ-05 | Der private EdDSA-Schlüssel hat keine dokumentierte Sicherung | Verlust beendet den Update-Kanal endgültig |
