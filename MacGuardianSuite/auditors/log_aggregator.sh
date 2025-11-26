#!/bin/bash

# ===============================
# Log Aggregator
# Aggregates logs from multiple sources
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SUITE_DIR/core/utils.sh" 2>/dev/null || true

LOG_DIR="$HOME/.macguardian/logs"
AGGREGATED_LOG="$LOG_DIR/aggregated_$(date +%Y%m%d_%H%M%S).json"
UNIFIED_LOG_PYTHON="$SUITE_DIR/collectors/unified_logging.py"

mkdir -p "$LOG_DIR"

# Aggregate logs
aggregate_logs() {
    local output_file="${1:-$AGGREGATED_LOG}"
    local hours="${2:-24}"  # Default to last 24 hours
    
    # Use Python collector if available
    if [ -f "$UNIFIED_LOG_PYTHON" ] && command -v python3 &> /dev/null; then
        python3 "$UNIFIED_LOG_PYTHON" --hours "$hours" --output "$output_file" 2>/dev/null || {
            warning "Python log aggregator failed, using fallback"
            aggregate_logs_fallback "$output_file" "$hours"
        }
    else
        aggregate_logs_fallback "$output_file" "$hours"
    fi
    
    success "Logs aggregated: $output_file"
}

# Fallback aggregation
aggregate_logs_fallback() {
    local output_file="$1"
    local hours="$2"
    
    local start_time=$(date -v-${hours}H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d "$hours hours ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
    
    echo "[]" > "$output_file"
    
    # Aggregate from unified logging if available
    if command -v log &> /dev/null; then
        log show --last "${hours}h" --predicate 'process == "kernel" OR process == "sshd" OR process == "sudo"' 2>/dev/null | head -1000 > "$LOG_DIR/unified_$(date +%Y%m%d_%H%M%S).txt" || true
    fi
    
    # Aggregate from application logs
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -type f -mtime -$((hours / 24 + 1)) -exec cat {} \; 2>/dev/null | head -5000 >> "$LOG_DIR/combined_$(date +%Y%m%d_%H%M%S).txt" || true
    fi
}

# Main execution
aggregate_logs "${1:-$AGGREGATED_LOG}" "${2:-24}"

