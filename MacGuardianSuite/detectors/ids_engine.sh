#!/bin/bash

# ===============================
# IDS Engine (Intrusion Detection System)
# Real-time correlation and alerting
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SUITE_DIR/core/utils.sh" 2>/dev/null || true

EVENT_DIR="$HOME/.macguardian/events"
INCIDENTS_DIR="$HOME/.macguardian/incidents"
RULES_FILE="$SUITE_DIR/config/rules.yaml"

mkdir -p "$INCIDENTS_DIR"

# Correlation window (seconds)
CORRELATION_WINDOW=60

# Run IDS correlation
run_ids_correlation() {
    local current_time=$(date +%s)
    local window_start=$((current_time - CORRELATION_WINDOW))
    
    # Get recent events
    local recent_events=$(find "$EVENT_DIR" -name "event_*.json" -type f -newermt "@$window_start" 2>/dev/null | head -100)
    
    if [ -z "$recent_events" ]; then
        return 0
    fi
    
    # Check correlation rules
    # Rule 1: File change + New process + Network connection = Suspicious
    local file_changes=$(echo "$recent_events" | xargs grep -l '"type":"filesystem"' 2>/dev/null | wc -l | tr -d ' ')
    local new_processes=$(echo "$recent_events" | xargs grep -l '"type":"process".*"severity":"high"' 2>/dev/null | wc -l | tr -d ' ')
    local network_conns=$(echo "$recent_events" | xargs grep -l '"type":"network"' 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$file_changes" -gt 0 ] && [ "$new_processes" -gt 0 ] && [ "$network_conns" -gt 0 ]; then
        create_incident "correlation" "critical" "Multiple suspicious activities detected simultaneously" "{\"file_changes\": $file_changes, \"new_processes\": $new_processes, \"network_connections\": $network_conns}"
    fi
    
    # Rule 2: High CPU process + Network to suspicious IP = Alert
    local high_cpu=$(echo "$recent_events" | xargs grep -l '"cpu_percent":[5-9][0-9]' 2>/dev/null | wc -l | tr -d ' ')
    local suspicious_ips=$(echo "$recent_events" | xargs grep -l '"threat_source"' 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$high_cpu" -gt 0 ] && [ "$suspicious_ips" -gt 0 ]; then
        create_incident "correlation" "high" "High CPU process connecting to known malicious IP" "{\"high_cpu_processes\": $high_cpu, \"suspicious_ips\": $suspicious_ips}"
    fi
    
    # Rule 3: Multiple file changes in short time = Potential ransomware
    if [ "$file_changes" -gt 50 ]; then
        create_incident "correlation" "critical" "Mass file changes detected - possible ransomware" "{\"file_changes\": $file_changes, \"time_window\": $CORRELATION_WINDOW}"
    fi
}

# Create incident
create_incident() {
    local incident_type="$1"
    local severity="$2"
    local description="$3"
    local details="$4"
    
    local incident_id=$(uuidgen 2>/dev/null || date +%s%N | sha256sum | cut -c1-32)
    local incident_file="$INCIDENTS_DIR/incident_${incident_id}.json"
    
    cat > "$incident_file" <<EOF
{
  "id": "$incident_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "$incident_type",
  "severity": "$severity",
  "description": "$description",
  "details": $details,
  "status": "open"
}
EOF
    
    log_message "ALERT" "IDS Incident created: $description"
    echo "🚨 IDS Alert: $description"
}

export -f run_ids_correlation
export -f create_incident

