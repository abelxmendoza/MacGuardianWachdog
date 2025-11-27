#!/bin/bash
APP_DIR=".build/release/MacGuardian Suite.app"
ICON="Resources/AppIcon.icns"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$ROOT_DIR/$APP_DIR" ]; then
    echo "❌ App bundle not found: $ROOT_DIR/$APP_DIR"
    echo "   Run ./build_app.sh first"
    exit 1
fi

if [ ! -f "$ROOT_DIR/$ICON" ]; then
    echo "❌ Icon file not found: $ROOT_DIR/$ICON"
    exit 1
fi

cp "$ROOT_DIR/$ICON" "$ROOT_DIR/$APP_DIR/Contents/Resources/AppIcon.icns"
touch "$ROOT_DIR/$APP_DIR"
echo "✅ Icon set!"
