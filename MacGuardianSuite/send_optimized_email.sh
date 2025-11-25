#!/bin/bash

# Send optimized email with Omega Technologies branded report
# This version ensures the HTML is properly formatted for email clients

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Load SMTP credentials
if [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ]; then
    if [ -f ~/.zshrc ]; then
        eval $(grep "^export SMTP_USERNAME=" ~/.zshrc 2>/dev/null || true)
        eval $(grep "^export SMTP_PASSWORD=" ~/.zshrc 2>/dev/null || true)
    fi
fi

REPORT_EMAIL="${REPORT_EMAIL:-abelxmendoza@gmail.com}"
REPORT_DIR="${REPORT_DIR:-$HOME/.macguardian/reports}"
mkdir -p "$REPORT_DIR"

echo "🛡️ Generating Omega Technologies Branded Security Report..."
echo "=============================================================="
echo ""

# Generate a fresh report
if [ -f "$SCRIPT_DIR/scheduled_reports.sh" ]; then
    source "$SCRIPT_DIR/scheduled_reports.sh"
    main daily html
    # Get the latest report
    report_file=$(ls -t "$REPORT_DIR"/security_report_*.html 2>/dev/null | head -1 | grep -v ".email.html")
else
    error "scheduled_reports.sh not found"
    exit 1
fi

if [ ! -f "$report_file" ] || [ ! -s "$report_file" ]; then
    error "Failed to generate report"
    exit 1
fi

echo "✅ Report generated: $report_file"
echo ""

# Check report size
report_size=$(du -h "$report_file" | cut -f1)
echo "📊 Report size: $report_size"

# Create optimized email HTML (ensure it's a complete HTML document)
email_html_file="${report_file}.email.html"

# Read the report HTML
html_content=$(cat "$report_file")

# Ensure it's a complete HTML document
if ! echo "$html_content" | grep -q "<!DOCTYPE html"; then
    # Wrap in HTML structure if needed
    html_content="<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
</head>
<body>
$html_content
</body>
</html>"
fi

# Write optimized HTML
echo "$html_content" > "$email_html_file"

# Create email body
subject="🛡️ MacGuardian Security Report - Omega Technologies Design Preview"
text_body="MacGuardian Security Report with Omega Technologies Branding

This email showcases the new design featuring:
- Omega Technologies branding
- MacGuardian logo integration  
- Dark theme styling
- Professional security report layout

See attached HTML report for full design preview.

Generated: $(date)
System: $(hostname)

Powered by OMEGA TECHNOLOGIES"

echo "📧 Sending email to: $REPORT_EMAIL"
echo ""

# Send email using Python SMTP
if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
    if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
        # Use Python to send email with proper HTML
        python3 <<PYTHON_SCRIPT
import sys
import os
sys.path.insert(0, "$SCRIPT_DIR")
from send_email import send_email

# Read HTML content
with open("$email_html_file", "r", encoding="utf-8") as f:
    html_content = f.read()

# Send email
smtp_config = {
    "username": "${SMTP_USERNAME}",
    "password": "${SMTP_PASSWORD}",
    "smtp_server": "smtp.gmail.com",
    "smtp_port": 587,
    "use_tls": True
}

success = send_email(
    "$REPORT_EMAIL",
    "$subject",
    """$text_body""",
    html_body=html_content,
    attachment_path="$report_file",
    smtp_config=smtp_config
)

sys.exit(0 if success else 1)
PYTHON_SCRIPT

        if [ $? -eq 0 ]; then
            success "✅ Email sent successfully to $REPORT_EMAIL"
            echo ""
            echo "📋 Email Details:"
            echo "   To: $REPORT_EMAIL"
            echo "   Subject: $subject"
            echo "   Attachment: $(basename "$report_file")"
            echo "   HTML Size: $(du -h "$email_html_file" | cut -f1)"
            echo ""
            echo "💡 Check your inbox to see the new Omega Technologies design!"
            echo ""
            echo "📝 Note: If the email doesn't display correctly:"
            echo "   1. Some email clients may strip HTML/CSS"
            echo "   2. Open the attached HTML file directly in a browser"
            echo "   3. The attached file contains the full report with all styling"
            exit 0
        else
            error "❌ Failed to send email via SMTP"
            echo ""
            echo "💡 Troubleshooting:"
            echo "   1. Check SMTP_USERNAME and SMTP_PASSWORD are set"
            echo "   2. For Gmail, use an App Password (not your regular password)"
            echo "   3. Ensure 2FA is enabled on your Google account"
            exit 1
        fi
    else
        warning "⚠️  SMTP credentials not configured"
        echo ""
        echo "To send emails, set:"
        echo "  export SMTP_USERNAME='your-email@gmail.com'"
        echo "  export SMTP_PASSWORD='your-app-password'"
        echo ""
        echo "Report saved to: $report_file"
        echo "You can open it manually to see the design:"
        echo "  open '$report_file'"
        exit 1
    fi
else
    error "❌ Python3 or send_email.py not found"
    echo ""
    echo "Report saved to: $report_file"
    echo "You can open it manually to see the design:"
    echo "  open '$report_file'"
    exit 1
fi

