# Mika+FileScope — Marketing Website

Static landing page for Mika+FileScope. No build step, no dependencies — plain HTML, CSS and ~60 lines of vanilla JS.

## Local preview

```bash
cd website
python3 -m http.server 8080
# → http://localhost:8080
```

## Deploy to Vercel

**Option A — Git integration (recommended)**

1. Import `daumedia/MikaFileScope` at [vercel.com/new](https://vercel.com/new)
2. Set **Root Directory** to `website`
3. Framework Preset: **Other** (no build command, no output directory)
4. Deploy. Every push to `main` redeploys automatically.

**Option B — One-off deploy from the CLI**

```bash
npx vercel --cwd website          # preview deployment
npx vercel --cwd website --prod   # production deployment
```

## Domain

The site is served from **`filescope.daumedia.lu`**. To attach it in Vercel:

1. Project → **Settings → Domains** → add `filescope.daumedia.lu`
2. At the DNS provider for `daumedia.lu`, add the record Vercel shows — for a subdomain that is
   a `CNAME` pointing to `cname.vercel-dns.com`
3. Wait for the certificate to be issued (usually a few minutes)

Every absolute URL in the site is already set to that domain. If it ever changes, update it in
three places:

- `index.html` — `<link rel="canonical">`, `og:url`, `og:image`, `twitter:image`, and the JSON-LD `url`
- `robots.txt` — the `Sitemap:` line
- `sitemap.xml` — the `<loc>` element

## Regenerating assets

The social preview is generated from the app icon by an AppKit script, run from the repo root:

```bash
swift scripts/GenerateOGImage.swift   # → website/assets/og-image.jpg
```

Screenshots in `assets/shots/` were captured from the real app in Dark Mode at a 1280×820 window
(`screencapture -o -l <windowID>`, so the rounded window corners stay transparent) and converted
with `cwebp -q 86 -alpha_q 100 -m 6`.

## Keeping the page truthful

Three claims on the page are tied to how the app is actually built. If any of this changes, update the page:

| Page says | Verify with |
|---|---|
| Apple silicon | `lipo -archs build/Mika+FileScope.app/Contents/MacOS/MikaFileScope` |
| Not notarized, needs right-click → Open on first launch | `codesign -dv build/Mika+FileScope.app` (currently `Signature=adhoc`) |
| No network requests except the update check | `grep -rn "URLSession\|https://" Sources/` (currently no hits — network comes from Sparkle only) |

Version number, download link and file size are hard-coded in `index.html` and point at the
`v2.0.0` GitHub release. Update them when a new version ships.
