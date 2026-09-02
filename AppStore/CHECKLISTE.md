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

      Ob die Projektstruktur trägt, lässt sich **ohne** Zertifikate prüfen:

      ```bash
      xcodegen generate
      xcodebuild archive -project MikaFileScope.xcodeproj -scheme MikaFileScope \
        -destination "generic/platform=macOS" -archivePath /tmp/Probe.xcarchive \
        CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
      /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" /tmp/Probe.xcarchive/Info.plist
      ```

      Kommt dort ein Block mit `ApplicationPath = Applications/MikaFileScope.app`,
      ist es ein App-Archiv. Fehlt `ApplicationProperties` ganz, bietet Xcode beim
      Verteilen nur „Custom" an. Zuletzt geprüft am 2026-08-25: App-Archiv,
      universal (x86_64 + arm64), ohne Sparkle.
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

## Vor jeder Einreichung — am Bundle prüfen

`swift test --filter BundleConfigTests` deckt beides ab; von Hand gegenprüfen lässt
es sich am gebauten Paket:

```bash
bash scripts/build.sh --appstore
plutil -p "build/appstore/Mika+FileScope.app/Contents/Info.plist" | grep UsageDescription
codesign -d --entitlements - "build/appstore/Mika+FileScope.app"
```

- [ ] Sechs `NS*UsageDescription` vorhanden, jede mit Zweck **und** Beispiel.
      Fehlen sie, erscheinen die Systemdialoge ohne Text — Ablehnungsgrund 5.1.1(ii)
      am 2026-09-01
- [ ] `com.apple.security.files.user-selected.read-write` gesetzt, `read-only` nicht.
      Mit `read-only` öffnet die Powerbox den Speichern-Dialog nicht, und der Export
      bleibt wirkungslos — Ablehnungsgrund 2.1(a) am 2026-09-01
- [ ] Den **Benutzerordner** einmal wirklich scannen, nicht nur einen Testordner.
      Vorher `tccutil reset SystemPolicyDesktopFolder lu.daumedia.mikafilescope`
      (ebenso `…DocumentsFolder`, `…DownloadsFolder`), sonst greift die gespeicherte
      Entscheidung und die Dialoge bleiben aus
- [ ] Export einmal bis zur geschriebenen Datei durchspielen, in der **sandboxed**
      Fassung — nicht im Debug-Build
