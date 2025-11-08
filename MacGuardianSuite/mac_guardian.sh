#!/bin/bash

# -----------------------------
# Mac Guardian Script 🧹🔒
# Cleans, updates, and secures your Mac
# Built for both beginners and pros
# Optimized for macOS
# -----------------------------

set -euo pipefail

# Global error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    # Only log if it's a real error (not from a function that returns non-zero intentionally)
    if [ $exit_code -ne 0 ] && [ "${CONTINUE_ON_ERROR:-false}" != "true" ]; then
        local error_msg="Script error at line $line_no (exit code: $exit_code)"
        log_message "ERROR" "$error_msg"
        # Track error in database
        if type track_error &> /dev/null; then
            track_error "$error_msg" "mac_guardian.sh" "$line_no" "script_error" "high" "false" ""
        fi
    fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities and config
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Parse command line arguments
parse_args "$@"

# Enable fast scan by default (unless explicitly disabled)
if [ "${FAST_SCAN_DEFAULT:-true}" = true ] && [ "${FAST_SCAN:-}" != false ]; then
    FAST_SCAN=true
fi

# Initialize report if requested
REPORT_FILE=""
if [ "$GENERATE_REPORT" = true ]; then
    REPORT_FILE="${REPORT_DIR:-$CONFIG_DIR/reports}/guardian_report_$(date +%Y%m%d_%H%M%S).html"
    mkdir -p "$(dirname "$REPORT_FILE")"
    report_header "Mac Guardian Security Report" "$REPORT_FILE"
    REPORT_CONTENT=""
fi

# Track issues for summary
ISSUES_FOUND=0
WARNINGS_FOUND=0

# Friendly intro
if [ "$QUIET" != true ]; then
    echo "${bold}👋 Welcome to Mac Guardian — Your System's Cleanup & Security Assistant${normal}"
    echo "Let's get your Mac up to date, clean, and safe. This may take a few minutes."
    echo ""
fi

log_message "INFO" "Mac Guardian started"

# Homebrew check
if ! command -v brew &> /dev/null; then
    error_exit "Homebrew not found. Please install Homebrew first from https://brew.sh"
fi

# Homebrew updates
if [ "$SKIP_UPDATES" != true ]; then
    if [ "$QUIET" != true ]; then
        echo "${bold}🔧 Step 1: Updating Homebrew (Mac's app manager)...${normal}"
    fi
    
    if brew update 2>&1 | tee -a "${LOG_DIR:-$CONFIG_DIR/logs}/brew_update.log"; then
        success "Homebrew is up to date."
        log_message "SUCCESS" "Homebrew updated"
    else
        warning "Homebrew update encountered issues, continuing..."
        WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        log_message "WARNING" "Homebrew update failed"
    fi

    if [ "$QUIET" != true ]; then
        echo ""
        echo "${bold}⬆️  Upgrading installed tools...${normal}"
    fi
    
    if brew upgrade 2>&1 | tee -a "${LOG_DIR:-$CONFIG_DIR/logs}/brew_upgrade.log"; then
        success "All tools upgraded."
        log_message "SUCCESS" "Homebrew packages upgraded"
    else
        warning "Some packages may have failed to upgrade."
        WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    fi

    if [ "$QUIET" != true ]; then
        echo ""
        echo "${bold}🗑️  Cleaning out old versions...${normal}"
    fi
    
    if brew cleanup 2>&1; then
        success "Cleanup complete."
    else
        warning "Cleanup encountered some issues."
        WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
    fi
else
    if [ "$QUIET" != true ]; then
        info "Skipping Homebrew updates (--skip-updates flag)"
    fi
fi

# macOS system update (interactive unless --yes flag)
if [ "$SKIP_UPDATES" != true ]; then
    if [ "$QUIET" != true ]; then
        echo ""
    fi
    
    if [ "$INTERACTIVE" = true ]; then
        read -p "${bold}📦 Do you want to check for macOS system updates? (y/n): ${normal}" systemUpdate
    else
        systemUpdate="n"  # Default to no in non-interactive mode
    fi
    
    if [[ "$systemUpdate" =~ ^[Yy]$ ]]; then
        if [ "$QUIET" != true ]; then
            echo "${bold}🔍 Looking for system updates...${normal}"
        fi
        
        if softwareupdate -l 2>&1; then
            if [ "$INTERACTIVE" = true ]; then
                read -p "${bold}⚙️  Install all available updates now? (this might restart your Mac) (y/n): ${normal}" installNow
            else
                installNow="n"  # Default to no in non-interactive mode
            fi
            
            if [[ "$installNow" =~ ^[Yy]$ ]]; then
                check_sudo
                if sudo softwareupdate -i -a 2>&1; then
                    success "System updates installed successfully."
                    send_notification "Mac Guardian" "System updates installed successfully" "${NOTIFICATION_SOUND:-true}"
                    log_message "SUCCESS" "System updates installed"
                else
                    warning "Some updates may have failed or require a restart."
                    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
                fi
            else
                if [ "$QUIET" != true ]; then
                    echo "⏩ Skipped installing updates."
                fi
            fi
        else
            warning "Could not check for updates. You may need to check System Settings manually."
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
    else
        if [ "$QUIET" != true ]; then
            echo "⏩ Skipped checking for macOS updates."
        fi
    fi
fi

# Additional Security Checks (Run in Parallel)
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}🔍 Step 2: Running Security Checks (Parallel Mode)...${normal}"
    if [ "${ENABLE_PARALLEL:-true}" = true ]; then
        info "Running security checks in parallel for faster execution"
    fi
fi

# Initialize parallel processing if enabled
if [ "${ENABLE_PARALLEL:-true}" = true ]; then
    init_parallel
fi

# Run security checks in parallel
SECURITY_RESULTS="$CONFIG_DIR/security_check_results_$$.txt"
> "$SECURITY_RESULTS"

# Source utils to ensure functions are available
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
fi

# Run checks in parallel with proper function sourcing
(
    source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
    check_disk_space 85
) >> "$SECURITY_RESULTS" 2>&1 &
JOB_PIDS+=($!)
JOB_NAMES+=("disk_space_check")
ACTIVE_JOBS=$((ACTIVE_JOBS + 1))

(
    source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
    check_suspicious_processes
) >> "$SECURITY_RESULTS" 2>&1 &
JOB_PIDS+=($!)
JOB_NAMES+=("process_check")
ACTIVE_JOBS=$((ACTIVE_JOBS + 1))

(
    source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
    check_network_connections
) >> "$SECURITY_RESULTS" 2>&1 &
JOB_PIDS+=($!)
JOB_NAMES+=("network_check")
ACTIVE_JOBS=$((ACTIVE_JOBS + 1))

(
    source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true
    check_file_permissions "$HOME/Documents"
) >> "$SECURITY_RESULTS" 2>&1 &
JOB_PIDS+=($!)
JOB_NAMES+=("permissions_check")
ACTIVE_JOBS=$((ACTIVE_JOBS + 1))

# Wait for all security checks to complete
wait_all_jobs

# Process results
if [ -f "$SECURITY_RESULTS" ]; then
    check_issues=$(grep -c "⚠️\|❌" "$SECURITY_RESULTS" 2>/dev/null | tr -d ' ' || echo "0")
    check_issues=${check_issues:-0}
    if [ "$check_issues" -gt 0 ] 2>/dev/null; then
        ISSUES_FOUND=$((ISSUES_FOUND + check_issues))
        if [ "$VERBOSE" = true ]; then
            cat "$SECURITY_RESULTS"
        fi
    fi
    # Show results even if no issues (for success messages)
    if [ "$VERBOSE" = true ] && [ "$QUIET" != true ]; then
        cat "$SECURITY_RESULTS" | grep -E "✅|⚠️|❌" || true
    fi
    rm -f "$SECURITY_RESULTS"
fi

# ClamAV antivirus
if [ "$SKIP_SCAN" != true ] && [ "${ENABLE_CLAMAV:-true}" = true ]; then
    if [ "$QUIET" != true ]; then
        echo ""
        echo "${bold}🛡️ Step 3: Running Antivirus Scan (ClamAV)...${normal}"
    fi

    # Ensure ClamAV is installed
    if ! command -v clamscan &> /dev/null; then
        if [ "$QUIET" != true ]; then
            echo "📦 ClamAV not found. Installing it now..."
        fi
        # Error handling for ClamAV installation
        set +e  # Temporarily disable exit on error
        if brew install clamav 2>&1; then
            success "ClamAV installed successfully."
            log_message "SUCCESS" "ClamAV installed"
        else
            warning "ClamAV installation failed. Skipping antivirus scan."
            log_message "WARNING" "ClamAV installation failed, skipping scan"
            SKIP_CLAMAV=true
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
        set -e  # Re-enable exit on error
    fi

    if [ "${SKIP_CLAMAV:-false}" != "true" ]; then
        if [ "$QUIET" != true ]; then
            echo "📥 Updating virus definitions..."
        fi
        # Error handling for freshclam
        set +e  # Temporarily disable exit on error
        if freshclam 2>&1; then
            success "Virus definitions updated."
            log_message "SUCCESS" "ClamAV definitions updated"
        else
            warning "Could not update virus definitions. Continuing with existing database..."
            log_message "WARNING" "ClamAV definition update failed, using existing database"
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
        set -e  # Re-enable exit on error

        # Use configured scan directory
        SCAN_TARGET="${SCAN_DIR:-$HOME/Documents}"
        if [ -d "$SCAN_TARGET" ]; then
            # Use fast scanner if available, otherwise use optimized clamscan
            if [ -f "$SCRIPT_DIR/clamav_fast.sh" ] && [ "${FAST_SCAN:-true}" != false ]; then
                if [ "$QUIET" != true ]; then
                    echo "🔍 Fast scanning $SCAN_TARGET for viruses..."
                    echo "   • Skipping large files and media"
                    echo "   • Optimized for speed"
                fi
                # Error handling for ClamAV scan
                set +e  # Temporarily disable exit on error
                SCAN_OUTPUT=$(bash "$SCRIPT_DIR/clamav_fast.sh" "$SCAN_TARGET" 100M 50000 2>&1)
                SCAN_EXIT=$?
                set -e  # Re-enable exit on error
                
                # Log scan result
                if [ $SCAN_EXIT -ne 0 ] && [ $SCAN_EXIT -ne 1 ]; then
                    # Exit code 1 is normal for ClamAV (means threats found), other codes are errors
                    log_message "WARNING" "ClamAV scan encountered an error (exit code: $SCAN_EXIT)"
                fi
            else
                # Optimized clamscan with exclusions
                if [ "$QUIET" != true ]; then
                    echo "🔍 Scanning $SCAN_TARGET for viruses (optimized for speed)..."
                    echo "   • Skipping files larger than 100MB"
                    echo "   • Excluding media and cache files"
                fi
                
                # Create exclude pattern file
                EXCLUDE_PATTERNS="$CONFIG_DIR/clamav_excludes.txt"
                cat > "$EXCLUDE_PATTERNS" <<'EXCLUDEEOF'
*.log
*.tmp
*.cache
*.swp
*.bak
*.old
*.DS_Store
*/.git/*
*/.Trash/*
*/Library/Caches/*
*/node_modules/*
*.mp4
*.mov
*.avi
*.mkv
*.mp3
*.wav
*.flac
*.jpg
*.jpeg
*.png
*.gif
*.pdf
*.zip
*.tar
*.gz
*.dmg
*.iso
EXCLUDEEOF
                
                # Fast scan with limits (with error handling)
                set +e  # Temporarily disable exit on error
                SCAN_OUTPUT=$(clamscan -r \
                    --bell \
                    -i \
                    --max-filesize=100M \
                    --max-scansize=200M \
                    --max-files=50000 \
                    --exclude-from="$EXCLUDE_PATTERNS" \
                    --no-summary \
                    "$SCAN_TARGET" 2>&1)
                SCAN_EXIT=$?
                set -e  # Re-enable exit on error
                rm -f "$EXCLUDE_PATTERNS"
                
                # Log scan result
                if [ $SCAN_EXIT -ne 0 ] && [ $SCAN_EXIT -ne 1 ]; then
                    log_message "WARNING" "ClamAV scan encountered an error (exit code: $SCAN_EXIT)"
                fi
            fi
            
            # Error handling for scan results
            set +e  # Temporarily disable exit on error
            if [ $SCAN_EXIT -eq 0 ]; then
                success "Antivirus scan finished - no threats found."
                log_message "SUCCESS" "Antivirus scan completed - no threats"
            elif [ $SCAN_EXIT -eq 1 ]; then
                # Exit code 1 means threats were found (this is expected behavior from ClamAV)
                warning "Antivirus scan found potential threats! Check the output above."
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
                send_notification "Mac Guardian Alert" "Potential threats detected!" "${NOTIFICATION_SOUND:-true}" "critical"
                log_message "ALERT" "Antivirus found threats"
            else
                # Other exit codes indicate errors
                warning "Antivirus scan encountered an error (exit code: $SCAN_EXIT)."
                log_message "WARNING" "ClamAV scan error (exit code: $SCAN_EXIT)"
                WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
            fi
            set -e  # Re-enable exit on error
        else
            warning "Scan directory not found at $SCAN_TARGET. Skipping scan."
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
    fi
else
    if [ "$QUIET" != true ]; then
        info "Skipping antivirus scan (--skip-scan flag or disabled in config)"
    fi
fi

# Rootkit check
if [ "$SKIP_SCAN" != true ] && [ "${ENABLE_RKHUNTER:-true}" = true ]; then
    if [ "$QUIET" != true ]; then
        echo ""
        echo "${bold}💀 Step 4: Checking for hidden rootkits (rkhunter)...${normal}"
    fi
    
    if ! command -v rkhunter &> /dev/null; then
        if [ "$QUIET" != true ]; then
            echo "📦 Rootkit Hunter not found. Installing it now..."
        fi
        if brew install rkhunter 2>&1; then
            success "Rootkit Hunter installed successfully."
            log_message "SUCCESS" "rkhunter installed"
        else
            warning "Rootkit Hunter installation failed. Skipping rootkit check."
            SKIP_RKHUNTER=true
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
    fi

    if [ "${SKIP_RKHUNTER:-false}" != "true" ]; then
        check_sudo
        if [ "$QUIET" != true ]; then
            echo "📥 Updating rootkit database..."
        fi
        if sudo rkhunter --update > /dev/null 2>&1; then
            success "Rootkit database updated."
        else
            warning "Could not update rootkit database."
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
        
        if [ "$QUIET" != true ]; then
            echo "🔍 Running rootkit scan..."
        fi
        if sudo rkhunter --check --sk 2>&1; then
            success "Rootkit scan completed."
            log_message "SUCCESS" "Rootkit scan completed"
        else
            warning "Rootkit scan completed with warnings. Review output above."
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
        fi
    fi
else
    if [ "$QUIET" != true ]; then
        info "Skipping rootkit scan (--skip-scan flag or disabled in config)"
    fi
fi

# Firewall check
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}🧱 Step 5: Checking Firewall status...${normal}"
fi
if FIREWALL_STATUS=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null); then
    case $FIREWALL_STATUS in
        0) warning "Firewall is OFF. You should enable it (System Settings > Network > Firewall)."; WARNINGS_FOUND=$((WARNINGS_FOUND + 1));;
        1) warning "Firewall is partially on. Turn it fully ON for better security."; WARNINGS_FOUND=$((WARNINGS_FOUND + 1));;
        2) success "Firewall is ON and protecting your Mac.";;
        *) warning "Unknown firewall status: $FIREWALL_STATUS"; WARNINGS_FOUND=$((WARNINGS_FOUND + 1));;
    esac
else
    warning "Could not read firewall status. Check System Settings manually."
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
fi

# LuLu check (optional outbound firewall)
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}🔎 Step 6: Checking for LuLu (outbound firewall tool)...${normal}"
fi
if pgrep -x LuLu &> /dev/null || pgrep -f "LuLu" &> /dev/null; then
    success "LuLu is running and monitoring outbound connections."
else
    info "LuLu is not active. Download it here: https://objective-see.org/products/lulu.html"
fi

# Gatekeeper status check
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}🔐 Step 7: Checking Gatekeeper status...${normal}"
fi
if spctl --status 2>/dev/null | grep -q "enabled"; then
    success "Gatekeeper is enabled and protecting your Mac."
else
    warning "Gatekeeper appears to be disabled."
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
fi

# System Integrity Protection (SIP) check
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}🛡️  Step 8: Checking System Integrity Protection (SIP)...${normal}"
fi
if csrutil status 2>/dev/null | grep -q "enabled"; then
    success "SIP is enabled and protecting system files."
elif csrutil status 2>/dev/null | grep -q "disabled"; then
    warning "SIP is disabled. This reduces system security."
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
else
    info "Could not determine SIP status (may require Recovery Mode to check)."
fi

# Backup reminder
if [ "$QUIET" != true ]; then
    echo ""
    echo "${bold}💾 Step 9: Backup Status${normal}"
fi
if tmutil status 2>/dev/null | grep -q "Running = 1"; then
    success "Time Machine appears to be running."
else
    warning "Time Machine may not be active. Make sure to back up your important files."
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
fi

# Final message
if [ "$QUIET" != true ]; then
    echo ""
    if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
        echo "${bold}${green}🎉 All done! Your Mac is now cleaner, safer, and more up to date.${normal}"
        # Don't send notification when everything is clear (reduces spam)
        # Only notify on actual threats
    elif [ $ISSUES_FOUND -gt 0 ]; then
        echo "${bold}${red}⚠️  Completed with $ISSUES_FOUND issue(s) and $WARNINGS_FOUND warning(s) found.${normal}"
        send_notification "Mac Guardian Alert" "Security issues detected!" "${NOTIFICATION_SOUND:-true}" "critical"
    else
        echo "${bold}${yellow}✅ Completed with $WARNINGS_FOUND warning(s). Review the output above.${normal}"
    fi
    echo "Run this script once a week or so to keep your system fresh. Stay secure out there, warrior. 🔐🧠💻"
fi

# Generate report if requested
if [ "$GENERATE_REPORT" = true ] && [ -n "$REPORT_FILE" ]; then
    report_footer "$REPORT_FILE"
    if [ "$QUIET" != true ]; then
        success "Report generated: $REPORT_FILE"
    fi
    log_message "INFO" "Report generated: $REPORT_FILE"
fi

log_message "INFO" "Mac Guardian completed - Issues: $ISSUES_FOUND, Warnings: $WARNINGS_FOUND"

# Process alert rules if advanced alerting is available
if [ -f "$SCRIPT_DIR/advanced_alerting.sh" ]; then
    source "$SCRIPT_DIR/advanced_alerting.sh" 2>/dev/null || true
    if type process_alert_rules &> /dev/null; then
        process_alert_rules 2>/dev/null || true
    fi
fi

# Always exit with success (0) - issues are already logged and reported
# Exit code 0 means the script ran successfully, not that no issues were found
exit 0
