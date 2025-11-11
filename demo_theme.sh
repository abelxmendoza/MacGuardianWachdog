#!/bin/bash
# Demo script to showcase the Omega Tech Black-Ops theme

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load theme
if [ -f "$SCRIPT_DIR/MacGuardianSuite/theme_omega_black_ops.sh" ]; then
    source "$SCRIPT_DIR/MacGuardianSuite/theme_omega_black_ops.sh"
fi

clear
omega_banner
echo ""
omega_label_value "THEME:" "${OMEGA_THEME_NAME:-Omega Tech Black-Ops}"
omega_label_value "OPS HUB:" "MacGuardian Watchdog Suite"
omega_label_value "PROFILE:" "${OMEGA_PROMPT_GLIPH:-Ω} // ${USER:-agent}"
omega_divider
omega_status info "Select your next operation"
echo ""

omega_menu_section "CORE OPERATIONS"
omega_menu_option "01" "Mac Guardian — Cleanup & Adaptive Security"
omega_menu_option "02" "Mac Watchdog — File Integrity Sentinel"
omega_menu_option "03" "Mac Blue Team — Adversary Hunting"
omega_menu_option "04" "Mac AI — Intelligence Synthesis"
omega_menu_option "05" "Mac Security Audit — Deep System Recon"
omega_menu_option "06" "Mac Remediation — Auto-Fix Strike"
echo ""

omega_menu_section "ADVANCED OPERATIONS"
omega_menu_option "07" "Run Core Ops Chain"
omega_menu_option "08" "Verify Suite Integrity"
omega_menu_option "09" "Error Vault — Review & Patch"
omega_menu_option "10" "Hardening Assessment"
echo ""

omega_menu_section "INTELLIGENCE & REPORTING"
omega_menu_option "11" "Generate Tactical Report"
omega_menu_option "12" "Phase One Systems Setup"
omega_menu_option "13" "Fire Test Transmission"
omega_menu_option "14" "Performance Monitor — Bottlenecks"
omega_menu_option "15" "Advanced Reporting Arsenal"
echo ""

omega_divider
omega_status success "Theme demonstration complete"
omega_status info "All styling functions are operational"
omega_status warn "This is a demo - no actual operations were executed"
omega_status error "Use ./MacGuardianSuite/mac_suite.sh for full functionality"
omega_divider

