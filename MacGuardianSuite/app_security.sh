#!/bin/bash

# ===============================
# 🔒 MacGuardian Suite App Security
# Security checks for the app itself
# ===============================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh" 2>/dev/null || true

# Calculate checksums for critical files
calculate_checksums() {
    local checksum_file="$SCRIPT_DIR/.checksums.json"
    local temp_file=$(mktemp)
    
    echo "{" > "$temp_file"
    echo "  \"generated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$temp_file"
    echo "  \"files\": {" >> "$temp_file"
    
    local first=true
    for script in mac_guardian.sh mac_watchdog.sh mac_blueteam.sh mac_remediation.sh utils.sh config.sh; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            local checksum=$(shasum -a 256 "$SCRIPT_DIR/$script" | awk '{print $1}')
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$temp_file"
            fi
            echo -n "    \"$script\": \"$checksum\"" >> "$temp_file"
        fi
    done
    
    echo "" >> "$temp_file"
    echo "  }" >> "$temp_file"
    echo "}" >> "$temp_file"
    
    mv "$temp_file" "$checksum_file"
    success "Checksums calculated and saved to .checksums.json"
}

# Verify file integrity
verify_integrity() {
    local checksum_file="$SCRIPT_DIR/.checksums.json"
    
    if [ ! -f "$checksum_file" ]; then
        warning "No checksum file found. Run with --generate-checksums first."
        return 1
    fi
    
    local issues=0
    
    # Parse JSON and verify each file
    while IFS= read -r line; do
        if [[ "$line" =~ \"([^\"]+)\":\ \"([^\"]+)\" ]]; then
            local file="${BASH_REMATCH[1]}"
            local expected="${BASH_REMATCH[2]}"
            
            if [ -f "$SCRIPT_DIR/$file" ]; then
                local actual=$(shasum -a 256 "$SCRIPT_DIR/$file" | awk '{print $1}')
                if [ "$actual" != "$expected" ]; then
                    error "⚠️  Integrity check FAILED: $file"
                    error "   Expected: $expected"
                    error "   Actual:   $actual"
                    issues=$((issues + 1))
                else
                    success "✅ $file - OK"
                fi
            else
                warning "File not found: $file"
            fi
        fi
    done < <(grep -E '\"[^\"]+\":\ \"[^\"]+\"' "$checksum_file")
    
    if [ $issues -eq 0 ]; then
        success "All files passed integrity verification"
        return 0
    else
        error "Found $issues file(s) with integrity issues"
        return 1
    fi
}

# Check file permissions
check_permissions() {
    local issues=0
    
    for script in mac_guardian.sh mac_watchdog.sh mac_blueteam.sh mac_remediation.sh utils.sh; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            local perms=$(stat -f "%OLp" "$SCRIPT_DIR/$script" 2>/dev/null || stat -c "%a" "$SCRIPT_DIR/$script" 2>/dev/null || echo "000")
            
            if [ "$perms" != "755" ] && [ "$perms" != "750" ] && [ "$perms" != "700" ]; then
                warning "⚠️  $script has incorrect permissions: $perms (should be 755)"
                issues=$((issues + 1))
            else
                success "✅ $script permissions OK ($perms)"
            fi
        fi
    done
    
    return $issues
}

# Main
case "${1:-verify}" in
    --generate-checksums|-g)
        calculate_checksums
        ;;
    --verify|-v)
        verify_integrity
        ;;
    --check-permissions|-p)
        check_permissions
        ;;
    --all|-a)
        echo "${bold}🔒 MacGuardian Suite Security Check${normal}"
        echo "=================================="
        echo ""
        echo "Checking file permissions..."
        check_permissions
        echo ""
        echo "Verifying file integrity..."
        verify_integrity
        ;;
    *)
        echo "Usage: $0 [--generate-checksums|--verify|--check-permissions|--all]"
        echo ""
        echo "Options:"
        echo "  --generate-checksums, -g  Generate checksums for critical files"
        echo "  --verify, -v              Verify file integrity against stored checksums"
        echo "  --check-permissions, -p   Check file permissions"
        echo "  --all, -a                 Run all security checks"
        exit 1
        ;;
esac

