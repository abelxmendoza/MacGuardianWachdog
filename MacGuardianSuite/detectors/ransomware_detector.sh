#!/bin/bash

# ===============================
# Ransomware Detector
# Detects potential ransomware activity
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SUITE_DIR/core/utils.sh" 2>/dev/null || true

EVENT_DIR="$HOME/.macguardian/events"
INCIDENTS_DIR="$HOME/.macguardian/incidents"
THRESHOLD_FILES=50  # Files changed in short time
THRESHOLD_TIME=60   # Seconds

# Detect ransomware patterns
detect_ransomware() {
    local current_time=$(date +%s)
    local window_start=$((current_time - THRESHOLD_TIME))
    
    # Count file changes in time window
    local file_changes=$(find "$EVENT_DIR" -name "event_*.json" -type f -newermt "@$window_start" 2>/dev/null | xargs grep -l '"type":"filesystem"' 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$file_changes" -ge "$THRESHOLD_FILES" ]; then
        warning "🚨 RANSOMWARE INDICATOR: $file_changes file changes in $THRESHOLD_TIME seconds"
        
        # Check for encryption patterns
        local encryption_patterns=$(find "$EVENT_DIR" -name "event_*.json" -type f -newermt "@$window_start" 2>/dev/null | xargs grep -lE '(encrypt|ransom|\.encrypted|\.locked)' 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$encryption_patterns" -gt 0 ]; then
            create_ransomware_incident "$file_changes" "$encryption_patterns"
            return 1
        fi
        
        return 0
    fi
    
    return 0
}

# Create ransomware incident
create_ransomware_incident() {
    local file_count="$1"
    local encryption_count="$2"
    
    local incident_id=$(uuidgen 2>/dev/null || date +%s%N | sha256sum | cut -c1-32)
    local incident_file="$INCIDENTS_DIR/ransomware_${incident_id}.json"
    
    cat > "$incident_file" <<EOF
{
  "id": "$incident_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "ransomware",
  "severity": "critical",
  "description": "Potential ransomware activity detected",
  "details": {
    "file_changes": $file_count,
    "encryption_patterns": $encryption_count,
    "time_window": $THRESHOLD_TIME
  },
  "status": "open",
  "recommended_action": "Immediately disconnect from network and investigate"
}
EOF
    
    log_message "CRITICAL" "RANSOMWARE INCIDENT: $file_count file changes detected"
    echo "🚨🚨🚨 RANSOMWARE ALERT 🚨🚨🚨"
    echo "File changes: $file_count"
    echo "Encryption patterns: $encryption_count"
    echo "Incident file: $incident_file"
}

# Main execution
detect_ransomware

