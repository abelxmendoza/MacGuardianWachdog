#!/bin/bash
set -e

APP_NAME="MacGuardian Suite"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "▸ Building Swift package..."
cd "$ROOT_DIR"
swift build -c release

echo "▸ Creating app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

echo "▸ Copying executable..."
cp "$BUILD_DIR/MacGuardianSuiteUI" "$APP_PATH/Contents/MacOS/"

echo "▸ Copying icon..."
if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/"
    echo "   ✔ Icon copied"
else
    echo "   ⚠️  Warning: Icon not found at $PROJECT_ROOT/Resources/AppIcon.icns"
fi

echo "▸ Writing Info.plist..."
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MacGuardian Suite</string>

    <key>CFBundleDisplayName</key>
    <string>MacGuardian Suite</string>

    <key>CFBundleIdentifier</key>
    <string>com.omegatech.macguardian</string>

    <key>CFBundleExecutable</key>
    <string>MacGuardianSuiteUI</string>

    <key>CFBundleVersion</key>
    <string>1.0</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleIconFile</key>
    <string>AppIcon</string>

    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>

    <key>NSHighResolutionCapable</key>
    <true/>

    <key>LSUIElement</key>
    <false/>

    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 MacGuardian Suite</string>

    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

echo "▸ Creating PkgInfo..."
echo -n "APPL????" > "$APP_PATH/Contents/PkgInfo"

echo ""
echo "✔ Build complete: $APP_PATH"
echo ""
echo "🚀 To launch:"
echo "   open \"$APP_PATH\""
echo ""
echo "💡 To force macOS to reload icon cache:"
echo "   killall Finder"
echo "   killall Dock"
