#!/bin/bash

# ===============================
# Launchd Service Setup
# Creates and configures launchd plists for MacGuardian
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="/usr/local/macguardian"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
CONFIG_DIR="$HOME/.macguardian"

# Ensure LaunchAgents directory exists
mkdir -p "$LAUNCH_AGENTS_DIR"

# ===============================
# Monitor Service Plist
# ===============================

create_monitor_plist() {
    cat > "$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macguardian.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$INSTALL_ROOT/daemons/mg_monitor.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/logs/monitor.log</string>
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/logs/monitor.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF
    
    chmod 644 "$LAUNCH_AGENTS_DIR/com.macguardian.monitor.plist"
    echo "✅ Monitor service plist created"
}

# ===============================
# Event Bus Service Plist
# ===============================

create_eventbus_plist() {
    cat > "$LAUNCH_AGENTS_DIR/com.macguardian.eventbus.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macguardian.eventbus</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$INSTALL_ROOT/outputs/event_bus.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/logs/eventbus.log</string>
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/logs/eventbus.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>PYTHONUNBUFFERED</key>
        <string>1</string>
    </dict>
</dict>
</plist>
EOF
    
    chmod 644 "$LAUNCH_AGENTS_DIR/com.macguardian.eventbus.plist"
    echo "✅ Event Bus service plist created"
}

# ===============================
# Main
# ===============================

main() {
    echo "Setting up launchd services..."
    
    create_monitor_plist
    create_eventbus_plist
    
    echo "✅ Launchd services configured"
}

main "$@"

