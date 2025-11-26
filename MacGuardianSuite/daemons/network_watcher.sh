#!/bin/zsh

# ===============================
# Network Watcher
# Real-time network anomaly detection
# ===============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/event_writer.sh" 2>/dev/null || true

# Threat intelligence database
THREAT_INTEL_DB="$HOME/.macguardian/threat_intel/iocs.json"

# Suspicious ports
SUSPICIOUS_PORTS=(4444 5555 6666 7777 8888 9999 1337 31337)

# Baseline for network connections
NETWORK_CHECK_INTERVAL=60  # Check every 60 seconds
LAST_NETWORK_CHECK="$HOME/.macguardian/.network_last_check"

function detect_network_anomalies() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_NETWORK_CHECK" 2>/dev/null || echo "0")
    
    # Only check every NETWORK_CHECK_INTERVAL seconds
    if [ $((current_time - last_check)) -lt $NETWORK_CHECK_INTERVAL ]; then
        return 0
    fi
    
    echo "$current_time" > "$LAST_NETWORK_CHECK"
    
    if ! command -v lsof &> /dev/null; then
        return 1
    fi
    
    # Get all established connections
    local connections=$(lsof -i -P -n 2>/dev/null | grep ESTABLISHED || true)
    
    if [ -z "$connections" ]; then
        return 0
    fi
    
    # Check each connection
    echo "$connections" | while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # Extract port and remote address
        local port=$(echo "$line" | grep -oE ':[0-9]+' | head -1 | tr -d ':' || echo "")
        local remote=$(echo "$line" | awk '{print $9}' | cut -d: -f1 || echo "")
        local process=$(echo "$line" | awk '{print $1}' || echo "")
        
        # Check suspicious ports
        for sus_port in "${SUSPICIOUS_PORTS[@]}"; do
            if [ "$port" = "$sus_port" ]; then
                write_event "network" "high" "Connection to suspicious port detected" "{\"port\": $port, \"remote\": \"$remote\", \"process\": \"$process\"}"
            fi
        done
        
        # Check threat intelligence database
        if [ -f "$THREAT_INTEL_DB" ] && command -v jq &> /dev/null && [ -n "$remote" ]; then
            local threat_match=$(jq -r ".[] | select(.type == \"ip\" and .value == \"$remote\") | .value" "$THREAT_INTEL_DB" 2>/dev/null | head -1)
            if [ -n "$threat_match" ]; then
                local threat_source=$(jq -r ".[] | select(.type == \"ip\" and .value == \"$remote\") | .source" "$THREAT_INTEL_DB" 2>/dev/null | head -1)
                write_event "network" "critical" "Connection to known malicious IP detected" "{\"ip\": \"$remote\", \"port\": \"$port\", \"process\": \"$process\", \"threat_source\": \"$threat_source\"}"
            fi
        fi
        
        # Check for connections to private/internal IPs from suspicious processes
        if echo "$remote" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)' && echo "$process" | grep -qiE "(curl|nc|python|sh|bash)"; then
            write_event "network" "medium" "Suspicious internal network connection" "{\"remote\": \"$remote\", \"port\": \"$port\", \"process\": \"$process\"}"
        fi
    done
    
    # Check for listening ports (potential backdoors)
    local listening=$(lsof -i -P -n 2>/dev/null | grep LISTEN || true)
    if [ -n "$listening" ]; then
        echo "$listening" | while IFS= read -r line; do
            local listen_port=$(echo "$line" | grep -oE ':[0-9]+' | head -1 | tr -d ':' || echo "")
            local listen_process=$(echo "$line" | awk '{print $1}' || echo "")
            
            # Alert on unexpected listening ports
            if [ -n "$listen_port" ] && [ "$listen_port" -gt 1024 ] && [ "$listen_port" -lt 65535 ]; then
                # Skip known safe processes
                if echo "$listen_process" | grep -qiE "(Safari|Chrome|Firefox|Slack|Discord|Spotify|Music|Mail)"; then
                    continue
                fi
                
                write_event "network" "medium" "Unexpected listening port detected" "{\"port\": $listen_port, \"process\": \"$listen_process\"}"
            fi
        done
    fi
}

export -f detect_network_anomalies

