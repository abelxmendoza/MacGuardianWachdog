#!/bin/bash

# ===============================
# macOS Permissions Request
# Guides user through granting required permissions
# ===============================

set -euo pipefail

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===============================
# Permission Requests
# ===============================

request_full_disk_access() {
    echo ""
    echo -e "${YELLOW}⚠️  Full Disk Access Required${NC}"
    echo ""
    echo "MacGuardian needs Full Disk Access to monitor file system changes."
    echo ""
    echo "To grant Full Disk Access:"
    echo "  1. Open System Settings"
    echo "  2. Go to Privacy & Security"
    echo "  3. Select Full Disk Access"
    echo "  4. Click the + button"
    echo "  5. Add MacGuardian Suite"
    echo ""
    read -p "Press Enter to open System Settings..."
    
    # Open System Settings to Full Disk Access
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    
    echo ""
    echo -e "${BLUE}After granting Full Disk Access, press Enter to continue...${NC}"
    read
}

request_screen_recording() {
    echo ""
    echo -e "${YELLOW}⚠️  Screen Recording Permission (Optional)${NC}"
    echo ""
    echo "Screen Recording permission is optional but recommended for:"
    echo "  - Screenshot analysis"
    echo "  - Visual security monitoring"
    echo ""
    read -p "Do you want to grant Screen Recording permission? (y/n): " answer
    
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        echo ""
        echo -e "${BLUE}After granting Screen Recording, press Enter to continue...${NC}"
        read
    fi
}

request_accessibility() {
    echo ""
    echo -e "${YELLOW}⚠️  Accessibility Permission (Optional)${NC}"
    echo ""
    echo "Accessibility permission is optional but may be needed for:"
    echo "  - Process monitoring"
    echo "  - System event detection"
    echo ""
    read -p "Do you want to grant Accessibility permission? (y/n): " answer
    
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        echo ""
        echo -e "${BLUE}After granting Accessibility, press Enter to continue...${NC}"
        read
    fi
}

request_notifications() {
    echo ""
    echo -e "${GREEN}📢 Notification Permission${NC}"
    echo ""
    echo "Requesting notification permission..."
    
    # Use osascript to request notification permission
    osascript <<EOF
display notification "MacGuardian Watchdog is requesting notification permission" with title "MacGuardian"
EOF
    
    # Note: Actual notification permission is requested by the SwiftUI app
    echo "Notification permission will be requested when you launch the MacGuardian Suite app."
}

# ===============================
# Main
# ===============================

main() {
    echo "=========================================="
    echo "MacGuardian Permissions Setup"
    echo "=========================================="
    echo ""
    
    request_full_disk_access
    request_screen_recording
    request_accessibility
    request_notifications
    
    echo ""
    echo -e "${GREEN}✅ Permission setup complete!${NC}"
    echo ""
    echo "You can change these permissions later in System Settings > Privacy & Security"
}

main "$@"

