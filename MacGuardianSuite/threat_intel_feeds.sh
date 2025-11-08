#!/bin/bash

# ===============================
# Threat Intelligence Feeds
# Integrates public threat intelligence sources
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THREAT_INTEL_DIR="${THREAT_INTEL_DIR:-$HOME/.macguardian/threat_intel}"
THREAT_INTEL_DB="${THREAT_INTEL_DB:-$THREAT_INTEL_DIR/iocs.json}"

mkdir -p "$THREAT_INTEL_DIR"

# Update threat intelligence feeds
update_threat_feeds() {
    echo "${bold}📥 Updating Threat Intelligence Feeds...${normal}"
    echo "=========================================="
    echo ""
    
    local updated=0
    
    # Abuse.ch Feodo Tracker (malware IPs)
    if command -v curl &> /dev/null; then
        echo "  • Fetching Abuse.ch Feodo Tracker..."
        if curl -s "https://feodotracker.abuse.ch/downloads/ipblocklist_recommended.txt" -o "$THREAT_INTEL_DIR/abuse_ch_feodo.txt" 2>/dev/null; then
            success "Abuse.ch Feodo Tracker updated"
            updated=$((updated + 1))
        else
            warning "Failed to fetch Abuse.ch feed"
        fi
        
        # Abuse.ch URLhaus (malicious URLs)
        echo "  • Fetching Abuse.ch URLhaus..."
        if curl -s "https://urlhaus.abuse.ch/downloads/csv_recent/" -o "$THREAT_INTEL_DIR/abuse_ch_urlhaus.csv" 2>/dev/null; then
            success "Abuse.ch URLhaus updated"
            updated=$((updated + 1))
        else
            warning "Failed to fetch URLhaus feed"
        fi
        
        # Malware Domain List
        echo "  • Fetching Malware Domain List..."
        if curl -s "https://www.malwaredomainlist.com/hostslist/hosts.txt" -o "$THREAT_INTEL_DIR/malware_domains.txt" 2>/dev/null; then
            success "Malware Domain List updated"
            updated=$((updated + 1))
        else
            warning "Failed to fetch Malware Domain List"
        fi
    else
        warning "curl not available - cannot fetch threat feeds"
        return 1
    fi
    
    echo ""
    success "Updated $updated threat intelligence feed(s)"
    
    # Convert to unified IOC format
    convert_feeds_to_iocs
    
    return 0
}

# Convert feeds to unified IOC format
convert_feeds_to_iocs() {
    if ! command -v jq &> /dev/null; then
        warning "jq not installed. Install with: brew install jq"
        return 1
    fi
    
    echo ""
    echo "${bold}🔄 Converting feeds to IOC format...${normal}"
    
    local iocs="[]"
    
    # Parse Abuse.ch Feodo (IPs)
    if [ -f "$THREAT_INTEL_DIR/abuse_ch_feodo.txt" ]; then
        while IFS= read -r line; do
            # Skip comments
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            
            # Extract IP
            local ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
            if [ -n "$ip" ]; then
                local ioc=$(cat <<EOF
{
  "type": "ip",
  "value": "$ip",
  "source": "abuse_ch_feodo",
  "malicious": true,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
                iocs=$(echo "$iocs" | jq ". += [$ioc]")
            fi
        done < "$THREAT_INTEL_DIR/abuse_ch_feodo.txt"
    fi
    
    # Parse Malware Domain List
    if [ -f "$THREAT_INTEL_DIR/malware_domains.txt" ]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ "$line" =~ ^127\.0\.0\.1 ]] || continue
            
            local domain=$(echo "$line" | awk '{print $2}')
            if [ -n "$domain" ] && [ "$domain" != "localhost" ]; then
                local ioc=$(cat <<EOF
{
  "type": "domain",
  "value": "$domain",
  "source": "malware_domain_list",
  "malicious": true,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
                iocs=$(echo "$iocs" | jq ". += [$ioc]")
            fi
        done < "$THREAT_INTEL_DIR/malware_domains.txt"
    fi
    
    # Save to IOC database
    echo "$iocs" > "$THREAT_INTEL_DB"
    
    local count=$(echo "$iocs" | jq '. | length')
    success "Converted $count IOCs to database"
}

# Check against threat intelligence
check_ioc() {
    local ioc_type="$1"  # ip, domain, hash, url
    local value="$2"
    
    if [ ! -f "$THREAT_INTEL_DB" ]; then
        warning "Threat intelligence database not found. Run update first."
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        warning "jq not installed"
        return 1
    fi
    
    # Check if IOC exists in database
    local match=$(jq -r ".[] | select(.type == \"$ioc_type\" and .value == \"$value\") | .value" "$THREAT_INTEL_DB" 2>/dev/null | head -1)
    
    if [ -n "$match" ]; then
        local source=$(jq -r ".[] | select(.type == \"$ioc_type\" and .value == \"$value\") | .source" "$THREAT_INTEL_DB" 2>/dev/null | head -1)
        echo "🚨 MATCH: $ioc_type=$value found in threat intelligence (source: $source)"
        return 0
    else
        echo "✅ CLEAN: $ioc_type=$value not found in threat intelligence"
        return 1
    fi
}

# Export to STIX format
export_to_stix() {
    local output_file="${1:-$THREAT_INTEL_DIR/iocs.stix.json}"
    
    if [ ! -f "$THREAT_INTEL_DB" ]; then
        warning "IOC database not found. Run update first."
        return 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/stix_exporter.py" ]; then
        warning "STIX exporter not found"
        return 1
    fi
    
    if python3 "$SCRIPT_DIR/stix_exporter.py" "$THREAT_INTEL_DB" "$output_file" 2>/dev/null; then
        success "Exported IOCs to STIX format: $output_file"
        return 0
    else
        warning "Failed to export to STIX"
        return 1
    fi
}

# Main function
main() {
    case "${1:-update}" in
        update)
            update_threat_feeds
            ;;
        check)
            if [ $# -lt 3 ]; then
                echo "Usage: $0 check <type> <value>"
                echo "Example: $0 check ip 192.168.1.100"
                return 1
            fi
            check_ioc "$2" "$3"
            ;;
        stix)
            export_to_stix "${2:-}"
            ;;
        *)
            echo "Usage: $0 [update|check|stix] [args...]"
            echo ""
            echo "Commands:"
            echo "  update              Update threat intelligence feeds"
            echo "  check <type> <val>  Check if IOC is in threat database"
            echo "  stix [output]       Export IOCs to STIX format"
            ;;
    esac
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

