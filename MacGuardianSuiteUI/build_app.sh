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

# Create app icon - prioritize MacGuardianLogo.png
LOGO_PNG=""
ICON_NAME="MacGuardianLogo"

if [ -f "$SCRIPT_DIR/Resources/images/MacGuardianLogo.png" ]; then
    LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGuardianLogo.png"
    ICON_NAME="MacGuardianLogo"
elif [ -f "$SCRIPT_DIR/Resources/images/MacGlogo.png" ]; then
    LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGlogo.png"
    ICON_NAME="MacGlogo"
fi

# Handle app icon
ICON_ICNS="$SCRIPT_DIR/Resources/images/${ICON_NAME}.icns"
ICON_COPIED=false

if [ -n "$LOGO_PNG" ] && [ -f "$LOGO_PNG" ]; then
    echo "🎨 Processing app icon from $(basename "$LOGO_PNG")..."
    
    # Generate .icns file if it doesn't exist or is invalid
    if [ ! -f "$ICON_ICNS" ] || [ ! -s "$ICON_ICNS" ]; then
        echo "   Generating .icns file from $(basename "$LOGO_PNG")..."
        if [ -f "$SCRIPT_DIR/create_app_icon.sh" ]; then
            # Temporarily update create_app_icon.sh to use the correct logo
            LOGO_BACKUP="$SCRIPT_DIR/create_app_icon.sh.backup"
            cp "$SCRIPT_DIR/create_app_icon.sh" "$LOGO_BACKUP"
            sed -i '' "s|MacGlogo.png|${ICON_NAME}.png|g" "$SCRIPT_DIR/create_app_icon.sh"
            sed -i '' "s|MacGlogo.icns|${ICON_NAME}.icns|g" "$SCRIPT_DIR/create_app_icon.sh"
            sed -i '' "s|MacGlogo.iconset|${ICON_NAME}.iconset|g" "$SCRIPT_DIR/create_app_icon.sh"
            
            if bash "$SCRIPT_DIR/create_app_icon.sh" 2>&1; then
                echo "   ✅ Icon generated successfully"
            else
                echo "   ⚠️  Warning: Could not generate .icns file"
            fi
            
            # Restore original script
            mv "$LOGO_BACKUP" "$SCRIPT_DIR/create_app_icon.sh"
        fi
    fi
    
    # Verify and copy .icns to app bundle
    if [ -f "$ICON_ICNS" ] && [ -s "$ICON_ICNS" ]; then
        # Verify it's a valid icon file
        if file "$ICON_ICNS" | grep -q "Mac OS X icon\|Apple Icon Image"; then
            cp "$ICON_ICNS" "$RESOURCES_DIR/${ICON_NAME}.icns"
            chmod 644 "$RESOURCES_DIR/${ICON_NAME}.icns"
            ICON_COPIED=true
            echo "   ✅ App icon copied to bundle ($(du -h "$RESOURCES_DIR/${ICON_NAME}.icns" | cut -f1))"
        else
            echo "   ⚠️  Warning: Icon file may be invalid, attempting to regenerate..."
            rm -f "$ICON_ICNS"
            # Regenerate
            LOGO_BACKUP="$SCRIPT_DIR/create_app_icon.sh.backup"
            cp "$SCRIPT_DIR/create_app_icon.sh" "$LOGO_BACKUP"
            sed -i '' "s|MacGlogo.png|${ICON_NAME}.png|g" "$SCRIPT_DIR/create_app_icon.sh"
            sed -i '' "s|MacGlogo.icns|${ICON_NAME}.icns|g" "$SCRIPT_DIR/create_app_icon.sh"
            sed -i '' "s|MacGlogo.iconset|${ICON_NAME}.iconset|g" "$SCRIPT_DIR/create_app_icon.sh"
            
            if bash "$SCRIPT_DIR/create_app_icon.sh" 2>&1 && [ -f "$ICON_ICNS" ]; then
                cp "$ICON_ICNS" "$RESOURCES_DIR/${ICON_NAME}.icns"
                chmod 644 "$RESOURCES_DIR/${ICON_NAME}.icns"
                ICON_COPIED=true
                echo "   ✅ App icon regenerated and copied"
            else
                echo "   ❌ Error: Failed to create valid icon file"
            fi
            
            mv "$LOGO_BACKUP" "$SCRIPT_DIR/create_app_icon.sh"
        fi
    else
        echo "   ⚠️  Warning: Icon file not found or empty"
    fi
else
    echo "⚠️  Warning: Logo PNG not found, app will use default icon"
fi

# Copy logo and image resources if they exist (but exclude old icon files)
if [ -d "$SCRIPT_DIR/Resources" ]; then
    echo "📸 Copying image resources..."
    # Copy Resources but exclude .icns files (we'll copy the correct one separately)
    find "$SCRIPT_DIR/Resources" -type f ! -name "*.icns" -exec cp --parents {} "$RESOURCES_DIR/" \; 2>/dev/null || true
    
    # Copy images directory excluding .icns files
    if [ -d "$SCRIPT_DIR/Resources/images" ]; then
        find "$SCRIPT_DIR/Resources/images" -type f ! -name "*.icns" -exec cp {} "$RESOURCES_DIR/" \; 2>/dev/null || true
    fi
    
    # Remove any old icon files that shouldn't be there
    if [ "$ICON_NAME" = "MacGuardianLogo" ]; then
        rm -f "$RESOURCES_DIR/MacGlogo.icns" 2>/dev/null || true
    fi
fi

# Create Info.plist with proper icon configuration
ICON_PLIST=""
if [ "$ICON_COPIED" = true ] && [ -f "$RESOURCES_DIR/${ICON_NAME}.icns" ]; then
    ICON_PLIST="    <key>CFBundleIconFile</key>
    <string>${ICON_NAME}</string>
    <key>CFBundleIconFiles</key>
    <array>
        <string>${ICON_NAME}</string>
    </array>"
fi

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
$ICON_PLIST
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

# Create PkgInfo (required for app recognition)
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Set bundle attributes to ensure macOS recognizes it as an app
if command -v SetFile &> /dev/null; then
    /usr/bin/SetFile -a B "$APP_BUNDLE" 2>/dev/null || true
    /usr/bin/SetFile -a C "$APP_BUNDLE" 2>/dev/null || true
fi

# Use DeRez/Rez to set icon resource (more reliable method)
if command -v DeRez &> /dev/null && command -v Rez &> /dev/null && [ -f "$RESOURCES_DIR/${ICON_NAME}.icns" ]; then
    echo "   Setting icon resource using DeRez/Rez..."
    ICON_RSRC="$RESOURCES_DIR/icon.rsrc"
    DeRez -only icns "$RESOURCES_DIR/${ICON_NAME}.icns" > "$ICON_RSRC" 2>/dev/null || true
    if [ -f "$ICON_RSRC" ] && [ -s "$ICON_RSRC" ]; then
        Rez -append "$ICON_RSRC" -o "$MACOS_DIR/MacGuardianSuiteUI" 2>/dev/null || true
        rm -f "$ICON_RSRC" 2>/dev/null || true
    fi
fi

# Touch the bundle to update its modification time
touch "$APP_BUNDLE"
touch "$CONTENTS_DIR/Info.plist"
touch "$CONTENTS_DIR/PkgInfo"
if [ -f "$RESOURCES_DIR/${ICON_NAME}.icns" ]; then
    touch "$RESOURCES_DIR/${ICON_NAME}.icns"
fi

# Convert Info.plist to binary format (more reliable)
if command -v plutil &> /dev/null; then
    plutil -convert binary1 "$CONTENTS_DIR/Info.plist" 2>/dev/null || true
fi

# Verify icon is properly set
echo ""
echo "🔍 Verifying app bundle..."
if [ -f "$RESOURCES_DIR/${ICON_NAME}.icns" ]; then
    ICON_SIZE=$(stat -f%z "$RESOURCES_DIR/${ICON_NAME}.icns" 2>/dev/null || stat -c%s "$RESOURCES_DIR/${ICON_NAME}.icns" 2>/dev/null || echo "0")
    if [ "$ICON_SIZE" -gt 0 ]; then
        echo "   ✅ Icon file present: ${ICON_NAME}.icns ($(du -h "$RESOURCES_DIR/${ICON_NAME}.icns" | cut -f1))"
        # Verify Info.plist references correct icon
        if plutil -extract CFBundleIconFile raw "$INFO_PLIST" 2>/dev/null | grep -q "$ICON_NAME"; then
            echo "   ✅ Info.plist references correct icon: $ICON_NAME"
        else
            echo "   ⚠️  Warning: Info.plist may not reference icon correctly"
        fi
    else
        echo "   ⚠️  Warning: Icon file is empty"
    fi
else
    echo "   ⚠️  Warning: Icon file not found in bundle"
fi

# Verify Info.plist
if plutil -lint "$CONTENTS_DIR/Info.plist" &>/dev/null; then
    echo "   ✅ Info.plist is valid"
else
    echo "   ⚠️  Warning: Info.plist validation failed"
fi

# Verify executable
if [ -f "$MACOS_DIR/MacGuardianSuiteUI" ] && [ -x "$MACOS_DIR/MacGuardianSuiteUI" ]; then
    echo "   ✅ Executable is present and executable"
else
    echo "   ❌ Error: Executable not found or not executable"
    exit 1
fi

echo ""
# Set icon using reliable method
if [ "$ICON_COPIED" = true ] && [ -f "$SCRIPT_DIR/set_app_icon.sh" ]; then
    echo ""
    echo "🔧 Applying icon to app bundle..."
    bash "$SCRIPT_DIR/set_app_icon.sh" 2>&1 | grep -v "Method" || true
fi

echo ""
echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "📝 Icon Setup:"
if [ "$ICON_COPIED" = true ]; then
    echo "   ✅ Custom icon configured (MacGuardianLogo)"
    echo "   💡 If icon doesn't show in Dock:"
    echo "      1. Quit the app completely (Cmd+Q)"
    echo "      2. Run: ./set_app_icon.sh"
    echo "      3. Run: killall Dock"
    echo "      4. Or restart your Mac"
    echo ""
    echo "   To manually clear icon cache (requires password):"
    echo "      sudo rm -rf /Library/Caches/com.apple.iconservices.store"
    echo "      killall Dock"
else
    echo "   ⚠️  Using default macOS icon"
    echo "   💡 To add custom icon, ensure MacGuardianLogo.png exists in Resources/images/"
fi
echo ""
echo "🚀 To install:"
echo "   cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "   Or drag \"$APP_BUNDLE\" to your Applications folder in Finder"

