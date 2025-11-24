#!/bin/bash
# More reliable method to set app icon on macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/.build/MacGuardian Suite.app"
ICON_ICNS="$SCRIPT_DIR/Resources/images/MacGuardianLogo.icns"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App bundle not found: $APP_BUNDLE"
    exit 1
fi

if [ ! -f "$ICON_ICNS" ]; then
    echo "❌ Icon file not found: $ICON_ICNS"
    exit 1
fi

echo "🎨 Setting app icon using multiple methods..."

# Method 1: Use sips to copy icon directly (most reliable)
echo "   Method 1: Using sips..."
sips -i "$ICON_ICNS" > /dev/null 2>&1 || true

# Method 2: Use DeRez/Rez to embed icon resource
if command -v DeRez &> /dev/null && command -v Rez &> /dev/null; then
    echo "   Method 2: Embedding icon resource..."
    ICON_RSRC=$(mktemp)
    DeRez -only icns "$ICON_ICNS" > "$ICON_RSRC" 2>/dev/null || true
    if [ -f "$ICON_RSRC" ] && [ -s "$ICON_RSRC" ]; then
        EXECUTABLE="$APP_BUNDLE/Contents/MacOS/MacGuardianSuiteUI"
        if [ -f "$EXECUTABLE" ]; then
            Rez -append "$ICON_RSRC" -o "$EXECUTABLE" 2>/dev/null || true
        fi
        rm -f "$ICON_RSRC"
    fi
fi

# Method 3: Use AppleScript to set icon (most reliable for Dock)
echo "   Method 3: Using AppleScript..."
osascript <<EOF 2>/dev/null || true
tell application "Finder"
    set theApp to POSIX file "$APP_BUNDLE" as alias
    set iconFile to POSIX file "$ICON_ICNS" as alias
    set the icon of theApp to iconFile
end tell
EOF

# Method 4: Copy icon to bundle and update timestamps
echo "   Method 4: Ensuring icon in bundle..."
cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/MacGuardianLogo.icns" 2>/dev/null || true
chmod 644 "$APP_BUNDLE/Contents/Resources/MacGuardianLogo.icns" 2>/dev/null || true

# Update timestamps
touch "$APP_BUNDLE"
touch "$APP_BUNDLE/Contents/Info.plist"
touch "$APP_BUNDLE/Contents/Resources/MacGuardianLogo.icns"

# Set bundle attributes
if command -v SetFile &> /dev/null; then
    SetFile -a C "$APP_BUNDLE" 2>/dev/null || true
fi

echo "✅ Icon set using multiple methods"
echo ""
echo "💡 To see the icon:"
echo "   1. Quit the app if running"
echo "   2. Run: killall Dock"
echo "   3. Or restart your Mac"
echo "   4. Open the app again"

