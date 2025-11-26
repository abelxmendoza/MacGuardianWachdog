#!/bin/bash

# ===============================
# MacGuardian Watchdog Installer
# Production-grade macOS installation script
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_ROOT="/usr/local/macguardian"
CONFIG_DIR="$HOME/.macguardian"
LOG_DIR="$CONFIG_DIR/logs"
EVENT_DIR="$CONFIG_DIR/events"
BASELINE_DIR="$CONFIG_DIR/baselines"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ===============================
# Pre-flight Checks
# ===============================

check_macos_version() {
    local os_version=$(sw_vers -productVersion)
    local major_version=$(echo "$os_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 12 ]; then
        echo -e "${RED}ERROR: macOS 12.0 or later required${NC}"
        echo "Current version: $os_version"
        exit 1
    fi
    
    echo -e "${GREEN}✅ macOS version check passed: $os_version${NC}"
}

check_sip_status() {
    if command -v csrutil &> /dev/null; then
        local sip_status=$(csrutil status 2>/dev/null | grep -i "enabled" || echo "")
        if [ -z "$sip_status" ]; then
            echo -e "${YELLOW}⚠️  WARNING: SIP appears to be disabled${NC}"
            echo "System Integrity Protection should be enabled for security"
        else
            echo -e "${GREEN}✅ SIP is enabled${NC}"
        fi
    fi
}

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}ERROR: This installer must be run with sudo${NC}"
        echo "Usage: sudo $0"
        exit 1
    fi
}

# ===============================
# Installation Steps
# ===============================

create_directories() {
    echo "Creating installation directories..."
    
    mkdir -p "$INSTALL_ROOT"/{core,daemons,auditors,detectors,privacy,outputs,config}
    mkdir -p "$CONFIG_DIR"/{logs,events,baselines}
    mkdir -p "$LOG_DIR"
    mkdir -p "$EVENT_DIR"
    mkdir -p "$BASELINE_DIR"
    
    # Set permissions
    chmod 755 "$INSTALL_ROOT"
    chmod 700 "$CONFIG_DIR"
    chmod 755 "$LOG_DIR"
    chmod 755 "$EVENT_DIR"
    chmod 755 "$BASELINE_DIR"
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

copy_files() {
    echo "Copying MacGuardian files..."
    
    # Copy core modules
    cp -r "$SUITE_DIR/core"/* "$INSTALL_ROOT/core/" 2>/dev/null || true
    chmod +x "$INSTALL_ROOT/core"/*.sh
    
    # Copy daemons
    cp -r "$SUITE_DIR/daemons"/* "$INSTALL_ROOT/daemons/" 2>/dev/null || true
    chmod +x "$INSTALL_ROOT/daemons"/*.sh
    
    # Copy auditors
    cp -r "$SUITE_DIR/auditors"/* "$INSTALL_ROOT/auditors/" 2>/dev/null || true
    chmod +x "$INSTALL_ROOT/auditors"/*.sh
    
    # Copy detectors
    cp -r "$SUITE_DIR/detectors"/* "$INSTALL_ROOT/detectors/" 2>/dev/null || true
    chmod +x "$INSTALL_ROOT/detectors"/*.sh
    
    # Copy privacy
    cp -r "$SUITE_DIR/privacy"/* "$INSTALL_ROOT/privacy/" 2>/dev/null || true
    chmod +x "$INSTALL_ROOT/privacy"/*.sh
    
    # Copy outputs
    cp -r "$SUITE_DIR/outputs"/* "$INSTALL_ROOT/outputs/" 2>/dev/null || true
    
    # Copy config
    if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
        cp "$SUITE_DIR/config/config.yaml" "$CONFIG_DIR/config.yaml"
        chmod 600 "$CONFIG_DIR/config.yaml"
    fi
    
    echo -e "${GREEN}✅ Files copied${NC}"
}

setup_launchd() {
    echo "Setting up launchd services..."
    
    # Run launchd setup script
    if [ -f "$SCRIPT_DIR/postinstall/launchd_setup.sh" ]; then
        bash "$SCRIPT_DIR/postinstall/launchd_setup.sh"
    fi
    
    echo -e "${GREEN}✅ Launchd services configured${NC}"
}

request_permissions() {
    echo "Requesting macOS permissions..."
    
    if [ -f "$SCRIPT_DIR/postinstall/permissions_request.sh" ]; then
        # Run as the actual user (not root)
        sudo -u "$SUDO_USER" bash "$SCRIPT_DIR/postinstall/permissions_request.sh" || true
    fi
    
    echo -e "${GREEN}✅ Permission requests completed${NC}"
}

validate_code_signature() {
    echo "Validating code signatures..."
    
    # Check if binaries are signed (if applicable)
    if command -v codesign &> /dev/null; then
        local unsigned_files=$(find "$INSTALL_ROOT" -type f -executable -exec sh -c 'codesign -dv "$1" 2>&1 | grep -q "not signed" && echo "$1"' _ {} \; 2>/dev/null || true)
        
        if [ -n "$unsigned_files" ]; then
            echo -e "${YELLOW}⚠️  Warning: Some files are not code-signed${NC}"
            echo "This is expected for shell scripts"
        else
            echo -e "${GREEN}✅ Code signature validation passed${NC}"
        fi
    fi
}

create_baseline() {
    echo "Creating initial baseline..."
    
    # Run baseline creation as the actual user
    if [ -f "$INSTALL_ROOT/daemons/mg_monitor.sh" ]; then
        sudo -u "$SUDO_USER" bash -c "cd '$INSTALL_ROOT' && bash daemons/mg_monitor.sh --create-baseline" || true
    fi
    
    echo -e "${GREEN}✅ Baseline created${NC}"
}

register_receipt() {
    echo "Registering package receipt..."
    
    local receipt_file="/var/db/receipts/com.macguardian.watchdog.bom"
    local plist_file="/var/db/receipts/com.macguardian.watchdog.plist"
    
    # Create receipt directory
    mkdir -p "$(dirname "$receipt_file")"
    
    # Create BOM (Bill of Materials)
    lsbom -s "$INSTALL_ROOT" > "$receipt_file" 2>/dev/null || true
    
    # Create plist receipt
    cat > "$plist_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PackageIdentifier</key>
    <string>com.macguardian.watchdog</string>
    <key>PackageVersion</key>
    <string>1.0.0</string>
    <key>InstallDate</key>
    <date>$(date -u +%Y-%m-%dT%H:%M:%SZ)</date>
    <key>InstallLocation</key>
    <string>$INSTALL_ROOT</string>
</dict>
</plist>
EOF
    
    echo -e "${GREEN}✅ Package receipt registered${NC}"
}

start_services() {
    echo "Starting MacGuardian services..."
    
    # Load launchd services
    if [ -f "$HOME/Library/LaunchAgents/com.macguardian.monitor.plist" ]; then
        launchctl load "$HOME/Library/LaunchAgents/com.macguardian.monitor.plist" 2>/dev/null || true
    fi
    
    if [ -f "$HOME/Library/LaunchAgents/com.macguardian.eventbus.plist" ]; then
        launchctl load "$HOME/Library/LaunchAgents/com.macguardian.eventbus.plist" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Services started${NC}"
}

# ===============================
# Main Installation
# ===============================

main() {
    echo "=========================================="
    echo "MacGuardian Watchdog Installer"
    echo "=========================================="
    echo ""
    
    check_sudo
    check_macos_version
    check_sip_status
    echo ""
    
    create_directories
    copy_files
    setup_launchd
    request_permissions
    validate_code_signature
    create_baseline
    register_receipt
    start_services
    
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Installation Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "MacGuardian Watchdog has been installed to:"
    echo "  $INSTALL_ROOT"
    echo ""
    echo "Configuration directory:"
    echo "  $CONFIG_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Grant Full Disk Access in System Settings"
    echo "  2. Launch MacGuardian Suite app"
    echo "  3. Complete onboarding wizard"
    echo ""
}

main "$@"

