#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Mika+FileScope"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Parse flags
CLEAN=false
IS_APPSTORE=false
UNIVERSAL=false
# Signaturidentität. Ad-hoc ("-") ist der Rückfall ohne Entwicklerkonto; für alles,
# was das Haus verlässt, gehört hier eine Developer ID hin — sonst weist Gatekeeper
# die App auf fremden Rechnern ab.
SIGN_ID="${MIKA_SIGN_ID:--}"
for arg in "$@"; do
    case "$arg" in
        --clean)     CLEAN=true ;;
        --appstore)  IS_APPSTORE=true ;;
        --universal) UNIVERSAL=true ;;
        --sign)      SIGN_ID="$2"; shift ;;
        --release)
            # Kürzel: nimmt die erste Developer-ID-Identität aus dem Schlüsselbund.
            SIGN_ID=$(security find-identity -v -p codesigning \
                      | grep "Developer ID Application" | head -1 \
                      | sed -E 's/.*"(.*)"/\1/')
            if [ -z "$SIGN_ID" ]; then
                echo "FEHLER: Keine 'Developer ID Application' im Schlüsselbund gefunden." >&2
                exit 1
            fi
            UNIVERSAL=true ;;
        -h|--help)
            echo "Verwendung: build.sh [--clean] [--appstore] [--universal] [--release|--sign ID]"
            echo "  --clean      .build vorher entfernen"
            echo "  --appstore   Store-Variante: Sandbox, ohne Sparkle"
            echo "  --universal  arm64 + x86_64 statt nur der Host-Architektur"
            echo "  --release    Developer ID aus dem Schlüsselbund + universal"
            echo "  --sign ID    Signaturidentität ausdrücklich wählen"
            echo ""
            echo "Nach --release folgt die Notarisierung:"
            echo "  bash scripts/notarize.sh installer/<paket>.dmg"
            exit 0 ;;
    esac
done

if [ "$IS_APPSTORE" = true ]; then
    # Die Umgebungsvariable steuert Package.swift; die Skriptvariable bleibt davon
    # getrennt, sonst prüft der Sparkle-Zweig unten gegen den falschen Wert.
    export APPSTORE=1
    ENTITLEMENTS="$PROJECT_DIR/Resources/MikaFileScope-AppStore.entitlements"
    BUILD_DIR="$PROJECT_DIR/build/appstore"
    APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
    echo "==> Store-Variante: Sandbox aktiv, Sparkle wird nicht eingebunden"
else
    ENTITLEMENTS="$PROJECT_DIR/Resources/MikaFileScope.entitlements"
fi

if [ "$CLEAN" = true ]; then
    echo "==> Cleaning .build/ directory..."
    rm -rf "$PROJECT_DIR/.build"
fi

# Der SwiftPM-Cache speichert absolute Pfade. Wurde das Projekt seit dem letzten Bau
# verschoben, scheitert `swift build` mit einer Meldung über den ALTEN Pfad — schwer zu
# deuten, wenn man den Umzug nicht mehr erinnert. Deshalb hier prüfen und selbst räumen.
if [ -f "$PROJECT_DIR/.build/workspace-state.json" ] \
   && ! grep -q "$PROJECT_DIR" "$PROJECT_DIR/.build/workspace-state.json" 2>/dev/null; then
    echo "==> Build-Cache stammt von einem anderen Speicherort — wird bereinigt..."
    rm -rf "$PROJECT_DIR/.build"
fi

echo "==> Building MikaFileScope..."
cd "$PROJECT_DIR"

if [ "$UNIVERSAL" = true ]; then
    # `swift build` erzeugt nur die Architektur des bauenden Rechners. Für ein Paket,
    # das auch auf Intel-Macs startet, müssen beide einzeln gebaut und vereint werden.
    echo "==> Universelles Binary (arm64 + x86_64)..."
    swift build -c release --arch arm64 --arch x86_64 2>&1
    EXECUTABLE=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/MikaFileScope
else
    swift build -c release 2>&1
    EXECUTABLE=$(swift build -c release --show-bin-path)/MikaFileScope
fi

echo "==> Assembling app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/MikaFileScope"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy app icon if available
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Sparkle einbetten — nur im Direktvertrieb. Der Store lässt keinen eigenen
# Update-Mechanismus zu; dort ist das Framework gar nicht erst gelinkt.
SPARKLE_FW=""
if [ "$IS_APPSTORE" != true ]; then
    SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -path "*/macos-arm64_x86_64/Sparkle.framework" -print -quit 2>/dev/null || true)
    if [ -z "$SPARKLE_FW" ]; then
        SPARKLE_FW=$(find "$PROJECT_DIR/.build/artifacts" -name "Sparkle.framework" -print -quit 2>/dev/null || true)
    fi
    if [ -z "$SPARKLE_FW" ]; then
        echo "FEHLER: Sparkle.framework nicht gefunden — das Bundle wäre ohne Update-Fähigkeit." >&2
        echo "        Führe 'swift build -c release' aus oder baue mit --appstore." >&2
        exit 1
    fi
fi
if [ -n "$SPARKLE_FW" ]; then
    echo "==> Embedding Sparkle.framework..."
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    cp -R "$SPARKLE_FW" "$APP_BUNDLE/Contents/Frameworks/"

    install_name_tool -add_rpath "@executable_path/../Frameworks" \
        "$APP_BUNDLE/Contents/MacOS/MikaFileScope" 2>/dev/null || true

    # Sign nested Sparkle components inside-out
    SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
    for xpc in "$SPARKLE_DIR"/Versions/B/XPCServices/*.xpc; do
        [ -d "$xpc" ] && codesign --force --sign "$SIGN_ID" --options runtime --timestamp "$xpc"
    done
    for app in "$SPARKLE_DIR"/Versions/B/*.app; do
        [ -d "$app" ] && codesign --force --sign "$SIGN_ID" --options runtime --timestamp "$app"
    done
    codesign --force --sign "$SIGN_ID" --options runtime --timestamp "$SPARKLE_DIR/Versions/B/Autoupdate" 2>/dev/null || true
    codesign --force --sign "$SIGN_ID" --options runtime --timestamp "$SPARKLE_DIR/Versions/B/Sparkle"
    codesign --force --sign "$SIGN_ID" --options runtime --timestamp "$SPARKLE_DIR"
fi

if [ "$SIGN_ID" = "-" ]; then
    echo "==> Signing ad-hoc (Gatekeeper wird die App auf fremden Rechnern abweisen)"
else
    echo "==> Signing with: $SIGN_ID"
fi
# Ohne --deep: Die verschachtelten Bestandteile sind oben bereits einzeln signiert.
# `--deep` überschrieb sie erneut und machte das Bundle in Prüfläufen startunfähig
# ("different Team IDs"). Apple rät davon ohnehin ab.
codesign --force --sign "$SIGN_ID" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime --timestamp \
    "$APP_BUNDLE"

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0")

# Prüfschritt statt bloßem Hinweis: Ein fehlerhaft signiertes Bundle fiel bisher
# erst beim Nutzer auf.
echo "==> Verifying signature..."
if ! codesign --verify --strict "$APP_BUNDLE" 2>&1; then
    echo "FEHLER: Signaturprüfung fehlgeschlagen." >&2
    exit 1
fi
ARCHS=$(lipo -archs "$APP_BUNDLE/Contents/MacOS/MikaFileScope" 2>/dev/null || echo "?")

# Gatekeeper-Gegenprobe: Sie schlägt bei Ad-hoc erwartungsgemäß fehl und ist dann nur
# ein Hinweis. Bei einer Developer ID ohne Notarisierung schlägt sie ebenfalls fehl —
# das ist der Punkt, an dem notarize.sh folgt.
echo "==> Gatekeeper-Gegenprobe:"
spctl -a -vv "$APP_BUNDLE" 2>&1 | sed 's/^/    /' || true

echo ""
echo "==> Build complete: $APP_BUNDLE (v$VERSION, $ARCHS)"
echo ""
echo "To verify signature:"
echo "  codesign --verify --deep --strict \"$APP_BUNDLE\""
echo ""
echo "To run:"
echo "  open \"$APP_BUNDLE\""
