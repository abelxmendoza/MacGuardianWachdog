#!/bin/bash
# Build script to create a proper macOS .app bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
APP_NAME="MacGuardian Suite"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building MacGuardian Suite UI..."

# Clean previous build
rm -rf "$APP_BUNDLE"

# Build the Swift package
cd "$SCRIPT_DIR"
swift build -c release

# Find the built executable
EXECUTABLE=$(swift build -c release --show-bin-path)/MacGuardianSuiteUI

if [ ! -f "$EXECUTABLE" ]; then
    echo "❌ Error: Executable not found at $EXECUTABLE"
    exit 1
fi

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE" "$MACOS_DIR/MacGuardianSuiteUI"
chmod +x "$MACOS_DIR/MacGuardianSuiteUI"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacGuardianSuiteUI</string>
    <key>CFBundleIdentifier</key>
    <string>com.macguardian.suite.ui</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacGuardian Suite</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 MacGuardian Suite</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Create PkgInfo (optional but helps with app recognition)
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "🚀 To install:"
echo "   cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "   Or drag \"$APP_BUNDLE\" to your Applications folder in Finder"

