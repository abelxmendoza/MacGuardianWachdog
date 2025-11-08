#!/bin/bash

# ===============================
# Mac Guardian Scheduler Installer
# Sets up automated daily/weekly runs
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$LAUNCH_AGENTS_DIR/com.macguardian.daily.plist"
WEEKLY_PLIST_FILE="$LAUNCH_AGENTS_DIR/com.macguardian.weekly.plist"

# Create launchd plist for daily watchdog runs
create_daily_plist() {
    cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macguardian.daily</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/mac_watchdog.sh</string>
        <string>-q</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/.macguardian/logs/watchdog_daily.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.macguardian/logs/watchdog_daily_error.log</string>
</dict>
</plist>
EOF
    chmod 644 "$PLIST_FILE"
    success "Created daily watchdog plist"
}

# Create launchd plist for weekly guardian runs
create_weekly_plist() {
    cat > "$WEEKLY_PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macguardian.weekly</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/mac_guardian.sh</string>
        <string>-y</string>
        <string>--report</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/.macguardian/logs/guardian_weekly.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.macguardian/logs/guardian_weekly_error.log</string>
</dict>
</plist>
EOF
    chmod 644 "$WEEKLY_PLIST_FILE"
    success "Created weekly guardian plist"
}

# Install scheduler
install_scheduler() {
    echo "${bold}📅 Installing Mac Guardian Scheduler...${normal}"
    echo ""
    
    # Create LaunchAgents directory if it doesn't exist
    mkdir -p "$LAUNCH_AGENTS_DIR"
    mkdir -p "$HOME/.macguardian/logs"
    
    # Create plists
    create_daily_plist
    create_weekly_plist
    
    # Load the launch agents
    if launchctl list | grep -q "com.macguardian.daily"; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi
    launchctl load "$PLIST_FILE"
    success "Loaded daily watchdog scheduler"
    
    if launchctl list | grep -q "com.macguardian.weekly"; then
        launchctl unload "$WEEKLY_PLIST_FILE" 2>/dev/null || true
    fi
    launchctl load "$WEEKLY_PLIST_FILE"
    success "Loaded weekly guardian scheduler"
    
    echo ""
    success "Scheduler installed successfully!"
    echo ""
    info "Daily watchdog runs: 2:00 AM every day"
    info "Weekly guardian runs: 3:00 AM every Sunday"
    echo ""
    echo "To uninstall, run: $0 --uninstall"
}

# Uninstall scheduler
uninstall_scheduler() {
    echo "${bold}🗑️  Uninstalling Mac Guardian Scheduler...${normal}"
    echo ""
    
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm "$PLIST_FILE"
        success "Removed daily scheduler"
    fi
    
    if [ -f "$WEEKLY_PLIST_FILE" ]; then
        launchctl unload "$WEEKLY_PLIST_FILE" 2>/dev/null || true
        rm "$WEEKLY_PLIST_FILE"
        success "Removed weekly scheduler"
    fi
    
    echo ""
    success "Scheduler uninstalled successfully!"
}

# Main
if [ "${1:-}" = "--uninstall" ]; then
    uninstall_scheduler
else
    install_scheduler
fi

