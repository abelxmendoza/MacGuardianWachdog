#!/bin/zsh

# ===============================
# Event Writer
# Writes structured JSON events to ~/.macguardian/events/
# ===============================

EVENT_DIR="$HOME/.macguardian/events"
mkdir -p "$EVENT_DIR"

function write_event() {
    local type="$1"
    local severity="$2"
    local message="$3"
    local details="$4"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local event_id=$(uuidgen 2>/dev/null || date +%s%N | sha256sum | cut -c1-32)
    local file="$EVENT_DIR/event_${event_id}.json"
    
    # Ensure details is valid JSON
    if [[ -z "$details" ]]; then
        details="{}"
    elif [[ ! "$details" =~ ^\{ ]]; then
        # If not JSON, wrap it (escape quotes)
        local escaped=$(echo "$details" | sed 's/"/\\"/g')
        details="{\"raw\": \"$escaped\"}"
    fi
    
    cat <<EOF > "$file"
{
  "id": "$event_id",
  "timestamp": "$timestamp",
  "type": "$type",
  "severity": "$severity",
  "message": "$message",
  "details": $details
}
EOF
    
    # Set permissions
    chmod 600 "$file" 2>/dev/null || true
}

export -f write_event

