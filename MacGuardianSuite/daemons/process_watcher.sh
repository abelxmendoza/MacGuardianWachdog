#!/bin/zsh

# ===============================
# Process Watcher
# Real-time process anomaly detection
# ===============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/event_writer.sh" 2>/dev/null || true

# Baseline for process count
BASELINE_FILE="$HOME/.macguardian/.process_baseline"
PROCESS_CHECK_INTERVAL=30  # Check every 30 seconds
LAST_PROCESS_CHECK="$HOME/.macguardian/.process_last_check"

function detect_suspicious_processes() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_PROCESS_CHECK" 2>/dev/null || echo "0")
    
    # Only check every PROCESS_CHECK_INTERVAL seconds
    if [ $((current_time - last_check)) -lt $PROCESS_CHECK_INTERVAL ]; then
        return 0
    fi
    
    echo "$current_time" > "$LAST_PROCESS_CHECK"
    
    # Get current process count
    local process_count=$(ps aux | wc -l | tr -d ' ')
    
    # Load baseline
    local baseline_count=$(cat "$BASELINE_FILE" 2>/dev/null || echo "$process_count")
    
    # Update baseline if it doesn't exist or is very old
    if [ ! -f "$BASELINE_FILE" ] || [ -z "$baseline_count" ]; then
        echo "$process_count" > "$BASELINE_FILE"
        return 0
    fi
    
    # Check for significant process count changes (>50% increase)
    local diff=$((process_count - baseline_count))
    local percent_change=0
    if [ "$baseline_count" -gt 0 ]; then
        percent_change=$((diff * 100 / baseline_count))
    fi
    
    if [ ${percent_change#-} -gt 50 ]; then
        write_event "process" "medium" "Significant process count change detected" "{\"current\": $process_count, \"baseline\": $baseline_count, \"change_percent\": $percent_change}"
    fi
    
    # Check for high CPU processes (using awk for portability)
    ps -eo pid,pcpu,comm,args 2>/dev/null | awk 'NR>1 && $2 > 80 {
        # Skip known system processes
        if ($3 !~ /(kernel_task|WindowServer|mds|mdworker|Spotlight|TimeMachine|biomesyncd)/) {
            print $1 "|" $2 "|" $3 "|" substr($0, index($0,$4))
        }
    }' | while IFS='|' read -r pid cpu comm args; do
        if [ -n "$pid" ] && [ -n "$cpu" ]; then
            write_event "process" "high" "High CPU process detected" "{\"pid\": $pid, \"cpu_percent\": $cpu, \"process\": \"$comm\", \"args\": \"$args\"}"
        fi
    done
    
    # Check for suspicious process patterns
    ps -eo pid,comm,args 2>/dev/null | awk 'NR>1 {
        comm = $2
        args = substr($0, index($0,$3))
        
        # Suspicious patterns (but exclude known safe uses)
        if (comm ~ /(curl|nc|nmap|python3|osascript|sh|bash|zsh)/ && 
            args !~ /(brew|pip|npm|node|MacGuardian|system)/) {
            print $1 "|" comm "|" args
        }
    }' | while IFS='|' read -r pid comm args; do
        if [ -n "$pid" ] && [ -n "$comm" ]; then
            write_event "process" "medium" "Potential suspicious process detected" "{\"pid\": $pid, \"process\": \"$comm\", \"args\": \"$args\"}"
        fi
    done
    
    # Check for processes with suspicious names
    ps -eo pid,comm 2>/dev/null | grep -iE "(miner|crypto|bitcoin|malware|trojan|backdoor|keylogger)" | while read -r pid comm; do
        if [ -n "$pid" ]; then
            write_event "process" "critical" "Suspicious process name detected" "{\"pid\": $pid, \"process\": \"$comm\"}"
        fi
    done
}

export -f detect_suspicious_processes

