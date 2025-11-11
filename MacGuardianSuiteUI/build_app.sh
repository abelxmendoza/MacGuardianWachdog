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

# Create app icon if logo exists (check both MacGlogo.png and MacGuardianLogo.png)
LOGO_PNG=""
ICON_NAME="MacGlogo"

if [ -f "$SCRIPT_DIR/Resources/images/MacGlogo.png" ]; then
    LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGlogo.png"
    ICON_NAME="MacGlogo"
elif [ -f "$SCRIPT_DIR/Resources/images/MacGuardianLogo.png" ]; then
    LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGuardianLogo.png"
    ICON_NAME="MacGuardianLogo"
    # Also create a symlink or copy as MacGlogo for consistency
    if [ ! -f "$SCRIPT_DIR/Resources/images/MacGlogo.png" ]; then
        cp "$LOGO_PNG" "$SCRIPT_DIR/Resources/images/MacGlogo.png"
        echo "📋 Using MacGuardianLogo.png as MacGlogo.png"
    fi
    LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGlogo.png"
fi

if [ -n "$LOGO_PNG" ] && [ -f "$LOGO_PNG" ]; then
    echo "🎨 Creating app icon from $(basename "$LOGO_PNG")..."
    if [ ! -f "$SCRIPT_DIR/Resources/images/MacGlogo.icns" ]; then
        # Generate .icns file if it doesn't exist
        "$SCRIPT_DIR/create_app_icon.sh" 2>/dev/null || echo "⚠️  Could not create .icns (sips/iconutil may not be available)"
    fi
    # Copy .icns to app bundle
    if [ -f "$SCRIPT_DIR/Resources/images/MacGlogo.icns" ]; then
        cp "$SCRIPT_DIR/Resources/images/MacGlogo.icns" "$RESOURCES_DIR/MacGlogo.icns"
        echo "✅ App icon copied to bundle"
    fi
fi

# Copy logo and image resources if they exist
if [ -d "$SCRIPT_DIR/Resources" ]; then
    echo "📸 Copying image resources..."
    # Copy all files from Resources directory
    cp -r "$SCRIPT_DIR/Resources"/* "$RESOURCES_DIR/" 2>/dev/null || true
    # Specifically ensure images folder contents are copied
    if [ -d "$SCRIPT_DIR/Resources/images" ]; then
        cp -r "$SCRIPT_DIR/Resources/images"/* "$RESOURCES_DIR/" 2>/dev/null || true
    fi
fi

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
    <key>CFBundleIconFile</key>
    <string>MacGlogo</string>
    <key>CFBundleIconFiles</key>
    <array>
        <string>MacGlogo</string>
    </array>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

# Create PkgInfo (required for app recognition)
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Set bundle attributes to ensure macOS recognizes it as an app
/usr/bin/SetFile -a B "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/SetFile -a C "$APP_BUNDLE" 2>/dev/null || true

# Touch the bundle to update its modification time
touch "$APP_BUNDLE"
touch "$CONTENTS_DIR/Info.plist"
touch "$CONTENTS_DIR/PkgInfo"

# Convert Info.plist to binary format (more reliable)
plutil -convert binary1 "$CONTENTS_DIR/Info.plist" 2>/dev/null || true

echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "🚀 To install:"
echo "   cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "   Or drag \"$APP_BUNDLE\" to your Applications folder in Finder"

