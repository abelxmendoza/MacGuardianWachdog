#!/bin/bash

# ===============================
# MacGuardian Watchdog Uninstaller
# Clean removal of MacGuardian installation
# ===============================

set -euo pipefail

INSTALL_ROOT="/usr/local/macguardian"
CONFIG_DIR="$HOME/.macguardian"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ===============================
# Uninstall Functions
# ===============================

stop_services() {
    echo "Stopping MacGuardian services..."
    
    # Unload launchd services
    if [ -f "$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist" ]; then
        launchctl unload "$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist" 2>/dev/null || true
    fi
    
    if [ -f "$LAUNCH_AGENTS_DIR/com.macguardian.eventbus.plist" ]; then
        launchctl unload "$LAUNCH_AGENTS_DIR/com.macguardian.eventbus.plist" 2>/dev/null || true
    fi
    
    # Kill any running processes
    pkill -f "mg_monitor.sh" 2>/dev/null || true
    pkill -f "event_bus.py" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Services stopped${NC}"
}

remove_launchd_plists() {
    echo "Removing launchd plists..."
    
    rm -f "$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist"
    rm -f "$LAUNCH_AGENTS_DIR/com.macguardian.eventbus.plist"
    
    echo -e "${GREEN}✅ Launchd plists removed${NC}"
}

remove_installation() {
    echo "Removing installation directory..."
    
    if [ -d "$INSTALL_ROOT" ]; then
        if [ "$EUID" -eq 0 ]; then
            rm -rf "$INSTALL_ROOT"
        else
            echo -e "${YELLOW}⚠️  Requires sudo to remove $INSTALL_ROOT${NC}"
            sudo rm -rf "$INSTALL_ROOT"
        fi
        echo -e "${GREEN}✅ Installation directory removed${NC}"
    else
        echo -e "${YELLOW}⚠️  Installation directory not found${NC}"
    fi
}

remove_config() {
    local full_wipe="${1:-false}"
    
    if [ "$full_wipe" = "true" ]; then
        echo "Removing configuration and data..."
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}✅ Configuration removed${NC}"
    else
        echo -e "${YELLOW}⚠️  Configuration preserved at: $CONFIG_DIR${NC}"
        echo "Use --full-wipe to remove configuration"
    fi
}

remove_receipts() {
    echo "Removing package receipts..."
    
    rm -f "/var/db/receipts/com.macguardian.watchdog.bom"
    rm -f "/var/db/receipts/com.macguardian.watchdog.plist"
    
    echo -e "${GREEN}✅ Receipts removed${NC}"
}

remove_socket() {
    echo "Removing Unix Domain Socket..."
    
    rm -f "/tmp/macguardian.sock"
    
    echo -e "${GREEN}✅ Socket removed${NC}"
}

# ===============================
# Main Uninstall
# ===============================

main() {
    local full_wipe=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full-wipe)
                full_wipe=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo "=========================================="
    echo "MacGuardian Watchdog Uninstaller"
    echo "=========================================="
    echo ""
    
    if [ "$full_wipe" = "true" ]; then
        echo -e "${RED}⚠️  FULL WIPE MODE: All data will be deleted${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Uninstall cancelled"
            exit 0
        fi
    fi
    
    stop_services
    remove_launchd_plists
    remove_installation
    remove_config "$full_wipe"
    remove_receipts
    remove_socket
    
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Uninstallation Complete!${NC}"
    echo "=========================================="
    echo ""
    
    if [ "$full_wipe" = "false" ]; then
        echo "Configuration preserved at: $CONFIG_DIR"
        echo "Use --full-wipe to remove configuration"
    fi
}

main "$@"

