#!/bin/bash

# Mac Guardian Suite Control Menu
# Interactive menu to run Mac Guardian tools

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for better UX
bold=$(tput bold 2>/dev/null || echo "")
normal=$(tput sgr0 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")

# Function to check if script exists and is executable
check_script() {
    local script="$1"
    if [ ! -f "$script" ]; then
        echo "${red}❌ Error: $script not found${normal}" >&2
        return 1
    fi
    chmod +x "$script"
    return 0
}

# Function to run a script with error handling
run_script() {
    local script="$1"
    local name="$2"
    
    if ! check_script "$script"; then
        return 1
    fi
    
    echo ""
    echo "${bold}${green}▶ Running $name...${normal}"
    echo "----------------------------------------"
    if ./"$(basename "$script")"; then
        echo ""
        echo "${green}✅ $name completed successfully${normal}"
        return 0
    else
        echo ""
        echo "${red}❌ $name encountered an error${normal}" >&2
        return 1
    fi
}

# Main menu loop
while true; do
    clear
    echo "${bold}=============================="
    echo "🧠 Mac Guardian Suite Control"
    echo "==============================${normal}"
    echo ""
    echo "1) Run Mac Guardian (Cleanup & Security)"
    echo "2) Run Mac Watchdog (File Integrity Monitor)"
    echo "3) Run Mac Blue Team (Advanced Threat Detection)"
    echo "4) Run Mac AI (Intelligent Security Analysis)"
    echo "5) Run Mac Security Audit (Comprehensive Security Assessment)"
    echo "6) Run Mac Remediation (Auto-Fix Security Issues)"
    echo "7) Run all (Guardian, Watchdog, Blue Team, AI, Audit)"
    echo "8) Verify Suite (Test All Components)"
    echo "9) View & Fix Errors (Error Database)"
    echo "10) Hardening Assessment (Security Evaluation)"
    echo "11) Generate Security Report"
    echo "12) Setup Phase 1 Features (Reports & Alerts)"
    echo "13) Test Email (Send Test Email)"
    echo "14) Performance Monitor (View Performance Stats)"
    echo "15) Advanced Reports (Comparisons, PDF Export)"
    echo "16) Fix Hardening Issues (Auto-Fix Security Settings)"
    echo "17) Privacy Mode (Control What's Monitored)"
    echo "18) Zero Trust Assessment (NIST SP 800-207)"
    echo "19) Zero Trust Auto-Fix (Fix Zero Trust Issues)"
    echo "20) Threat Intelligence Feeds (Update & Check IOCs)"
    echo "21) Diamond Model Correlation (Threat Analysis)"
    echo "22) Exit"
    echo ""
    read -p "Select (1-22): " choice
    
    case "$choice" in
        1)
            if run_script "mac_guardian.sh" "Mac Guardian"; then
                read -p "Press Enter to continue..."
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        2)
            if run_script "mac_watchdog.sh" "Mac Watchdog"; then
                read -p "Press Enter to continue..."
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        3)
            run_script "mac_blueteam.sh" "Mac Blue Team"
            read -p "Press Enter to continue..."
            ;;
        4)
            run_script "mac_ai.sh" "Mac AI"
            read -p "Press Enter to continue..."
            ;;
        5)
            run_script "mac_security_audit.sh" "Mac Security Audit"
            read -p "Press Enter to continue..."
            ;;
        6)
            run_script "mac_remediation.sh" "Mac Remediation"
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            echo "${bold}Running all tools in sequence...${normal}"
            if run_script "mac_guardian.sh" "Mac Guardian"; then
                echo ""
                if run_script "mac_watchdog.sh" "Mac Watchdog"; then
                    echo ""
                    if run_script "mac_blueteam.sh" "Mac Blue Team"; then
                        echo ""
                        if run_script "mac_ai.sh" "Mac AI"; then
                            echo ""
                        if run_script "mac_security_audit.sh" "Mac Security Audit"; then
                            echo ""
                            echo "${cyan}💡 Tip: Run Remediation to auto-fix any issues found${normal}"
                            echo ""
                            read -p "Would you like to run Remediation now to auto-fix issues? (y/n): " run_remediation
                            if [[ "$run_remediation" =~ ^[Yy]$ ]]; then
                                echo ""
                                run_script "mac_remediation.sh" "Mac Remediation"
                            fi
                        fi
                        fi
                    fi
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            run_script "verify_suite.sh" "Suite Verification"
            read -p "Press Enter to continue..."
            ;;
        9)
            run_script "view_errors.sh" "Error Viewer & Fixer"
            read -p "Press Enter to continue..."
            ;;
        10)
            run_script "hardening_assessment.sh" "Hardening Assessment"
            read -p "Press Enter to continue..."
            ;;
        11)
            run_script "scheduled_reports.sh" "Security Report Generator"
            read -p "Press Enter to continue..."
            ;;
        12)
            run_script "setup_phase1_features.sh" "Phase 1 Features Setup"
            read -p "Press Enter to continue..."
            ;;
        13)
            run_script "test_email.sh" "Email Test"
            read -p "Press Enter to continue..."
            ;;
        14)
            if [ -f "performance_monitor.sh" ]; then
                echo ""
                echo "${bold}⚡ Performance Monitor${normal}"
                echo "----------------------------------------"
                ./performance_monitor.sh bottlenecks
                echo ""
                ./performance_monitor.sh suggestions
                echo ""
            else
                echo "${red}Performance monitor not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        15)
            if [ -f "advanced_reporting.sh" ]; then
                echo ""
                echo "${bold}📊 Advanced Reporting${normal}"
                echo "----------------------------------------"
                echo "1) Generate Comparison Report"
                echo "2) Export Report to PDF"
                echo "3) Generate Executive Summary"
                echo "4) Create Custom Template"
                read -p "Select (1-4): " report_choice
                case "$report_choice" in
                    1)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh compare "$latest_report"
                        else
                            echo "${red}No reports found. Generate a report first.${normal}"
                        fi
                        ;;
                    2)
                        latest_report=$(ls -t "$HOME/.macguardian/reports"/*.html 2>/dev/null | head -1)
                        if [ -n "$latest_report" ]; then
                            ./advanced_reporting.sh pdf "$latest_report"
                        else
                            echo "${red}No reports found. Generate a report first.${normal}"
                        fi
                        ;;
                    3)
                        ./advanced_reporting.sh executive
                        ;;
                    4)
                        ./advanced_reporting.sh template
                        ;;
                esac
            else
                echo "${red}Advanced reporting not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        16)
            if [ -f "hardening_auto_fix.sh" ]; then
                echo ""
                echo "${bold}🔧 Hardening Auto-Fix${normal}"
                echo "----------------------------------------"
                echo "This will fix hardening assessment failures."
                echo ""
                echo "1) Dry-run (show what would be fixed)"
                echo "2) Execute fixes (with confirmation)"
                echo "3) Auto-fix all (no confirmation - use with caution)"
                read -p "Select (1-3): " fix_choice
                case "$fix_choice" in
                    1)
                        ./hardening_auto_fix.sh all
                        ;;
                    2)
                        ./hardening_auto_fix.sh all --execute
                        ;;
                    3)
                        ./hardening_auto_fix.sh all --execute --yes
                        ;;
                esac
            else
                echo "${red}Hardening auto-fix not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        17)
            if [ -f "privacy_mode.sh" ]; then
                echo ""
                echo "${bold}🔒 Privacy Mode${normal}"
                echo "----------------------------------------"
                ./privacy_mode.sh status
                echo ""
                echo "Change privacy mode:"
                echo "1) Minimal (essential checks only)"
                echo "2) Light (basic security)"
                echo "3) Standard (full suite - default)"
                echo "4) Full (everything enabled)"
                read -p "Select (1-4) or press Enter to keep current: " privacy_choice
                case "$privacy_choice" in
                    1) ./privacy_mode.sh minimal ;;
                    2) ./privacy_mode.sh light ;;
                    3) ./privacy_mode.sh standard ;;
                    4) ./privacy_mode.sh full ;;
                esac
            else
                echo "${red}Privacy mode not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        18)
            if [ -f "zero_trust_assessment.sh" ]; then
                run_script "zero_trust_assessment.sh" "Zero Trust Assessment"
            else
                echo "${red}Zero Trust assessment not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        19)
            if [ -f "threat_intel_feeds.sh" ]; then
                echo ""
                echo "${bold}📥 Threat Intelligence Feeds${normal}"
                echo "----------------------------------------"
                echo "1) Update threat feeds"
                echo "2) Check IOC (IP/domain)"
                echo "3) Export to STIX format"
                read -p "Select (1-3): " feed_choice
                case "$feed_choice" in
                    1)
                        ./threat_intel_feeds.sh update
                        ;;
                    2)
                        echo "Enter IOC type (ip/domain/hash/url):"
                        read -r ioc_type
                        echo "Enter IOC value:"
                        read -r ioc_value
                        ./threat_intel_feeds.sh check "$ioc_type" "$ioc_value"
                        ;;
                    3)
                        ./threat_intel_feeds.sh stix
                        ;;
                esac
            else
                echo "${red}Threat intelligence feeds not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        20)
            if [ -f "diamond_model_correlation.sh" ]; then
                echo ""
                echo "${bold}🔷 Diamond Model Correlation${normal}"
                echo "----------------------------------------"
                ./diamond_model_correlation.sh correlate
                echo ""
                echo "Options:"
                echo "1) Populate from Blue Team results"
                echo "2) Add adversary manually"
                echo "3) Add infrastructure manually"
                read -p "Select (1-3) or press Enter to skip: " diamond_choice
                case "$diamond_choice" in
                    1)
                        latest_results=$(ls -t "$HOME/.macguardian/blueteam/results_*.txt" 2>/dev/null | head -1)
                        if [ -n "$latest_results" ]; then
                            ./diamond_model_correlation.sh populate "$latest_results"
                        else
                            echo "${red}No Blue Team results found. Run Blue Team first.${normal}"
                        fi
                        ;;
                    2)
                        echo "Enter adversary name:"
                        read -r adv_name
                        ./diamond_model_correlation.sh adversary "adv_$(date +%s)" "$adv_name"
                        ;;
                    3)
                        echo "Enter infrastructure type (ip/domain/url):"
                        read -r infra_type
                        echo "Enter value:"
                        read -r infra_value
                        ./diamond_model_correlation.sh infrastructure "$infra_type" "$infra_value"
                        ;;
                esac
            else
                echo "${red}Diamond Model correlation not found${normal}"
            fi
            read -p "Press Enter to continue..."
            ;;
        21)
            echo ""
            echo "${green}👋 Goodbye! Stay secure!${normal}"
            exit 0
            ;;
        *)
            echo "${red}❌ Invalid option. Please select 1-21.${normal}"
            sleep 2
            ;;
    esac
done

