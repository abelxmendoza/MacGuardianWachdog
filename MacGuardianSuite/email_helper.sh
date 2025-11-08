#!/bin/bash

# ===============================
# Email Helper Functions
# Provides working email sending via SMTP (Python) or system mail
# ===============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Send email using best available method
send_email_safe() {
    local to_email="$1"
    local subject="$2"
    local body="$3"
    local html_body="${4:-}"
    local attachment="${5:-}"
    
    # Try Python SMTP first (most reliable)
    if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
        # Check if SMTP credentials are configured
        if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            if [ -n "$html_body" ]; then
                python3 "$SCRIPT_DIR/send_email.py" "$to_email" "$subject" "$body" --html "$html_body" ${attachment:+"--attachment" "$attachment"} --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>&1 && return 0
            else
                python3 "$SCRIPT_DIR/send_email.py" "$to_email" "$subject" "$body" ${attachment:+"--attachment" "$attachment"} --username "$SMTP_USERNAME" --password "$SMTP_PASSWORD" 2>&1 && return 0
            fi
        fi
    fi
    
    # Fallback: Try system mail (may not actually send on macOS)
    if command -v mail &> /dev/null; then
        if [ -n "$attachment" ] && [ -f "$attachment" ]; then
            echo "$body" | mail -s "$subject" -a "$attachment" "$to_email" 2>/dev/null && return 0
        else
            echo "$body" | mail -s "$subject" "$to_email" 2>/dev/null && return 0
        fi
    fi
    
    # Last resort: sendmail
    if command -v sendmail &> /dev/null; then
        {
            echo "To: $to_email"
            echo "Subject: $subject"
            [ -n "$html_body" ] && echo "Content-Type: text/html; charset=UTF-8" || echo "Content-Type: text/plain; charset=UTF-8"
            echo ""
            [ -n "$html_body" ] && echo "$html_body" || echo "$body"
        } | sendmail "$to_email" 2>/dev/null && return 0
    fi
    
    return 1
}

# Check email configuration
check_email_config() {
    echo "📧 Email Configuration Check"
    echo "----------------------------------------"
    
    # Check Python SMTP
    if command -v python3 &> /dev/null && [ -f "$SCRIPT_DIR/send_email.py" ]; then
        echo "✅ Python SMTP sender available"
        
        if [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            echo "✅ SMTP credentials configured"
            echo "   Username: ${SMTP_USERNAME}"
            return 0
        else
            echo "⚠️  SMTP credentials not configured"
            echo ""
            echo "To enable SMTP email (recommended):"
            echo "  1. For Gmail: Create an App Password"
            echo "     • Go to: https://myaccount.google.com/apppasswords"
            echo "     • Generate an app password"
            echo "  2. Set environment variables:"
            echo "     export SMTP_USERNAME='your-email@gmail.com'"
            echo "     export SMTP_PASSWORD='your-app-password'"
            echo "  3. Or add to ~/.zshrc for persistence:"
            echo "     echo 'export SMTP_USERNAME=\"your-email@gmail.com\"' >> ~/.zshrc"
            echo "     echo 'export SMTP_PASSWORD=\"your-app-password\"' >> ~/.zshrc"
            return 1
        fi
    else
        echo "⚠️  Python SMTP sender not available"
    fi
    
    # Check system mail
    if command -v mail &> /dev/null; then
        echo "⚠️  System mail available (may not actually send on macOS)"
    fi
    
    return 1
}

