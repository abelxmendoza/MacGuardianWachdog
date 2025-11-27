#!/bin/bash
set -e

APP_NAME="MacGuardian Suite"
EXECUTABLE="MacGuardianSuiteUI"
ICON_FILE="AppIcon.icns"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "🔨 Building Swift package..."
swift build -c release

# Get the actual build path (architecture-specific)
ACTUAL_BUILD_DIR=$(swift build -c release --show-bin-path)
EXECUTABLE_PATH="$ACTUAL_BUILD_DIR/$EXECUTABLE"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ Error: Executable not found at $EXECUTABLE_PATH"
    exit 1
fi

echo "📦 Creating macOS app bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "🚚 Copying executable..."
cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/"

echo "🎨 Copying icon..."
if [ -f "$ROOT_DIR/Resources/$ICON_FILE" ]; then
    cp "$ROOT_DIR/Resources/$ICON_FILE" "$APP_DIR/Contents/Resources/"
    echo "   ✅ Icon copied"
else
    echo "   ⚠️  Warning: Icon file not found at $ROOT_DIR/Resources/$ICON_FILE"
fi

echo "📝 Creating Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key>
    <string>com.omegatech.$EXECUTABLE</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Create PkgInfo (required for app recognition)
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "✨ Build complete!"
echo "📍 App located at: $APP_DIR"
echo ""
echo "🚀 To launch:"
echo "   open \"$APP_DIR\""
echo ""
echo "💡 If Dock icon doesn't update:"
echo "   killall Dock"
