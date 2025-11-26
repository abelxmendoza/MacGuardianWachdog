#!/bin/zsh

# ===============================
# FSEvents Watcher
# Real-time file system change detection
# ===============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/event_writer.sh" 2>/dev/null || true

# Watch directories (configurable)
WATCH_DIRS=(
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/.ssh"
)

# Last check timestamp file
LAST_CHECK_FILE="$HOME/.macguardian/.fsevents_last_check"

# Initialize last check time
if [ ! -f "$LAST_CHECK_FILE" ]; then
    echo "$(date +%s)" > "$LAST_CHECK_FILE"
fi

function detect_fs_changes() {
    local current_time=$(date +%s)
    local last_check=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo "$current_time")
    
    # Check each directory for recent changes
    for dir in "${WATCH_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi
        
        # Find files modified since last check
        # Use stat to check modification time
        local recent_files=$(find "$dir" -type f -print0 2>/dev/null | xargs -0 stat -f "%m %N" 2>/dev/null | awk -v last="$last_check" '$1 > last {print $2}' | head -20)
        
        if [ -n "$recent_files" ]; then
            local file_count=$(echo "$recent_files" | wc -l | tr -d ' ')
            
            # Only alert on significant changes (more than 5 files)
            if [ "$file_count" -gt 5 ] 2>/dev/null; then
                # Get first file as example (simplified JSON)
                local first_file=$(echo "$recent_files" | head -1 | sed 's/"/\\"/g')
                write_event "filesystem" "medium" "Multiple file changes detected in $dir" "{\"directory\": \"$dir\", \"file_count\": $file_count, \"sample_file\": \"$first_file\"}"
            fi
            
            # Check for suspicious file types
            local suspicious=$(echo "$recent_files" | grep -E '\.(exe|bat|scr|vbs|ps1|sh)$' 2>/dev/null | head -1)
            if [ -n "$suspicious" ]; then
                local escaped_file=$(echo "$suspicious" | sed 's/"/\\"/g')
                write_event "filesystem" "high" "Suspicious file type detected" "{\"directory\": \"$dir\", \"file\": \"$escaped_file\"}"
            fi
        fi
    done
    
    # Update last check time
    echo "$current_time" > "$LAST_CHECK_FILE"
}

export -f detect_fs_changes

