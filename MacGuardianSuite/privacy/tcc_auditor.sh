#!/bin/bash

# ===============================
# TCC (Transparency, Consent, and Control) Privacy Auditor
# Audits macOS privacy permissions and TCC database
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SUITE_DIR/core/utils.sh" 2>/dev/null || true

TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"
USER_TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
BASELINE_DIR="$HOME/.macguardian/baselines"
PRIVACY_BASELINE="$BASELINE_DIR/privacy_baseline.json"
AUDIT_OUTPUT="$HOME/.macguardian/audits/tcc_audit_$(date +%Y%m%d_%H%M%S).json"

mkdir -p "$BASELINE_DIR" "$(dirname "$AUDIT_OUTPUT")"

# Initialize privacy baseline
init_privacy_baseline() {
    if [ ! -f "$PRIVACY_BASELINE" ]; then
        log_message "INFO" "Creating privacy baseline..."
        
        local permissions="{}"
        
        # Query TCC database if sqlite3 is available
        if command -v sqlite3 &> /dev/null && [ -f "$USER_TCC_DB" ]; then
            # Get permissions (simplified - would need proper SQL parsing)
            local perm_count=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE allowed=1;" 2>/dev/null || echo "0")
            permissions="{\"permission_count\": $perm_count}"
        fi
        
        cat > "$PRIVACY_BASELINE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "permissions": $permissions
}
EOF
        
        success "Privacy baseline created"
    fi
}

# Audit TCC permissions
audit_tcc_permissions() {
    local issues=0
    
    # Load baseline
    if [ ! -f "$PRIVACY_BASELINE" ]; then
        init_privacy_baseline
        return 0
    fi
    
    # Check for new permissions
    if command -v sqlite3 &> /dev/null && [ -f "$USER_TCC_DB" ]; then
        local current_count=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE allowed=1;" 2>/dev/null || echo "0")
        local baseline_count=$(grep -o '"permission_count":[0-9]*' "$PRIVACY_BASELINE" 2>/dev/null | cut -d: -f2 || echo "0")
        
        if [ "$current_count" -gt "$baseline_count" ]; then
            issues=$((issues + 1))
            warning "New privacy permissions granted: $baseline_count -> $current_count"
        fi
        
        # Check for suspicious permissions
        # Full Disk Access
        local full_disk=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND allowed=1;" 2>/dev/null || echo "0")
        if [ "$full_disk" -gt 0 ]; then
            info "Full Disk Access granted to $full_disk application(s)"
        fi
        
        # Screen Recording
        local screen_recording=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceScreenCapture' AND allowed=1;" 2>/dev/null || echo "0")
        if [ "$screen_recording" -gt 0 ]; then
            info "Screen Recording granted to $screen_recording application(s)"
        fi
        
        # Microphone
        local microphone=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceMicrophone' AND allowed=1;" 2>/dev/null || echo "0")
        if [ "$microphone" -gt 0 ]; then
            info "Microphone access granted to $microphone application(s)"
        fi
        
        # Camera
        local camera=$(sqlite3 "$USER_TCC_DB" "SELECT COUNT(*) FROM access WHERE service='kTCCServiceCamera' AND allowed=1;" 2>/dev/null || echo "0")
        if [ "$camera" -gt 0 ]; then
            info "Camera access granted to $camera application(s)"
        fi
    else
        warning "sqlite3 not available or TCC database not found - cannot audit permissions"
    fi
    
    # Output JSON
    cat > "$AUDIT_OUTPUT" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "audit_type": "tcc_privacy",
  "issues_found": $issues,
  "full_disk_access": ${full_disk:-0},
  "screen_recording": ${screen_recording:-0},
  "microphone": ${microphone:-0},
  "camera": ${camera:-0}
}
EOF
    
    if [ $issues -eq 0 ]; then
        success "TCC privacy audit completed - no issues found"
    else
        warning "TCC privacy audit completed - $issues issue(s) found"
    fi
    
    return $issues
}

# Main execution
if [ "${1:-audit}" = "baseline" ]; then
    init_privacy_baseline
else
    audit_tcc_permissions
fi

