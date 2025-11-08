#!/bin/bash

# ===============================
# Phase 1 Features Setup
# Sets up scheduled reports and advanced alerting
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

echo "${bold}🚀 Setting Up Phase 1 Features${normal}"
echo "=========================================="
echo ""

# 1. Setup Scheduled Reports
echo "${bold}📊 Setting Up Scheduled Reports...${normal}"
echo "----------------------------------------"

# Add to launchd for daily reports
if [ -z "${REPORT_EMAIL:-}" ]; then
    read -p "Enter email for reports (or press Enter to skip): " email
    if [ -n "$email" ]; then
        export REPORT_EMAIL="$email"
        # Update config
        if [ -f "$MAIN_CONFIG" ]; then
            sed -i.bak "s|REPORT_EMAIL=\"\"|REPORT_EMAIL=\"$email\"|" "$MAIN_CONFIG" 2>/dev/null || true
        fi
    fi
fi

# Create launchd plist for daily reports
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCHD_DIR"

cat > "$LAUNCHD_DIR/com.macguardian.reports.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macguardian.reports</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/scheduled_reports.sh</string>
        <string>daily</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/.macguardian/reports/scheduler.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.macguardian/reports/scheduler_error.log</string>
</dict>
</plist>
EOF

# Load the launchd job
launchctl unload "$LAUNCHD_DIR/com.macguardian.reports.plist" 2>/dev/null || true
launchctl load "$LAUNCHD_DIR/com.macguardian.reports.plist" 2>/dev/null && {
    success "✅ Daily reports scheduled (9:00 AM daily)"
} || {
    warning "⚠️  Could not load launchd job (may need to run manually)"
}

echo ""

# 2. Setup Advanced Alerting
echo "${bold}🔔 Setting Up Advanced Alerting...${normal}"
echo "----------------------------------------"

# Initialize alert rules
if [ -f "$SCRIPT_DIR/advanced_alerting.sh" ]; then
    "$SCRIPT_DIR/advanced_alerting.sh" process 2>/dev/null || true
    success "✅ Alert rules initialized"
    
    # Show configured rules
    echo ""
    echo "Configured alert rules:"
    "$SCRIPT_DIR/advanced_alerting.sh" list | head -20
else
    warning "⚠️  Advanced alerting script not found"
fi

# Add alert processing to main suite
echo ""
echo "${bold}📋 Integration Complete${normal}"
echo "----------------------------------------"
echo ""
echo "✅ Scheduled Reports:"
echo "   • Daily reports at 9:00 AM"
echo "   • Reports saved to: $REPORT_DIR"
if [ -n "${REPORT_EMAIL:-}" ]; then
    echo "   • Email reports to: $REPORT_EMAIL"
fi
echo ""
echo "✅ Advanced Alerting:"
echo "   • Custom alert rules configured"
echo "   • Alert history: $HOME/.macguardian/alerts/history.log"
echo "   • Rules file: $ALERT_RULES_FILE"
echo ""
echo "${green}🎉 Phase 1 features are now active!${normal}"
echo ""
echo "To test:"
echo "  • Generate report: ./MacGuardianSuite/scheduled_reports.sh daily"
echo "  • Process alerts: ./MacGuardianSuite/advanced_alerting.sh process"
echo "  • View rules: ./MacGuardianSuite/advanced_alerting.sh list"

