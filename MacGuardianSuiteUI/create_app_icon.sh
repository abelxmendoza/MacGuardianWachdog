#!/bin/bash
# Script to create .icns file from PNG for macOS app icon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_PNG="$SCRIPT_DIR/Resources/images/MacGlogo.png"
ICONSET_DIR="$SCRIPT_DIR/Resources/images/MacGlogo.iconset"
ICNS_FILE="$SCRIPT_DIR/Resources/images/MacGlogo.icns"

echo "🎨 Creating app icon from MacGlogo.png..."

# Check if logo exists
if [ ! -f "$LOGO_PNG" ]; then
    echo "❌ Error: Logo file not found at $LOGO_PNG"
    echo "   Please ensure MacGlogo.png exists in Resources/images/"
    exit 1
fi

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Required icon sizes for macOS
sizes=(
    "16:16"
    "32:32"
    "64:64"
    "128:128"
    "256:256"
    "512:512"
    "1024:1024"
)

# Generate all required sizes
for size in "${sizes[@]}"; do
    IFS=':' read -r width height <<< "$size"
    
    # Standard size
    sips -z $width $height "$LOGO_PNG" --out "$ICONSET_DIR/icon_${width}x${width}.png" > /dev/null 2>&1
    
    # @2x retina size (double resolution)
    retina_width=$((width * 2))
    retina_height=$((height * 2))
    sips -z $retina_width $retina_height "$LOGO_PNG" --out "$ICONSET_DIR/icon_${width}x${width}@2x.png" > /dev/null 2>&1
    
    echo "  ✓ Generated ${width}x${width} and ${retina_width}x${retina_height} icons"
done

# Create .icns file
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

if [ -f "$ICNS_FILE" ]; then
    echo "✅ App icon created successfully: $ICNS_FILE"
    echo "   File size: $(du -h "$ICNS_FILE" | cut -f1)"
else
    echo "❌ Error: Failed to create .icns file"
    exit 1
fi

