#!/bin/bash

# ===============================
# MacGuardian Monitor Daemon Installer
# Installs the real-time monitoring daemon as a LaunchAgent
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
# Try new enhanced monitor first, fallback to original
MONITOR_SCRIPT="$SCRIPT_DIR/daemons/mg_monitor.sh"
if [ ! -f "$MONITOR_SCRIPT" ]; then
    MONITOR_SCRIPT="$SCRIPT_DIR/daemons/macguardian_monitor.sh"
fi
PLIST_TEMPLATE="$SCRIPT_DIR/launchd/com.macguardian.monitor.plist"
PLIST_FILE="$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist"
LOG_DIR="$HOME/.macguardian/logs"

# Verify monitor script exists
if [ ! -f "$MONITOR_SCRIPT" ]; then
    error_exit "Monitor script not found: $MONITOR_SCRIPT"
fi

# Create directories
mkdir -p "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# Create plist from template
if [ ! -f "$PLIST_TEMPLATE" ]; then
    error_exit "Plist template not found: $PLIST_TEMPLATE"
fi

# Replace placeholders in plist template
sed "s|PLACEHOLDER_SCRIPT_PATH|$MONITOR_SCRIPT|g; s|PLACEHOLDER_LOG_PATH|$LOG_DIR|g" "$PLIST_TEMPLATE" > "$PLIST_FILE"

chmod 644 "$PLIST_FILE"
success "Created LaunchAgent plist: $PLIST_FILE"

# Unload existing daemon if running
if launchctl list | grep -q "com.macguardian.monitor"; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    success "Unloaded existing monitor daemon"
fi

# Load the daemon
launchctl load "$PLIST_FILE" 2>/dev/null || {
    warning "Failed to load daemon. You may need to run: launchctl load $PLIST_FILE"
}

# Install function
install_monitor() {
    echo "${bold}📅 Installing MacGuardian Monitor Daemon...${normal}"
    echo ""
    
    # Verify monitor script exists
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        error_exit "Monitor script not found: $MONITOR_SCRIPT"
    fi
    
    # Create directories
    mkdir -p "$LAUNCH_AGENTS_DIR" "$LOG_DIR"
    
    # Create plist from template
    if [ ! -f "$PLIST_TEMPLATE" ]; then
        error_exit "Plist template not found: $PLIST_TEMPLATE"
    fi
    
    # Replace placeholders in plist template
    sed "s|PLACEHOLDER_SCRIPT_PATH|$MONITOR_SCRIPT|g; s|PLACEHOLDER_LOG_PATH|$LOG_DIR|g" "$PLIST_TEMPLATE" > "$PLIST_FILE"
    
    chmod 644 "$PLIST_FILE"
    success "Created LaunchAgent plist: $PLIST_FILE"
    
    # Unload existing daemon if running
    if launchctl list | grep -q "com.macguardian.monitor"; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        success "Unloaded existing monitor daemon"
    fi
    
    # Load the daemon
    launchctl load "$PLIST_FILE" 2>/dev/null || {
        warning "Failed to load daemon. You may need to run: launchctl load $PLIST_FILE"
    }
    echo "${bold}📅 Installing MacGuardian Monitor Daemon...${normal}"
    echo ""
    
    success "Monitor daemon installed successfully!"
    echo ""
    info "Monitor daemon will start automatically on login"
    info "Event directory: $HOME/.macguardian/events"
    info "Log directory: $LOG_DIR"
    echo ""
    info "To check status: launchctl list | grep macguardian.monitor"
    info "To stop: launchctl unload $PLIST_FILE"
    info "To start: launchctl load $PLIST_FILE"
    info "To uninstall: $0 --uninstall"
    echo ""
}

# Uninstall function
uninstall_monitor() {
    echo "${bold}🗑️  Uninstalling MacGuardian Monitor Daemon...${normal}"
    echo ""
    
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
        success "Removed LaunchAgent plist"
    fi
    
    # Optionally remove event files (ask first)
    if [ -d "$HOME/.macguardian/events" ]; then
        read -p "Remove event files? (y/N): " remove_events
        if [[ "$remove_events" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.macguardian/events"
            success "Removed event files"
        fi
    fi
    
    echo ""
    success "Monitor daemon uninstalled successfully!"
}

# Main execution
if [ "${1:-}" = "--uninstall" ]; then
    uninstall_monitor
else
    install_monitor
fi

