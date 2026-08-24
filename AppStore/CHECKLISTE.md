# Vor der Einreichung

Was im Repository liegt, ist fertig. Offen ist nur noch, was sich ausschließlich im
Apple-Konto oder auf einem fremden Dienst erledigen lässt.

## Im Apple Developer Account

- [ ] **Zertifikate erzeugen** — *Apple Distribution* und *Mac Installer Distribution*.
      Nur die *Developer ID*-Zertifikate liegen bereits im Schlüsselbund; die beiden
      Store-Zertifikate fehlen noch.
      Prüfen mit `security find-identity -v -p codesigning`.
- [ ] **Provisioning Profile** für `lu.daumedia.mikafilescope` (Mac App Store) anlegen
      und laden.
- [ ] **App-Datensatz in App Store Connect** anlegen: Name, Bundle-ID, SKU aus
      [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md).

## Beim Hochladen

- [ ] `xcodegen generate`, dann in Xcode **Product ▸ Archive** mit Ziel „My Mac".
      Das Archiv muss als *macOS App Archive* erscheinen, nicht als *Generic Xcode
      Archive* — sonst fehlt `INSTALL_PATH` in `project.yml`.
- [ ] Texte aus `metadata/en-US/` einsetzen, Screenshots aus
      `screenshots/en-US/mac-2880x1800/` in Nummernreihenfolge hochladen.
- [ ] Datenschutz-Fragebogen: durchgehend **Data Not Collected**.
- [ ] Altersfreigabe-Fragebogen: alle 24 Kategorien „Nein"/„Nie", Ergebnis **4+**.
      Antworten und Belege in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).
- [ ] Prüfungshinweise aus [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) eintragen.

## Nur für den Direktvertrieb (nicht Store-relevant)

- [ ] **Notarisierung einrichten**: einmalig
      `xcrun notarytool store-credentials "notarytool" --apple-id <mail> --team-id CWJM4J4HFN --password <app-spezifisch>`,
      danach läuft `bash scripts/notarize.sh`.
- [ ] **GitHub-Kontoname `Mukaarts` sichern.** Ausgelieferte Kopien von v2.0.0 fragen
      dort ihren Sparkle-Feed ab. Es ist der frühere Name desselben Kontos, nach der
      Umbenennung aber unbesetzt und für andere registrierbar.
- [ ] **Impressum vervollständigen**: `website/imprint.html` enthält drei Platzhalter
      (Anschrift, RCS-Nummer, USt-IdNr.).

## Zuletzt

- [ ] `swift test` — alle Prüfungen grün, einschließlich `StoreAssetTests`.
- [ ] Version in `Resources/Info.plist`, `CHANGELOG.md` und `website/index.html`
      stimmt überein.
