#!/bin/bash

# ===============================
# 🔍 Mac Security Audit v1.0
# Comprehensive Security Auditing & Hardening
# Enterprise-grade security assessment
# ===============================

set -euo pipefail

# Global error handler
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    if [ $exit_code -ne 0 ] && [ "${CONTINUE_ON_ERROR:-false}" != "true" ]; then
        log_message "ERROR" "Script error at line $line_no (exit code: $exit_code)"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Security Audit specific config
AUDIT_DIR="$CONFIG_DIR/security_audit"
AUDIT_REPORT="$AUDIT_DIR/audit_report_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$AUDIT_DIR"

# Parse arguments
QUIET=false
VERBOSE=false
RUN_LYNIS=false
CHECK_FILEVAULT=true
CHECK_LAUNCH_ITEMS=true
CHECK_CERTIFICATES=true
CHECK_SIP=true
CHECK_GATEKEEPER=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quiet) QUIET=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        --lynis) RUN_LYNIS=true; shift ;;
        --no-filevault) CHECK_FILEVAULT=false; shift ;;
        --no-launch) CHECK_LAUNCH_ITEMS=false; shift ;;
        --no-certs) CHECK_CERTIFICATES=false; shift ;;
        -h|--help)
            cat <<EOF
Mac Security Audit - Comprehensive Security Assessment

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help
    -q, --quiet         Minimal output
    -v, --verbose       Detailed output
    --lynis             Run full lynis security audit
    --no-filevault      Skip FileVault check
    --no-launch         Skip launch items check
    --no-certs          Skip certificate checks

EOF
            exit 0
            ;;
        *) shift ;;
    esac
done

# Check FileVault encryption status
check_filevault() {
    if [ "$CHECK_FILEVAULT" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🔐 FileVault Encryption Status...${normal}"
    fi
    
    local fv_status=""
    if command -v fdesetup &> /dev/null; then
        set +e
        fv_status=$(fdesetup status 2>/dev/null)
        set -e
        
        if echo "$fv_status" | grep -q "FileVault is On"; then
            success "FileVault is enabled - Disk encryption is active"
            log_message "SUCCESS" "FileVault encryption enabled"
            return 0
        elif echo "$fv_status" | grep -q "FileVault is Off"; then
            warning "FileVault is DISABLED - Your disk is not encrypted!"
            log_message "WARNING" "FileVault encryption disabled"
            return 1
        else
            warning "Could not determine FileVault status"
            log_message "WARNING" "FileVault status unknown"
            return 1
        fi
    else
        warning "fdesetup command not available"
        return 1
    fi
}

# Check launch agents and daemons for suspicious items
check_launch_items() {
    if [ "$CHECK_LAUNCH_ITEMS" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🚀 Launch Items & Persistence Mechanisms...${normal}"
    fi
    
    local issues=0
    local suspicious_patterns=("miner" "crypto" "bitcoin" "malware" "backdoor" "trojan" "keylogger")
    
    # Check user launch agents
    local user_agents="$HOME/Library/LaunchAgents"
    if [ -d "$user_agents" ]; then
        local agent_count=$(find "$user_agents" -name "*.plist" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$agent_count" -gt 0 ]; then
            info "Found $agent_count user launch agent(s)"
            
            # Check for suspicious patterns
            for plist in "$user_agents"/*.plist; do
                if [ -f "$plist" ]; then
                    local basename_plist=$(basename "$plist")
                    for pattern in "${suspicious_patterns[@]}"; do
                        if echo "$basename_plist" | grep -qi "$pattern"; then
                            warning "Suspicious launch agent: $basename_plist"
                            issues=$((issues + 1))
                            log_message "WARNING" "Suspicious launch agent: $plist"
                        fi
                    done
                fi
            done
        fi
    fi
    
    # Check system launch agents (requires sudo)
    if sudo -n true 2>/dev/null; then
        local system_agents="/Library/LaunchAgents"
        if [ -d "$system_agents" ]; then
            local sys_count=$(sudo find "$system_agents" -name "*.plist" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$sys_count" -gt 0 ] && [ "$VERBOSE" = true ]; then
                info "Found $sys_count system launch agent(s)"
            fi
        fi
        
        # Check launch daemons
        local system_daemons="/Library/LaunchDaemons"
        if [ -d "$system_daemons" ]; then
            local daemon_count=$(sudo find "$system_daemons" -name "*.plist" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$daemon_count" -gt 0 ] && [ "$VERBOSE" = true ]; then
                info "Found $daemon_count system launch daemon(s)"
            fi
        fi
    fi
    
    # List active launch items
    if [ "$VERBOSE" = true ]; then
        info "Active launch items:"
        launchctl list 2>/dev/null | head -20 || true
    fi
    
    if [ $issues -eq 0 ]; then
        success "No suspicious launch items detected"
        return 0
    else
        warning "Found $issues suspicious launch item(s)"
        return 1
    fi
}

# Check SSL/TLS certificates for expiration
check_certificates() {
    if [ "$CHECK_CERTIFICATES" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🔒 SSL/TLS Certificate Status...${normal}"
    fi
    
    # Check system keychain certificates
    if command -v security &> /dev/null; then
        set +e
        local expired_certs=$(security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain 2>/dev/null | \
            openssl x509 -noout -enddate 2>/dev/null | \
            awk -F= '{if ($2 < "'$(date +%Y%m%d)'") print $2}' | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
        set -e
        
        # Ensure expired_certs is a clean integer
        expired_certs=${expired_certs:-0}
        expired_certs=$(echo "$expired_certs" | tr -d ' \n' || echo "0")
        
        if [ "$expired_certs" -gt 0 ] 2>/dev/null && [ "${VERBOSE:-false}" = "true" ]; then
            info "Found expired certificates in system keychain"
        fi
    fi
    
    success "Certificate check completed"
    return 0
}

# Run lynis security audit
run_lynis_audit() {
    if [ "$RUN_LYNIS" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🛡️ Running Lynis Security Audit...${normal}"
        echo "   This may take a few minutes..."
    fi
    
    # Check if lynis is installed
    if ! command -v lynis &> /dev/null; then
        if [ "$QUIET" != true ]; then
            warning "Lynis not found. Installing..."
        fi
        
        set +e
        if brew install lynis 2>&1; then
            set -e
            success "Lynis installed successfully"
        else
            set -e
            warning "Lynis installation failed. Skipping audit"
            return 1
        fi
    fi
    
    # Run lynis audit
    local lynis_output="$AUDIT_DIR/lynis_audit_$(date +%Y%m%d_%H%M%S).txt"
    set +e
    if lynis audit system --quick 2>&1 | tee "$lynis_output"; then
        set -e
        success "Lynis audit completed - Report: $lynis_output"
        log_message "SUCCESS" "Lynis audit completed"
        return 0
    else
        set -e
        warning "Lynis audit encountered issues"
        log_message "WARNING" "Lynis audit had issues"
        return 1
    fi
}

# Check System Integrity Protection (SIP)
check_sip() {
    if [ "$CHECK_SIP" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🛡️ System Integrity Protection (SIP)...${normal}"
    fi
    
    if command -v csrutil &> /dev/null; then
        set +e
        local sip_status=$(csrutil status 2>/dev/null)
        set -e
        
        if echo "$sip_status" | grep -q "System Integrity Protection status: enabled"; then
            success "SIP is enabled"
            log_message "SUCCESS" "SIP enabled"
            return 0
        else
            warning "SIP may be disabled or status unknown"
            log_message "WARNING" "SIP status unclear"
            return 1
        fi
    else
        info "csrutil not available (may require Recovery Mode)"
        return 0
    fi
}

# Check Gatekeeper status
check_gatekeeper() {
    if [ "$CHECK_GATEKEEPER" != true ]; then
        return 0
    fi
    
    if [ "$QUIET" != true ]; then
        echo "${bold}🚪 Gatekeeper Status...${normal}"
    fi
    
    if command -v spctl &> /dev/null; then
        set +e
        local gatekeeper_status=$(spctl --status 2>/dev/null)
        set -e
        
        if echo "$gatekeeper_status" | grep -q "assessments enabled"; then
            success "Gatekeeper is enabled"
            log_message "SUCCESS" "Gatekeeper enabled"
            return 0
        else
            warning "Gatekeeper may be disabled"
            log_message "WARNING" "Gatekeeper disabled or unknown"
            return 1
        fi
    else
        warning "spctl command not available"
        return 1
    fi
}

# Main audit function
main() {
    if [ "$QUIET" != true ]; then
        echo "${bold}🔍 Mac Security Audit - Comprehensive Security Assessment${normal}"
        echo "=========================================="
        echo ""
    fi
    
    log_message "INFO" "Security audit started"
    
    local total_issues=0
    
    # Run security checks
    check_filevault || total_issues=$((total_issues + 1))
    check_launch_items || total_issues=$((total_issues + 1))
    check_sip || total_issues=$((total_issues + 1))
    check_gatekeeper || total_issues=$((total_issues + 1))
    check_certificates || total_issues=$((total_issues + 1))
    
    # Run lynis if requested
    if [ "$RUN_LYNIS" = true ]; then
        run_lynis_audit || total_issues=$((total_issues + 1))
    fi
    
    # Summary
    if [ "$QUIET" != true ]; then
        echo ""
        if [ $total_issues -eq 0 ]; then
            echo "${bold}${green}✅ Security Audit Complete - No Issues Detected${normal}"
        else
            echo "${bold}${yellow}⚠️  Security Audit Complete - $total_issues Issue(s) Detected${normal}"
            echo "${yellow}   Review the findings above for details.${normal}"
            send_notification "Security Audit Alert" "$total_issues security issue(s) found" "${NOTIFICATION_SOUND:-true}" "critical"
        fi
        echo ""
        echo "Detailed logs: $AUDIT_DIR"
    fi
    
    log_message "INFO" "Security audit completed - $total_issues issues found"
    
    exit 0
}

main "$@"

