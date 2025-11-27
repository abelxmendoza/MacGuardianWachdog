#!/bin/bash
APP_DIR=".build/release/MacGuardian Suite.app"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
FULL_APP_DIR="$ROOT_DIR/$APP_DIR"

echo "📁 Checking bundle..."
if [ ! -d "$FULL_APP_DIR" ]; then
    echo "❌ No app bundle found at: $FULL_APP_DIR"
    echo "   Run ./build_app.sh first"
    exit 1
fi
echo "   ✅ App bundle exists"

echo ""
echo "📄 Checking Info.plist..."
if grep -q "CFBundleIconFile" "$FULL_APP_DIR/Contents/Info.plist" 2>/dev/null; then
    ICON_NAME=$(grep -A1 "CFBundleIconFile" "$FULL_APP_DIR/Contents/Info.plist" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    if [ "$ICON_NAME" = "AppIcon" ]; then
        echo "   ✅ Icon entry OK: $ICON_NAME"
    else
        echo "   ⚠️  Icon entry found but should be 'AppIcon': $ICON_NAME"
    fi
else
    echo "   ❌ Missing icon entry"
    exit 1
fi

echo ""
echo "🎨 Checking icon file..."
if [ -f "$FULL_APP_DIR/Contents/Resources/AppIcon.icns" ]; then
    ICON_SIZE=$(stat -f%z "$FULL_APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || stat -c%s "$FULL_APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || echo "0")
    if [ "$ICON_SIZE" -gt 0 ]; then
        echo "   ✅ Icon file exists ($(du -h "$FULL_APP_DIR/Contents/Resources/AppIcon.icns" | cut -f1))"
    else
        echo "   ❌ Icon file is empty"
        exit 1
    fi
else
    echo "   ❌ Icon file missing"
    exit 1
fi

echo ""
echo "✅ All checks passed!"
echo ""
echo "📍 App location: $FULL_APP_DIR"
echo "🚀 To launch: open \"$FULL_APP_DIR\""
