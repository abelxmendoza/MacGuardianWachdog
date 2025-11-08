#!/bin/bash

# ===============================
# 🐺 Mac Watchdog v3.0
# BSD-safe, progress-friendly, stable hashing
# Optimized for macOS with better error handling
# ===============================

set -euo pipefail

CONFIG_FILE="$HOME/.mac_watchdog_config"
BASELINE_FILE="$HOME/.mac_watchdog_baseline.txt"
CURRENT_CHECKSUMS="$HOME/.mac_watchdog_current.txt"
ALERT_EMAIL="abelxmendoza@gmail.com"
MONITOR_PATHS=("$HOME/Documents")
FULL_SCAN_PATH="/Applications"
HONEYPOT_DIR="$HOME/Documents/Passwords_DO_NOT_OPEN"
HONEYPOT_LOG="$HOME/.mac_watchdog_honeypot.log"
SYSLOG_COPY="$HOME/.mac_watchdog_syslog_last.txt"
SYSLOG_DIFF="$HOME/.mac_watchdog_syslog_diff.txt"
WATCHDOG_LOG="$HOME/.mac_watchdog_log.txt"

# Color support with fallback
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")
yellow=$(tput setaf 3 2>/dev/null || echo "")

# Logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$WATCHDOG_LOG"
}

# Function to send alert (multiple methods)
send_alert() {
    local subject="$1"
    local body="$2"
    local timestamp=$(date)
    
    # Try mail command first (macOS built-in)
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null && return 0
    fi
    
    # Try sendmail as fallback
    if command -v sendmail &> /dev/null; then
        {
            echo "Subject: $subject"
            echo "To: $ALERT_EMAIL"
            echo ""
            echo "$body"
        } | sendmail "$ALERT_EMAIL" 2>/dev/null && return 0
    fi
    
    # Fallback: write to log file
    echo "ALERT: $subject" >> "$WATCHDOG_LOG"
    echo "$body" >> "$WATCHDOG_LOG"
    echo "${yellow}⚠️  Alert logged (email not configured). Check $WATCHDOG_LOG${normal}"
    return 1
}

# Source advanced algorithms
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
    source "$SCRIPT_DIR/algorithms.sh"
    init_algorithms
fi

# Optimized checksum creation with incremental hashing
create_checksums() {
    local target_dir="$1"
    local output_file="$2"
    local use_incremental="${3:-false}"
    local baseline_file="${4:-}"
    
    if [ ! -d "$target_dir" ]; then
        echo "${yellow}⚠️  Directory not found: $target_dir${normal}"
        return 1
    fi
    
    echo "Indexing: $target_dir"
    
    # Use incremental hashing if baseline exists
    if [ "$use_incremental" = "true" ] && [ -f "$baseline_file" ] && [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
        local stats=$(incremental_hash "$target_dir" "$baseline_file" "$output_file")
        local changed=$(echo "$stats" | cut -d'|' -f1)
        local new=$(echo "$stats" | cut -d'|' -f2)
        local unchanged=$(echo "$stats" | cut -d'|' -f3)
        local total=$((changed + new + unchanged))
        
        echo "  ✅ Indexed $total files (Changed: $changed, New: $new, Unchanged: $unchanged)"
        
        # Save cache
        if [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
            cleanup_algorithms
        fi
        
        return 0
    fi
    
    # Standard hashing with optimizations
    local count=0
    local exclude_patterns=(
        "*/.*"           # Hidden files/dirs
        "*/node_modules/*"
        "*/Library/Caches/*"
        "*/tmp/*"
        "*/temp/*"
    )
    
    # Use smart_find if available, with parallel processing and sorting
    if [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
        source "$SCRIPT_DIR/algorithms.sh"
        
        # Process files in parallel batches and sort results
        local temp_unsorted="$output_file.unsorted"
        > "$temp_unsorted"
        
        # Process files in parallel
        local file_list=$(mktemp)
        smart_find "$target_dir" "${exclude_patterns[@]}" > "$file_list" 2>/dev/null || \
        find "$target_dir" -type f -print0 2>/dev/null | tr '\0' '\n' > "$file_list"
        
        # Process in parallel batches
        local batch_size=100
        local processed=0
        
        while IFS= read -r file; do
            if [ -f "$file" ] && [ -r "$file" ]; then
                (
                    local cached_info=$(get_file_info "$file")
                    local hash=$(echo "$cached_info" | cut -d'|' -f3)
                    if [ -n "$hash" ]; then
                        echo "$hash|$file"
                    fi
                ) >> "$temp_unsorted" &
                
                processed=$((processed + 1))
                
                # Wait for batch to complete
                if [ $((processed % batch_size)) -eq 0 ]; then
                    wait
                    if [ "$QUIET" != true ]; then
                        echo "  • Processed $processed files..."
                    fi
                fi
            fi
        done < "$file_list"
        
        wait
        
        # Sort results by hash for efficient comparison
        if [ -f "$SCRIPT_DIR/sort_engine.sh" ]; then
            source "$SCRIPT_DIR/sort_engine.sh"
            parallel_sort_large "$temp_unsorted" "$output_file" 1
        else
            sort "$temp_unsorted" > "$output_file"
        fi
        
        # Convert to standard format (hash  filepath)
        sed 's/|/  /' "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
        
        count=$(wc -l < "$output_file" | tr -d ' ')
        rm -f "$temp_unsorted" "$file_list"
    else
        # Fallback to standard find
        while IFS= read -r -d '' file; do
            if [ -f "$file" ] && [ -r "$file" ]; then
                if shasum -a 256 "$file" >> "$output_file" 2>/dev/null; then
                    count=$((count + 1))
                    if [ $((count % 50)) -eq 0 ]; then
                        echo "  • Processed $count files..."
                    fi
                fi
            fi
        done < <(find "$target_dir" -type f -print0 2>/dev/null)
    fi
    
    echo "  ✅ Indexed $count files from $target_dir"
    
    # Save cache
    if [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
        cleanup_algorithms
    fi
    
    return 0
}

# First-time setup
if [ ! -f "$CONFIG_FILE" ]; then
    echo "${bold}🔐 First-time setup for Mac Watchdog...${normal}"
    echo "Creating baseline checksums..."
    
    # Initialize baseline file
    > "$BASELINE_FILE"
    
    # Index monitored paths
    for path in "${MONITOR_PATHS[@]}"; do
        create_checksums "$path" "$BASELINE_FILE"
    done
    
    # Ask about /Applications scan
    read -p "${bold}❓ Scan /Applications too? (y/n): ${normal}" FULL_SCAN_REPLY
    if [[ "$FULL_SCAN_REPLY" =~ ^[Yy]$ ]]; then
        create_checksums "$FULL_SCAN_PATH" "$BASELINE_FILE"
    fi
    
    # Verify baseline was created
    if [ ! -s "$BASELINE_FILE" ]; then
        echo "${red}❌ No baseline created. Try again with accessible directories.${normal}"
        log_message "ERROR" "Baseline creation failed"
        exit 1
    fi
    
    # Create honeypot directory
    mkdir -p "$HONEYPOT_DIR"
    echo "# Fake credentials file - DO NOT OPEN" > "$HONEYPOT_DIR/credentials.txt"
    echo "# This is a honeypot file to detect unauthorized access" >> "$HONEYPOT_DIR/credentials.txt"
    echo "username: admin" >> "$HONEYPOT_DIR/credentials.txt"
    echo "password: changeme123" >> "$HONEYPOT_DIR/credentials.txt"
    chmod 600 "$HONEYPOT_DIR/credentials.txt" 2>/dev/null || true
    
    # Initialize honeypot log
    touch "$HONEYPOT_LOG"
    stat -f %m "$HONEYPOT_DIR/credentials.txt" > "$HONEYPOT_LOG" 2>/dev/null || echo "0" > "$HONEYPOT_LOG"
    
    # Create initial syslog snapshot
    if command -v log &> /dev/null; then
        log show --last 1d --predicate 'process == "kernel"' 2>/dev/null | head -1000 > "$SYSLOG_COPY" || true
    fi
    
    # Save configuration
    {
        echo "BASELINE_FILE=\"$BASELINE_FILE\""
        echo "ALERT_EMAIL=\"$ALERT_EMAIL\""
        echo "MONITOR_PATHS=(\"$HOME/Documents\")"
        echo "HONEYPOT_DIR=\"$HONEYPOT_DIR\""
        echo "SYSLOG_COPY=\"$SYSLOG_COPY\""
        if [[ "$FULL_SCAN_REPLY" =~ ^[Yy]$ ]]; then
            echo "FULL_SCAN_PATH=\"$FULL_SCAN_PATH\""
        fi
    } > "$CONFIG_FILE"
    
    echo "${bold}${green}✅ Baseline created with $(wc -l < "$BASELINE_FILE") files. Future runs will compare against this.${normal}"
    log_message "INFO" "Baseline created successfully"
    exit 0
fi

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "${red}❌ Configuration file not found. Please run setup again.${normal}"
    exit 1
fi

# Verify baseline exists
if [ ! -f "$BASELINE_FILE" ] || [ ! -s "$BASELINE_FILE" ]; then
    echo "${red}❌ Baseline file missing or empty. Please run setup again.${normal}"
    log_message "ERROR" "Baseline file missing"
    exit 1
fi

# Run integrity check (with parallel processing)
echo "${bold}🔍 Mac Watchdog - Running integrity check...${normal}"
echo ""

# Source utils for parallel processing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
    if [ "${ENABLE_PARALLEL:-true}" = true ]; then
        init_parallel
        info "Processing ${#MONITOR_PATHS[@]} path(s) in parallel"
    fi
fi

> "$CURRENT_CHECKSUMS"

# Process paths in parallel if enabled (with incremental hashing)
if [ "${ENABLE_PARALLEL:-true}" = true ] && [ -f "$SCRIPT_DIR/utils.sh" ]; then
    for path in "${MONITOR_PATHS[@]}"; do
        if [ -d "$path" ]; then
            # Use incremental hashing for efficiency
            run_parallel "checksum_$(basename "$path")" "create_checksums \"$path\" \"$CURRENT_CHECKSUMS\" \"true\" \"$BASELINE_FILE\"" > /dev/null
        else
            echo "${yellow}⚠️  Path not found: $path${normal}"
        fi
    done
    wait_all_jobs
else
    # Sequential fallback with incremental hashing
    for path in "${MONITOR_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "Checking: $path"
            create_checksums "$path" "$CURRENT_CHECKSUMS" "true" "$BASELINE_FILE"
        else
            echo "${yellow}⚠️  Path not found: $path${normal}"
        fi
    done
fi

# Compare checksums using optimized diff algorithm
DIFF_RESULT=""
if [ -f "$CURRENT_CHECKSUMS" ] && [ -s "$CURRENT_CHECKSUMS" ]; then
    if [ -f "$SCRIPT_DIR/algorithms.sh" ]; then
        # Use fast_diff for O(1) hash lookups
        DIFF_RESULT=$(fast_diff "$BASELINE_FILE" "$CURRENT_CHECKSUMS" 2>/dev/null || true)
    else
        # Fallback to standard diff
        DIFF_RESULT=$(diff -u "$BASELINE_FILE" "$CURRENT_CHECKSUMS" 2>/dev/null || true)
    fi
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HONEYPOT_ACCESSED=false

# Check honeypot access
if [ -f "$HONEYPOT_DIR/credentials.txt" ]; then
    if [ -f "$HONEYPOT_LOG" ]; then
        LAST_RUN_TIME=$(cat "$HONEYPOT_LOG" 2>/dev/null || echo "0")
        CURRENT_ACCESS_TIME=$(stat -f %m "$HONEYPOT_DIR/credentials.txt" 2>/dev/null || echo "0")
        
        if [ "$CURRENT_ACCESS_TIME" -gt "$LAST_RUN_TIME" ] 2>/dev/null; then
            HONEYPOT_ACCESSED=true
            echo "$CURRENT_ACCESS_TIME" > "$HONEYPOT_LOG"
        fi
    else
        echo "$(stat -f %m "$HONEYPOT_DIR/credentials.txt" 2>/dev/null || echo "0")" > "$HONEYPOT_LOG"
    fi
fi

# Check system log changes (simplified)
LOG_CHANGES=""
if command -v log &> /dev/null && [ -f "$SYSLOG_COPY" ]; then
    log show --last 1d --predicate 'process == "kernel"' 2>/dev/null | head -1000 > "$SYSLOG_DIFF" || true
    if [ -f "$SYSLOG_DIFF" ]; then
        LOG_CHANGES=$(diff -u "$SYSLOG_COPY" "$SYSLOG_DIFF" 2>/dev/null | head -50 || true)
        cp "$SYSLOG_DIFF" "$SYSLOG_COPY" 2>/dev/null || true
    fi
fi

# Build alert message
ALERT_MSG=""
ALERT_NEEDED=false

if [ -n "$DIFF_RESULT" ]; then
    ALERT_MSG+="🚨 FILE INTEGRITY VIOLATIONS DETECTED 🚨\n\n"
    ALERT_MSG+="Files have been added, modified, or deleted:\n"
    ALERT_MSG+="$(echo "$DIFF_RESULT" | head -100)\n\n"
    if [ $(echo "$DIFF_RESULT" | wc -l) -gt 100 ]; then
        ALERT_MSG+="... (truncated, see full diff in log)\n\n"
    fi
    ALERT_NEEDED=true
    echo "${red}⚠️  File integrity violations detected!${normal}"
    log_message "ALERT" "File integrity violations detected"
fi

if [ "$HONEYPOT_ACCESSED" = true ]; then
    ALERT_MSG+="🚨🚨🚨 HONEYPOT FILE ACCESSED 🚨🚨🚨\n\n"
    ALERT_MSG+="The honeypot file was accessed at: $TIMESTAMP\n"
    ALERT_MSG+="Location: $HONEYPOT_DIR/credentials.txt\n"
    ALERT_MSG+="This may indicate unauthorized access!\n\n"
    ALERT_NEEDED=true
    echo "${red}🚨 HONEYPOT ACCESSED - Potential security breach!${normal}"
    log_message "CRITICAL" "Honeypot file accessed"
fi

if [ -n "$LOG_CHANGES" ]; then
    ALERT_MSG+="System log changes detected:\n"
    ALERT_MSG+="$(echo "$LOG_CHANGES" | head -30)\n\n"
    # Only alert on significant log changes (not every run)
    if echo "$LOG_CHANGES" | grep -qE "(error|warning|fail|denied|unauthorized)" 2>/dev/null; then
        ALERT_NEEDED=true
        log_message "WARNING" "Significant system log changes detected"
    fi
fi

# Send alert if needed
if [ "$ALERT_NEEDED" = true ]; then
    ALERT_MSG+="\n---\nMac Watchdog Alert\nTimestamp: $TIMESTAMP\n"
    if send_alert "🚨 Mac Watchdog Alert - $TIMESTAMP" "$ALERT_MSG"; then
        echo "${green}✅ Alert sent to $ALERT_EMAIL${normal}"
    else
        echo "${yellow}⚠️  Alert logged (email may not be configured)${normal}"
    fi
else
    echo "${green}✅ No suspicious activity detected.${normal}"
    log_message "INFO" "Scan completed - no issues found"
fi

# Log completion
log_message "INFO" "Watchdog run completed"
echo ""
echo "${bold}✅ Mac Watchdog check completed at $TIMESTAMP${normal}"

