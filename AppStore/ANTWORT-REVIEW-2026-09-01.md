# Antwort an den App Review — Submission 9b246573-21ad-44c4-a5a5-db0ac143b21c

Entwurf für die Antwort in App Store Connect. Version 2.1.1, eingereicht nach der
Ablehnung vom 2026-09-01.

**Zum Hinweis auf die Medienbibliothek:** Die Meldung verlangt unter „Next Steps",
die *media library and Apple Music library* purpose strings zu ergänzen. Mika+FileScope
greift auf keine Medien- oder Musikbibliothek zu und fragt keine solche Berechtigung
ab — offenbar ein Textbaustein. Die tatsächlich betroffenen Berechtigungen sind die
Dateiordner, und die sind unten benannt. Der Antworttext stellt das sachlich klar,
ohne darauf herumzureiten.

---

```
Thank you for the detailed review. Both issues are fixed in version 2.1.1.

Guideline 5.1.1(ii) — purpose strings

You are right: version 2.1.0 shipped with no purpose strings at all, so the system
consent dialogs appeared with no explanation. That was our mistake — we had treated
the App Sandbox entitlement as covering these prompts, which it does not.

Version 2.1.1 adds six usage descriptions to Info.plist, each stating what is read,
what for, with an example, and what the app does not do:

- NSDesktopFolderUsageDescription
- NSDocumentsFolderUsageDescription
- NSDownloadsFolderUsageDescription
- NSRemovableVolumesUsageDescription
- NSNetworkVolumesUsageDescription
- NSFileProviderDomainUsageDescription

For example, the Desktop string reads:

  "Mika+FileScope reads the names, sizes and modification dates of files on your
  Desktop to show how much space each file type uses there — for example, that 340
  screenshots take up 12 GB. File contents are read only when you start a duplicate
  search, and only on this Mac. Nothing is moved, changed, deleted or uploaded."

These prompts appear because a scan is recursive: choosing the home folder means the
scan reaches Desktop, Documents and Downloads. In 2.1.1 the app also explains this
before the first folder is chosen, in a one-time panel that states which system
prompts are coming and that only names, sizes and dates are read.

One clarification: the app does not access the media library or the Apple Music
library, and requests no such permission. We assume that part of the message was a
template. If we misunderstood and you did observe a media-related prompt, please let
us know which step produced it and we will investigate immediately.

Guideline 2.1(a) — Export did not respond

Reproduced and fixed. The cause was an entitlement: the build was signed with
com.apple.security.files.user-selected.read-only. Without the read-write entitlement,
the Powerbox does not open the save dialog at all — no panel, no file, no error
message. From the outside the Export menu simply did nothing, exactly as you describe.

We verified this by signing the identical build both ways: with read-only, choosing
"Export as CSV" produced no visible reaction; with read-write, the save dialog appears
and the file is written.

Version 2.1.1 changes three things here:

1. The App Store build now uses com.apple.security.files.user-selected.read-write.
   The app still only reads the folders you select; the only file it writes is the
   export you name in the save dialog.
2. The save dialog is presented as a window sheet instead of a modal session started
   from inside a menu action.
3. Export is also available as File > Export as CSV (Cmd-E) and Export as JSON
   (Shift-Cmd-E), so it does not depend on the toolbar.

While fixing this we also corrected related issues that could have affected your
review: the scan progress counter never advanced (a long scan looked like a frozen
app), cancelling a scan did not stop the background work, the duplicate search failed
silently when it could not open files, and a few interface strings were in German in
an otherwise English app. Denied access is now reported as such, with a pointer to
System Settings, instead of being counted silently.

We have added automated tests that check the purpose strings and the entitlements in
the bundle, so this class of problem cannot pass unnoticed again.

To test: any folder with mixed file types shows every feature within seconds. If you
scan a folder containing Desktop, Documents or Downloads, macOS will ask for consent
to each — those prompts now carry the descriptions above. Please note that macOS
remembers earlier decisions; "tccutil reset SystemPolicyDesktopFolder
lu.daumedia.mikafilescope" re-triggers them if needed.

Thank you again for the clear reproduction steps.
```
