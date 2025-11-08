#!/bin/bash

# ===============================
# Mac Guardian Suite Configuration
# Centralized configuration file
# ===============================

# Configuration file location
CONFIG_DIR="$HOME/.macguardian"
MAIN_CONFIG="$CONFIG_DIR/config.conf"

# Default settings
DEFAULT_ALERT_EMAIL="abelxmendoza@gmail.com"
DEFAULT_MONITOR_PATHS=("$HOME/Documents" "$HOME/Desktop")
DEFAULT_SCAN_DIR="$HOME/Documents"
DEFAULT_HONEYPOT_DIR="$HOME/Documents/Passwords_DO_NOT_OPEN"
DEFAULT_LOG_DIR="$CONFIG_DIR/logs"

# Initialize configuration if it doesn't exist
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        mkdir -p "$DEFAULT_LOG_DIR"
    fi
    
    if [ ! -f "$MAIN_CONFIG" ]; then
        cat > "$MAIN_CONFIG" <<EOF
# Mac Guardian Suite Configuration
# Edit this file to customize settings

ALERT_EMAIL="$DEFAULT_ALERT_EMAIL"
MONITOR_PATHS=($(printf '"%s" ' "${DEFAULT_MONITOR_PATHS[@]}"))
SCAN_DIR="$DEFAULT_SCAN_DIR"
HONEYPOT_DIR="$DEFAULT_HONEYPOT_DIR"
LOG_DIR="$DEFAULT_LOG_DIR"

# Notification settings
ENABLE_NOTIFICATIONS=true
NOTIFICATION_SOUND=true
NOTIFICATION_COOLDOWN=300  # Seconds between notifications (5 minutes default, prevents spam)

# Scan settings
ENABLE_CLAMAV=true
ENABLE_RKHUNTER=true
ENABLE_FULL_SCAN=false

# Watchdog settings
WATCHDOG_ENABLED=true
CHECK_INTERVAL_HOURS=24

# Report settings
GENERATE_REPORTS=true
REPORT_DIR="$CONFIG_DIR/reports"

# Parallel processing settings
ENABLE_PARALLEL=true
PARALLEL_JOBS=""  # Auto-detect if empty

# ClamAV scan settings
FAST_SCAN_DEFAULT=true
CLAMAV_MAX_FILESIZE=100M
CLAMAV_MAX_FILES=50000

# Report settings
REPORT_EMAIL=""  # Set to enable email reports
REPORT_SCHEDULE="daily"  # daily, weekly, monthly
REPORT_FORMAT="html"  # html, text, json

# Alerting settings
ALERT_EMAIL=""  # Set to enable email alerts
ALERT_ENABLED=true
ALERT_RULES_FILE="$CONFIG_DIR/alerts/rules.conf"
EOF
        echo "✅ Configuration initialized at $MAIN_CONFIG"
    fi
}

# Load configuration
load_config() {
    if [ -f "$MAIN_CONFIG" ]; then
        source "$MAIN_CONFIG"
    else
        # Use defaults
        ALERT_EMAIL="$DEFAULT_ALERT_EMAIL"
        MONITOR_PATHS=("${DEFAULT_MONITOR_PATHS[@]}")
        SCAN_DIR="$DEFAULT_SCAN_DIR"
        HONEYPOT_DIR="$DEFAULT_HONEYPOT_DIR"
        LOG_DIR="$DEFAULT_LOG_DIR"
        ENABLE_NOTIFICATIONS=true
        NOTIFICATION_SOUND=true
        ENABLE_CLAMAV=true
        ENABLE_RKHUNTER=true
        ENABLE_FULL_SCAN=false
        WATCHDOG_ENABLED=true
        CHECK_INTERVAL_HOURS=24
        GENERATE_REPORTS=true
        REPORT_DIR="$CONFIG_DIR/reports"
        ENABLE_PARALLEL=true
        PARALLEL_JOBS=""
        FAST_SCAN_DEFAULT=true
        CLAMAV_MAX_FILESIZE=100M
        CLAMAV_MAX_FILES=50000
    fi
    
    # Ensure directories exist
    mkdir -p "$LOG_DIR"
    mkdir -p "${REPORT_DIR:-$CONFIG_DIR/reports}"
}

# Initialize on source
init_config
load_config

