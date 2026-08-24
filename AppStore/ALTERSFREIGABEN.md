# Altersfreigaben — Antworten für App Store Connect

Der Fragebogen unter *App Store Connect → App-Informationen → Altersfreigaben* fragt
24 Kategorien ab. Hier stehen die Antworten mit dem Beleg aus dem Code, damit sie bei
einer Neueinreichung oder nach einem Feature-Umbau nachvollziehbar bleiben. Ändert sich
eine der belegten Stellen, gehört die Antwort geprüft.

Stand: 2026-08-24, App-Version 2.1.0. Grundlage:
[Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions).

**Ergebnis: 4+** — die niedrigste Stufe, und zwar ohne Ausnahme in irgendeiner
Kategorie.

Apple hat das System 2025 umgestellt: Die Stufen heißen jetzt 4+, 9+, 13+, 16+ und 18+
(vorher 4+, 9+, 12+, 17+), und mehrere Kategorien sind dazugekommen. Wer eine ältere
Anleitung im Kopf hat, findet die Fragen nicht wieder.

---

## Schritt 1: Funktionen

| Frage (deutsch / englisch) | Antwort | Beleg |
|---|---|---|
| Kindersicherung · *Parental Controls* | Nein | Die App kennt genau eine Einstellung: Menüleistensymbol ja/nein (`AppStorageKeys.showMenubar`, `Sources/MikaFileScopeApp.swift:61`). Keine Sperren, keine Profile. |
| Altersnachweis · *Age Assurance* | Nein | Keine Konten, keine Registrierung, keine Altersabfrage. Die App fragt nichts ab. |
| Uneingeschränkter Internetzugriff · *Unrestricted Web Access* | Nein | Kein Browser, keine Adresszeile. `grep -rn "URLSession\|WKWebView" Sources/` liefert **nichts**. Der einzige Sprung nach außen ist `NSWorkspace.shared.activateFileViewerSelecting` (`Sources/DuplicateResultView.swift:118`) — der öffnet den Finder mit der markierten Datei, nicht das Netz. |
| Benutzergenerierte Inhalte · *User-Generated Content* | Nein | Siehe die Abgrenzung unten — die angezeigten Dateinamen sind keine UGC im Sinne des Fragebogens. |
| Soziale Medien · *Social Media* | Nein | Keine Feeds, keine Profile, keine Interaktion mit anderen Nutzern. |
| Soziale Medien für unter 13-Jährige deaktiviert · *Social Media Disabled for Users Under 13* | Nein | Gegenstandslos, da „Soziale Medien" bereits Nein ist. |
| Nachrichten und Chat · *Messaging and Chat* | Nein | Keine Kommunikationsfunktion. |
| Werbung · *Advertising* | Nein | Die Store-Variante wird ohne jede Fremdabhängigkeit gebaut: `Package.swift:13` schaltet über `APPSTORE=1` auch Sparkle ab. Kein Werbe-SDK, keine Analytics. |

### Warum „Benutzergenerierte Inhalte = Nein"

Die App zeigt Dateinamen und Pfade aus dem gescannten Ordner an — im Duplikat-Sheet
sogar vollständig. Das ist die Frage, die bei einer Prüfung am ehesten aufkommt.

Es ist trotzdem keine UGC im Sinne des Fragebogens. Apple zielt damit auf Inhalte, die
Nutzer **beitragen und die anderen Nutzern sichtbar werden** — Kommentare, Profile,
hochgeladene Bilder. Hier gibt es beides nicht:

- Die Dateien stammen vom eigenen Gerät und werden nur der Person angezeigt, die den
  Ordner selbst ausgewählt hat.
- Nichts wird hochgeladen, geteilt oder veröffentlicht. Die App stellt keine
  Netzwerkverbindung her.
- Der Export (`Sources/ExportManager.swift`) schreibt CSV oder JSON über ein
  `NSSavePanel` an einen Ort, den der Nutzer bestimmt — lokal.

Damit entfallen auch die Folgepflichten aus Guideline 1.2 (Meldefunktion, Blockieren,
veröffentlichte Kontaktadresse). Sollte je eine Freigabe- oder Teilen-Funktion
dazukommen, ist diese Antwort als Erstes zu prüfen.

## Schritt 2: Erwachsenenthemen

| Frage | Antwort | Beleg |
|---|---|---|
| Obszöner oder vulgärer Humor · *Profanity or Crude Humor* | Nie | Die App zeigt Tabellen, Diagramme und Dateiendungen. Alle Texte stehen in `Sources/`. |
| Horror-/Gruselszenen · *Horror/Fear Themes* | Nie | Keine Illustrationen außer dem App-Symbol und SF Symbols. |
| Alkohol, Tabak oder Drogen bzw. Verweise · *Alcohol, Tobacco, or Drug Use or References* | Nie | Kommt inhaltlich nicht vor. |

## Schritt 3: Gesundheit

| Frage | Antwort | Beleg |
|---|---|---|
| Medizinische oder Behandlungsinformationen · *Medical or Treatment Information* | Nie | Die App gibt keinerlei Ratschläge. |
| Gesundheits- oder Wellness-Themen · *Health or Wellness Topics* | Nein | Dito. |

## Schritt 4: Sexuelle Inhalte

| Frage | Antwort |
|---|---|
| Anzügliche Themen · *Mature or Suggestive Themes* | Nie |
| Sexuelle Inhalte oder Nacktheit · *Sexual Content or Nudity* | Nie |
| Explizite sexuelle Inhalte und Nacktheit · *Graphic Sexual Content and Nudity* | Nie |

Die App erzeugt keine eigenen Bildinhalte. Dass ein Nutzer einen Ordner mit beliebigen
Dateien scannen kann, ändert daran nichts: Die App zeigt Namen und Größen, keine
Vorschauen.

## Schritt 5: Gewalt

| Frage | Antwort |
|---|---|
| Comic- oder Fantasy-Gewalt · *Cartoon or Fantasy Violence* | Nie |
| Realistische Gewalt · *Realistic Violence* | Nie |
| Anhaltende explizite oder sadistische realistische Gewalt · *Prolonged Graphic or Sadistic Realistic Violence* | Nie |
| Schusswaffen oder andere Waffen · *Guns or Other Weapons* | Nie |

## Schritt 6: Glücksspiel und Wettbewerbe

| Frage | Antwort |
|---|---|
| Glücksspiel · *Gambling* | Nein |
| Simuliertes Glücksspiel · *Simulated Gambling* | Nie |
| Wettbewerbe · *Contests* | Nie |
| Beutekisten · *Loot Boxes* | Nein |

Keine Käufe, keine Währung, keine Zufallsmechanik. Die App ist kostenlos und kennt
keine In-App-Käufe.

---

## Wenn sich etwas ändert

Diese vier Antworten sind die einzigen, die ein neues Feature kippen könnte:

| Antwort | Was sie kippen würde |
|---|---|
| Uneingeschränkter Internetzugriff | Eine eingebettete Web-Ansicht oder ein Link, der frei navigierbare Seiten öffnet. Ein `WKWebView` in `Sources/` ist das Alarmsignal. |
| Benutzergenerierte Inhalte | Jede Funktion, die Ergebnisse mit anderen teilt statt sie lokal zu speichern. |
| Werbung | Jede Fremdabhängigkeit, die in der Store-Variante mitgebaut wird — `Package.swift:13` prüfen. |
| Nachrichten und Chat | Jede Form der Kommunikation zwischen Nutzern. |

Die drei ersten lassen sich mechanisch prüfen:

```bash
grep -rn "URLSession\|WKWebView" Sources/         # muss leer bleiben
APPSTORE=1 swift package show-dependencies        # "No external dependencies found"
```

Ohne `APPSTORE=1` erscheint dort Sparkle — das ist der Direktvertrieb und für den
Fragebogen unerheblich, weil im Store eine andere Binärdatei landet.

`swift test --filter StoreAssetTests` prüft die erste Zusage bei jedem Lauf mit.
